use oxicloud_desktop::domain::entities::encryption::{
    EncryptionAlgorithm, EncryptionSettings, KeyStorageMethod
};
use oxicloud_desktop::domain::repositories::encryption_repository::EncryptionRepository;
use oxicloud_desktop::domain::services::encryption_service::EncryptionService;
use oxicloud_desktop::infrastructure::adapters::encryption_adapter::SqliteEncryptionRepository;
use oxicloud_desktop::infrastructure::services::encryption_service_impl::EncryptionServiceImpl;

use std::sync::Arc;
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use tokio;
use std::path::PathBuf;
use std::fs;

// Helper function to create an in-memory SQLite database for testing
fn create_test_db_pool() -> Pool<SqliteConnectionManager> {
    let manager = SqliteConnectionManager::memory();
    r2d2::Pool::new(manager).expect("Failed to create test database pool")
}

// Helper function to create a temporary file with content
fn create_temp_file(content: &[u8]) -> (PathBuf, PathBuf) {
    let temp_dir = std::env::temp_dir().join("oxicloud_test");
    fs::create_dir_all(&temp_dir).expect("Failed to create temp directory");
    
    let file_path = temp_dir.join(format!("test_file_{}.txt", rand::random::<u64>()));
    fs::write(&file_path, content).expect("Failed to write test file");
    
    let encrypted_path = file_path.with_extension("encrypted");
    
    (file_path, encrypted_path)
}

// Helper function to create settings for testing
fn create_test_encryption_settings() -> EncryptionSettings {
    EncryptionSettings {
        enabled: true,
        algorithm: EncryptionAlgorithm::Aes256Gcm,
        key_storage: KeyStorageMethod::Password,
        encrypt_filenames: true,
        encrypt_metadata: true,
        kdf_salt: None,
        public_key: None,
        key_id: None,
    }
}

#[tokio::test]
async fn test_encryption_service_initialization() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let test_password = "test_password";
    
    let result = encryption_service.initialize(test_password, &settings).await;
    assert!(result.is_ok(), "Failed to initialize encryption: {:?}", result.err());
    
    let initialized_settings = result.unwrap();
    assert!(initialized_settings.enabled);
    assert!(initialized_settings.key_id.is_some());
    assert!(initialized_settings.kdf_salt.is_some());
}

#[tokio::test]
async fn test_encrypt_decrypt_data() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let test_password = "test_password";
    
    let initialized_settings = encryption_service.initialize(test_password, &settings).await.expect("Failed to initialize encryption");
    
    // Test data
    let test_data = b"This is a test message for encryption and decryption";
    
    // Encrypt data
    let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(test_password, test_data).await
        .expect("Failed to encrypt data");
    
    // Verify encrypted data is different from original
    assert_ne!(encrypted_data, test_data);
    
    // Decrypt data
    let decrypted_data = encryption_service.decrypt_data(test_password, &encrypted_data, &iv, &metadata).await
        .expect("Failed to decrypt data");
    
    // Verify decrypted data matches original
    assert_eq!(decrypted_data, test_data);
}

#[tokio::test]
async fn test_encrypt_decrypt_string() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let test_password = "test_password";
    
    let initialized_settings = encryption_service.initialize(test_password, &settings).await.expect("Failed to initialize encryption");
    
    // Test string
    let test_string = "This is a test string for encryption and decryption";
    
    // Encrypt string
    let (encrypted_string, iv, metadata) = encryption_service.encrypt_string(test_password, test_string).await
        .expect("Failed to encrypt string");
    
    // Verify encrypted string is different from original
    assert_ne!(encrypted_string, test_string);
    
    // Decrypt string
    let decrypted_string = encryption_service.decrypt_string(test_password, &encrypted_string, &iv, &metadata).await
        .expect("Failed to decrypt string");
    
    // Verify decrypted string matches original
    assert_eq!(decrypted_string, test_string);
}

#[tokio::test]
async fn test_incorrect_password() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let test_password = "correct_password";
    let wrong_password = "wrong_password";
    
    let initialized_settings = encryption_service.initialize(test_password, &settings).await.expect("Failed to initialize encryption");
    
    // Test data
    let test_data = b"This is a test message for encryption and decryption";
    
    // Encrypt data with correct password
    let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(test_password, test_data).await
        .expect("Failed to encrypt data");
    
    // Try to decrypt with wrong password
    let decryption_result = encryption_service.decrypt_data(wrong_password, &encrypted_data, &iv, &metadata).await;
    
    // Verify decryption fails with wrong password
    assert!(decryption_result.is_err());
}

#[tokio::test]
async fn test_change_password() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let old_password = "old_password";
    let new_password = "new_password";
    
    let initialized_settings = encryption_service.initialize(old_password, &settings).await.expect("Failed to initialize encryption");
    
    // Test data
    let test_data = b"This is a test message for encryption and decryption";
    
    // Encrypt data with old password
    let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(old_password, test_data).await
        .expect("Failed to encrypt data");
    
    // Change password
    encryption_service.change_password(old_password, new_password).await
        .expect("Failed to change password");
    
    // Try to decrypt with old password
    let old_password_result = encryption_service.decrypt_data(old_password, &encrypted_data, &iv, &metadata).await;
    assert!(old_password_result.is_err());
    
    // Decrypt with new password
    let new_password_result = encryption_service.decrypt_data(new_password, &encrypted_data, &iv, &metadata).await;
    assert!(new_password_result.is_ok());
    assert_eq!(new_password_result.unwrap(), test_data);
}

#[tokio::test]
async fn test_verify_password() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Initialize encryption
    let settings = create_test_encryption_settings();
    let test_password = "test_password";
    let wrong_password = "wrong_password";
    
    let initialized_settings = encryption_service.initialize(test_password, &settings).await.expect("Failed to initialize encryption");
    
    // Verify correct password
    let correct_result = encryption_service.verify_password(test_password).await
        .expect("Failed to verify password");
    assert!(correct_result);
    
    // Verify wrong password
    let wrong_result = encryption_service.verify_password(wrong_password).await
        .expect("Failed to verify password");
    assert!(!wrong_result);
}

#[tokio::test]
async fn test_different_algorithms() {
    // Create test database and repository
    let db_pool = create_test_db_pool();
    let repository = Arc::new(SqliteEncryptionRepository::new(db_pool));
    
    // Create encryption service
    let encryption_service = Arc::new(EncryptionServiceImpl::new(repository));
    
    // Test data
    let test_data = b"This is a test message for encryption and decryption";
    let test_password = "test_password";
    
    // Test each algorithm
    let algorithms = vec![
        EncryptionAlgorithm::Aes256Gcm,
        EncryptionAlgorithm::Chacha20Poly1305,
        // Note: We're not testing post-quantum algorithms since they're placeholder implementations
    ];
    
    for algorithm in algorithms {
        // Initialize encryption with specific algorithm
        let mut settings = create_test_encryption_settings();
        settings.algorithm = algorithm.clone();
        
        let initialized_settings = encryption_service.initialize(test_password, &settings).await
            .expect(&format!("Failed to initialize encryption with {:?}", algorithm));
        
        // Encrypt data
        let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(test_password, test_data).await
            .expect(&format!("Failed to encrypt data with {:?}", algorithm));
        
        // Decrypt data
        let decrypted_data = encryption_service.decrypt_data(test_password, &encrypted_data, &iv, &metadata).await
            .expect(&format!("Failed to decrypt data with {:?}", algorithm));
        
        // Verify decrypted data matches original
        assert_eq!(decrypted_data, test_data, "Failed with algorithm {:?}", algorithm);
    }
}