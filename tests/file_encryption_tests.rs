use oxicloud_desktop::domain::entities::encryption::{
    EncryptionAlgorithm, EncryptionSettings, KeyStorageMethod
};
use oxicloud_desktop::domain::entities::file::{FileItem, FileType};
use oxicloud_desktop::application::ports::encryption_port::EncryptionPort;
use oxicloud_desktop::application::services::encryption_service::EncryptionApplicationService;
use oxicloud_desktop::domain::services::encryption_service::EncryptionService;
use oxicloud_desktop::domain::repositories::encryption_repository::EncryptionRepository;
use oxicloud_desktop::infrastructure::adapters::encryption_adapter::SqliteEncryptionRepository;
use oxicloud_desktop::infrastructure::services::encryption_service_impl::EncryptionServiceImpl;

use std::sync::Arc;
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use tokio;
use std::path::PathBuf;
use std::fs;
use chrono::Utc;
use uuid::Uuid;

// Helper function to create an in-memory SQLite database for testing
fn create_test_db_pool() -> Pool<SqliteConnectionManager> {
    let manager = SqliteConnectionManager::memory();
    r2d2::Pool::new(manager).expect("Failed to create test database pool")
}

// Helper function to create a test file with specified content
fn create_test_file(content: &str) -> PathBuf {
    let temp_dir = std::env::temp_dir().join("oxicloud_test");
    fs::create_dir_all(&temp_dir).expect("Failed to create temp directory");
    
    let file_path = temp_dir.join(format!("test_file_{}.txt", Uuid::new_v4()));
    fs::write(&file_path, content).expect("Failed to write test file");
    
    file_path
}

// Helper function to create a test FileItem
fn create_test_file_item(local_path: Option<String>) -> FileItem {
    FileItem::new_file(
        Uuid::new_v4().to_string(),
        "test_file.txt".to_string(),
        "/test_file.txt".to_string(),
        100,
        Some("text/plain".to_string()),
        None,
        local_path,
    )
}

// Setup test encryption service
fn setup_encryption_service() -> (Arc<dyn EncryptionPort>, String) {
    let db_pool = create_test_db_pool();
    let repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let domain_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(repository));
    let encryption_service: Arc<dyn EncryptionPort> = Arc::new(EncryptionApplicationService::new(domain_service));
    
    let test_password = "test_password".to_string();
    
    // Initialize encryption settings
    let settings = EncryptionSettings {
        enabled: true,
        algorithm: EncryptionAlgorithm::Aes256Gcm,
        key_storage: KeyStorageMethod::Password,
        encrypt_filenames: true,
        encrypt_metadata: true,
        kdf_salt: None,
        public_key: None,
        key_id: None,
    };
    
    // Run this in a synchronous context for test setup
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        encryption_service.initialize_encryption(&test_password, &settings).await
            .expect("Failed to initialize encryption");
    });
    
    (encryption_service, test_password)
}

#[tokio::test]
async fn test_encrypt_decrypt_file() {
    // Setup
    let (encryption_service, password) = setup_encryption_service();
    
    // Create a test file
    let test_content = "This is some test content for file encryption and decryption testing.";
    let source_file = create_test_file(test_content);
    
    // Encrypt the file
    let encrypted_file = encryption_service.encrypt_file(&password, &source_file).await
        .expect("Failed to encrypt file");
    
    // Verify the encrypted file exists and has different content
    assert!(encrypted_file.exists());
    let encrypted_content = fs::read_to_string(&encrypted_file).expect("Failed to read encrypted file");
    assert_ne!(encrypted_content, test_content);
    
    // Decrypt the file
    let decrypted_file = encryption_service.decrypt_file(&password, &encrypted_file).await
        .expect("Failed to decrypt file");
    
    // Verify the decrypted file contains the original content
    assert!(decrypted_file.exists());
    let decrypted_content = fs::read_to_string(&decrypted_file).expect("Failed to read decrypted file");
    assert_eq!(decrypted_content, test_content);
    
    // Clean up
    let _ = fs::remove_file(source_file);
    let _ = fs::remove_file(encrypted_file);
    let _ = fs::remove_file(decrypted_file);
}

