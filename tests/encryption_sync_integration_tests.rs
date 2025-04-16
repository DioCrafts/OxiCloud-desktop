use oxicloud_desktop::domain::entities::encryption::{
    EncryptionAlgorithm, EncryptionSettings, KeyStorageMethod, EncryptionMetadata
};
use oxicloud_desktop::domain::entities::file::{FileItem, FileType, SyncStatus, EncryptionStatus};
use oxicloud_desktop::domain::services::encryption_service::EncryptionService;
use oxicloud_desktop::domain::services::file_service::FileService;
use oxicloud_desktop::domain::services::sync_service::SyncService;
use oxicloud_desktop::domain::repositories::encryption_repository::EncryptionRepository;
use oxicloud_desktop::domain::repositories::file_repository::FileRepository;
use oxicloud_desktop::domain::repositories::sync_repository::SyncRepository;
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
use async_trait::async_trait;
use std::collections::HashMap;
use mockall::mock;
use mockall::predicate::*;

// Mock the file service for testing
mock! {
    pub FileServiceMock {}
    
    #[async_trait]
    impl FileService for FileServiceMock {
        async fn list_files(&self, path: &str) -> Result<Vec<FileItem>, crate::domain::entities::file::FileError>;
        async fn get_file(&self, id: &str) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn create_directory(&self, name: &str, parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn rename_file(&self, id: &str, new_name: &str) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn move_file(&self, id: &str, new_parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn delete_file(&self, id: &str) -> Result<(), crate::domain::entities::file::FileError>;
        async fn upload_file(&self, local_path: &str, remote_path: &str, parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn download_file(&self, id: &str, local_path: &str) -> Result<String, crate::domain::entities::file::FileError>;
    }
}

// Mock the sync repository for testing
mock! {
    pub SyncRepoMock {}
    
    #[async_trait]
    impl SyncRepository for SyncRepoMock {
        async fn get_sync_status(&self, path: &str) -> Result<SyncStatus, crate::domain::entities::file::FileError>;
        async fn set_sync_status(&self, path: &str, status: SyncStatus) -> Result<(), crate::domain::entities::file::FileError>;
        async fn get_files_by_status(&self, status: SyncStatus) -> Result<Vec<String>, crate::domain::entities::file::FileError>;
        async fn clear_sync_status(&self) -> Result<(), crate::domain::entities::file::FileError>;
    }
}

// Mock the file repository (local) for testing
mock! {
    pub FileRepoMock {}
    
    #[async_trait]
    impl FileRepository for FileRepoMock {
        async fn list_files(&self, path: &str) -> Result<Vec<FileItem>, crate::domain::entities::file::FileError>;
        async fn get_file(&self, id: &str) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn create_directory(&self, name: &str, parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn rename_file(&self, id: &str, new_name: &str) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn move_file(&self, id: &str, new_parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn delete_file(&self, id: &str) -> Result<(), crate::domain::entities::file::FileError>;
        async fn upload_file(&self, local_path: &str, remote_path: &str, parent_id: Option<&str>) -> Result<FileItem, crate::domain::entities::file::FileError>;
        async fn download_file(&self, id: &str, local_path: &str) -> Result<String, crate::domain::entities::file::FileError>;
    }
}

// Helper function to create a test file item
fn create_test_file_item(local_path: Option<String>, encryption_status: EncryptionStatus) -> FileItem {
    let mut file = FileItem::new_file(
        Uuid::new_v4().to_string(),
        "test_file.txt".to_string(),
        "/test_file.txt".to_string(),
        100,
        Some("text/plain".to_string()),
        None,
        local_path,
    );
    
    file.encryption_status = encryption_status;
    
    if encryption_status == EncryptionStatus::Encrypted {
        file.encryption_iv = Some("test_iv_base64".to_string());
        file.encryption_metadata = Some(r#"{"algorithm":"Aes256Gcm","key_id":"test-key-id","filename_encrypted":true,"original_size":100,"original_mime_type":"text/plain","extension":"txt"}"#.to_string());
    }
    
    file
}

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

#[tokio::test]
async fn test_upload_encrypted_file() {
    // Setup encryption service
    let db_pool = create_test_db_pool();
    let enc_repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let encryption_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(enc_repository));
    
    // Initialize encryption
    let password = "test_password".to_string();
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
    
    let initialized_settings = encryption_service.initialize(&password, &settings).await
        .expect("Failed to initialize encryption");
    
    // Mock file service for the test
    let mut file_service_mock = FileServiceMock::new();
    
    // Setup expectations for file upload
    file_service_mock
        .expect_upload_file()
        .returning(|local_path, remote_path, parent_id| {
            // This simulates a successful upload and returns a FileItem
            let file_item = FileItem::new_file(
                Uuid::new_v4().to_string(),
                PathBuf::from(local_path).file_name().unwrap().to_string_lossy().to_string(),
                remote_path.to_string(),
                100,
                Some("text/plain".to_string()),
                parent_id.map(|id| id.to_string()),
                Some(local_path.to_string()),
            );
            
            Ok(file_item)
        });
    
    // Create a test file to encrypt and upload
    let test_content = "This is content that will be encrypted before upload.";
    let source_file_path = create_test_file(test_content);
    let source_file_path_str = source_file_path.to_string_lossy().to_string();
    
    // First encrypt the file content
    let test_data = fs::read(&source_file_path).expect("Failed to read test file");
    let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(&password, &test_data).await
        .expect("Failed to encrypt data");
    
    // Save encrypted file
    let encrypted_file_path = source_file_path.with_extension("enc");
    fs::write(&encrypted_file_path, &encrypted_data).expect("Failed to write encrypted file");
    
    // Create a file item with encryption details
    let mut file_item = create_test_file_item(
        Some(encrypted_file_path.to_string_lossy().to_string()),
        EncryptionStatus::Encrypted,
    );
    file_item.encryption_iv = Some(iv);
    file_item.encryption_metadata = Some(metadata);
    
    // Upload the encrypted file (mock call)
    let result = file_service_mock.upload_file(
        &encrypted_file_path.to_string_lossy(),
        "/remote/path/test_file.txt.enc",
        None
    ).await;
    
    // Assertions
    assert!(result.is_ok(), "Upload should succeed");
    
    // Clean up
    let _ = fs::remove_file(source_file_path);
    let _ = fs::remove_file(encrypted_file_path);
}

#[tokio::test]
async fn test_download_and_decrypt_file() {
    // Setup encryption service
    let db_pool = create_test_db_pool();
    let enc_repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let encryption_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(enc_repository));
    
    // Initialize encryption
    let password = "test_password".to_string();
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
    
    let initialized_settings = encryption_service.initialize(&password, &settings).await
        .expect("Failed to initialize encryption");
    
    // Create test data and encrypt it
    let test_content = "This is content that was encrypted before download.";
    let test_data = test_content.as_bytes();
    
    let (encrypted_data, iv, metadata) = encryption_service.encrypt_data(&password, test_data).await
        .expect("Failed to encrypt data");
    
    // Setup the encrypted file that we'll "download"
    let downloaded_file_path = std::env::temp_dir().join(format!("downloaded_file_{}.enc", Uuid::new_v4()));
    fs::write(&downloaded_file_path, &encrypted_data).expect("Failed to write encrypted file");
    
    // Create a file item with encryption details
    let mut file_item = create_test_file_item(
        Some(downloaded_file_path.to_string_lossy().to_string()),
        EncryptionStatus::Encrypted,
    );
    file_item.encryption_iv = Some(iv);
    file_item.encryption_metadata = Some(metadata);
    
    // Mock file service for the test
    let mut file_service_mock = FileServiceMock::new();
    
    // Setup expectations for file download
    file_service_mock
        .expect_download_file()
        .returning(move |id, local_path| {
            // This simulates a successful download and returns the local path
            // In real implementation this would actually download the encrypted file
            // For the test, we just return the path where we already wrote the encrypted content
            Ok(downloaded_file_path.to_string_lossy().to_string())
        });
    
    // Mock get_file to return our file item with encryption details
    file_service_mock
        .expect_get_file()
        .returning(move |_| {
            Ok(file_item.clone())
        });
    
    // "Download" the encrypted file (mock call)
    let file_id = "test-file-id";
    let local_download_path = std::env::temp_dir().join("download_destination").to_string_lossy().to_string();
    
    let downloaded_path = file_service_mock.download_file(file_id, &local_download_path).await
        .expect("Download should succeed");
    
    // Get file metadata to check if it's encrypted
    let file = file_service_mock.get_file(file_id).await
        .expect("Failed to get file metadata");
    
    assert_eq!(file.encryption_status, EncryptionStatus::Encrypted);
    assert!(file.encryption_iv.is_some());
    assert!(file.encryption_metadata.is_some());
    
    // Now decrypt the downloaded file
    let encrypted_content = fs::read(&downloaded_path).expect("Failed to read downloaded file");
    let decrypted_data = encryption_service.decrypt_data(
        &password, 
        &encrypted_content, 
        &file.encryption_iv.unwrap(), 
        &file.encryption_metadata.unwrap()
    ).await.expect("Failed to decrypt data");
    
    // Convert decrypted data to string and verify it's the original content
    let decrypted_string = String::from_utf8(decrypted_data).expect("Failed to convert decrypted data to string");
    assert_eq!(decrypted_string, test_content);
    
    // Clean up
    let _ = fs::remove_file(downloaded_file_path);
}