#[tokio::test]
async fn test_decrypt_with_wrong_password() {
    // Setup
    let (encryption_service, password) = setup_encryption_service();
    let wrong_password = "wrong_password";
    
    // Create a test file
    let test_content = "This is some test content for file encryption and decryption testing.";
    let source_file = create_test_file(test_content);
    
    // Encrypt the file
    let encrypted_file = encryption_service.encrypt_file(&password, &source_file).await
        .expect("Failed to encrypt file");
    
    // Try to decrypt with wrong password
    let decryption_result = encryption_service.decrypt_file(wrong_password, &encrypted_file).await;
    
    // Verify decryption fails with wrong password
    assert!(decryption_result.is_err());
    
    // Clean up
    let _ = fs::remove_file(source_file);
    let _ = fs::remove_file(encrypted_file);
}

#[tokio::test]
async fn test_encryption_settings_update() {
    // Setup
    let (encryption_service, password) = setup_encryption_service();
    
    // Get current settings
    let original_settings = encryption_service.get_encryption_settings().await
        .expect("Failed to get encryption settings");
    
    // Create modified settings
    let mut updated_settings = original_settings.clone();
    updated_settings.algorithm = EncryptionAlgorithm::Chacha20Poly1305; // Change algorithm
    updated_settings.encrypt_filenames = !original_settings.encrypt_filenames; // Toggle filename encryption
    
    // Update settings
    encryption_service.update_encryption_settings(&password, &updated_settings).await
        .expect("Failed to update encryption settings");
    
    // Retrieve settings again and verify changes
    let retrieved_settings = encryption_service.get_encryption_settings().await
        .expect("Failed to get updated encryption settings");
    
    assert_eq!(retrieved_settings.algorithm, EncryptionAlgorithm::Chacha20Poly1305);
    assert_eq!(retrieved_settings.encrypt_filenames, !original_settings.encrypt_filenames);
    
    // Key ID and salt should remain the same
    assert_eq!(retrieved_settings.key_id, original_settings.key_id);
    assert_eq!(retrieved_settings.kdf_salt, original_settings.kdf_salt);
}

#[tokio::test]
async fn test_password_verification() {
    // Setup
    let (encryption_service, password) = setup_encryption_service();
    
    // Verify correct password
    let correct_result = encryption_service.verify_password(&password).await
        .expect("Failed to verify password");
    assert!(correct_result);
    
    // Verify wrong password
    let wrong_result = encryption_service.verify_password("wrong_password").await
        .expect("Failed to verify password");
    assert!(!wrong_result);
}

#[tokio::test]
async fn test_key_export_import() {
    // Setup
    let (encryption_service, password) = setup_encryption_service();
    
    // Create a test file and encrypt it
    let test_content = "This is content that will be encrypted with the original key.";
    let source_file = create_test_file(test_content);
    let encrypted_file = encryption_service.encrypt_file(&password, &source_file).await
        .expect("Failed to encrypt file");
    
    // Export the key
    let export_path = std::env::temp_dir().join("oxicloud_test_key_export.json");
    encryption_service.export_encryption_key(&password, &export_path).await
        .expect("Failed to export key");
    
    // Setup a new encryption service instance (simulating a new installation)
    let db_pool = create_test_db_pool();
    let repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let domain_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(repository));
    let new_encryption_service: Arc<dyn EncryptionPort> = Arc::new(EncryptionApplicationService::new(domain_service));
    
    // Import the key to the new service
    new_encryption_service.import_encryption_key(&password, &export_path).await
        .expect("Failed to import key");
    
    // Verify the key works by decrypting the previously encrypted file
    let decrypted_file = new_encryption_service.decrypt_file(&password, &encrypted_file).await
        .expect("Failed to decrypt file with imported key");
    
    // Verify the decrypted content matches the original
    let decrypted_content = fs::read_to_string(&decrypted_file).expect("Failed to read decrypted file");
    assert_eq!(decrypted_content, test_content);
    
    // Clean up
    let _ = fs::remove_file(source_file);
    let _ = fs::remove_file(encrypted_file);
    let _ = fs::remove_file(decrypted_file);
    let _ = fs::remove_file(export_path);
}