use oxicloud_desktop::domain::entities::encryption::{
    EncryptionAlgorithm, EncryptionSettings, KeyStorageMethod
};
use oxicloud_desktop::domain::entities::file::{FileItem, FileType, SyncStatus, EncryptionStatus};
use oxicloud_desktop::domain::entities::sync::{SyncConfig, SyncDirection, SyncResult};
use oxicloud_desktop::domain::repositories::encryption_repository::EncryptionRepository;
use oxicloud_desktop::domain::repositories::file_repository::FileRepository;
use oxicloud_desktop::domain::repositories::sync_repository::SyncRepository;
use oxicloud_desktop::domain::services::encryption_service::EncryptionService;
use oxicloud_desktop::domain::services::sync_service::{SyncService, SyncServiceImpl, SyncEvent};
use oxicloud_desktop::infrastructure::adapters::encryption_adapter::SqliteEncryptionRepository;
use oxicloud_desktop::infrastructure::services::encryption_service_impl::EncryptionServiceImpl;

use std::sync::Arc;
use tokio::sync::{Mutex, broadcast};
use tokio::fs;
use std::path::PathBuf;
use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use async_trait::async_trait;
use chrono::Utc;
use uuid::Uuid;
use mockall::mock;
use mockall::predicate::*;
use chrono::DateTime;

// Mock the file repository
mock! {
    pub FileRepoMock {}
    
    #[async_trait]
    impl FileRepository for FileRepoMock {
        async fn get_file_by_id(&self, file_id: &str) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_files_by_folder(&self, folder_id: Option<&str>) -> Result<Vec<FileItem>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_file_content(&self, file_id: &str) -> Result<Vec<u8>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn create_file(&self, file: FileItem, content: Vec<u8>) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
        async fn update_file(&self, file: FileItem, content: Option<Vec<u8>>) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
        async fn delete_file(&self, file_id: &str) -> Result<(), oxicloud_desktop::domain::entities::file::FileError>;
        async fn create_folder(&self, folder: FileItem) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
        async fn delete_folder(&self, folder_id: &str, recursive: bool) -> Result<(), oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_changed_files(&self, since: Option<DateTime<Utc>>) -> Result<Vec<FileItem>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_files_by_sync_status(&self, status: SyncStatus) -> Result<Vec<FileItem>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_file_from_path(&self, path: &std::path::Path) -> Result<Option<FileItem>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn download_file_to_path(&self, file_id: &str, local_path: &std::path::Path) -> Result<(), oxicloud_desktop::domain::entities::file::FileError>;
        async fn upload_file_from_path(&self, local_path: &std::path::Path, parent_id: Option<&str>) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
        async fn get_favorites(&self) -> Result<Vec<FileItem>, oxicloud_desktop::domain::entities::file::FileError>;
        async fn set_favorite(&self, file_id: &str, is_favorite: bool) -> Result<FileItem, oxicloud_desktop::domain::entities::file::FileError>;
    }
}

// Mock the sync repository
mock! {
    pub SyncRepoMock {}
    
    #[async_trait]
    impl SyncRepository for SyncRepoMock {
        async fn get_sync_config(&self) -> SyncResult<SyncConfig>;
        async fn save_sync_config(&self, config: &SyncConfig) -> SyncResult<()>;
        async fn get_sync_status(&self) -> SyncResult<oxicloud_desktop::domain::entities::sync::SyncStatus>;
        async fn update_sync_status(&self, status: &oxicloud_desktop::domain::entities::sync::SyncStatus) -> SyncResult<()>;
        async fn start_sync(&self) -> SyncResult<()>;
        async fn pause_sync(&self) -> SyncResult<()>;
        async fn resume_sync(&self) -> SyncResult<()>;
        async fn cancel_sync(&self) -> SyncResult<()>;
        async fn get_excluded_items(&self) -> SyncResult<Vec<String>>;
        async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()>;
        async fn get_last_sync_time(&self) -> SyncResult<Option<DateTime<Utc>>>;
        async fn set_last_sync_time(&self, time: DateTime<Utc>) -> SyncResult<()>;
        async fn get_conflicts(&self) -> SyncResult<Vec<FileItem>>;
        async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileItem>;
        async fn record_event(&self, event: oxicloud_desktop::domain::entities::sync::SyncEvent) -> SyncResult<()>;
        async fn get_recent_events(&self, limit: usize) -> SyncResult<Vec<oxicloud_desktop::domain::entities::sync::SyncEvent>>;
    }
}

// Helper function to create a test file
fn create_test_file(content: &[u8]) -> (PathBuf, PathBuf) {
    let temp_dir = std::env::temp_dir().join("oxicloud_test");
    let _ = std::fs::create_dir_all(&temp_dir);
    
    let file_path = temp_dir.join(format!("test_file_{}.txt", Uuid::new_v4()));
    std::fs::write(&file_path, content).expect("Failed to write test file");
    
    let encrypted_path = file_path.with_extension("encrypted");
    
    (file_path, encrypted_path)
}

// Helper function to create in-memory SQLite DB
fn create_test_db_pool() -> Pool<SqliteConnectionManager> {
    let manager = SqliteConnectionManager::memory();
    r2d2::Pool::new(manager).expect("Failed to create test database pool")
}

#[tokio::test]
async fn test_sync_service_with_encryption() {
    // Create the encryption service
    let db_pool = create_test_db_pool();
    let encryption_repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let encryption_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(encryption_repository));
    
    // Initialize encryption with test settings
    let password = "test_password";
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
    
    let _ = encryption_service.initialize(password, &settings).await
        .expect("Failed to initialize encryption");
    
    // Create mock repositories
    let mut file_repo_mock = FileRepoMock::new();
    let mut sync_repo_mock = SyncRepoMock::new();
    
    // Setup mock expectations
    sync_repo_mock.expect_start_sync()
        .returning(|| Ok(()));
    
    sync_repo_mock.expect_get_sync_status()
        .returning(|| {
            Ok(oxicloud_desktop::domain::entities::sync::SyncStatus {
                state: oxicloud_desktop::domain::entities::sync::SyncState::Syncing,
                last_sync: None,
                current_operation: None,
                current_file: None,
                total_files: 0,
                processed_files: 0,
                total_bytes: 0,
                processed_bytes: 0,
                error_message: None,
            })
        });
    
    // Prepare a test file
    let test_content = "This is a test file that will be encrypted before upload";
    let (file_path, _) = create_test_file(test_content.as_bytes());
    
    // Create sync service
    let sync_service = SyncServiceImpl::new(
        Arc::new(sync_repo_mock),
        Arc::new(file_repo_mock),
        Some(encryption_service.clone()),
    );
    
    // Set the encryption password
    sync_service.set_encryption_password(Some(password.to_string())).await;
    
    // Subscribe to events
    let mut event_receiver = sync_service.subscribe_to_events();
    
    // Collect events in a background task
    let events = Arc::new(Mutex::new(Vec::new()));
    let events_clone = events.clone();
    
    tokio::spawn(async move {
        while let Ok(event) = event_receiver.recv().await {
            let mut events = events_clone.lock().await;
            events.push(event);
        }
    });
    
    // Test encrypting a file
    let encrypted_file = sync_service.encrypt_file_for_upload(&file_path.to_string_lossy()).await
        .expect("Failed to encrypt file")
        .expect("Expected Some(FileItem) but got None");
    
    // Verify that the file was encrypted
    assert_eq!(encrypted_file.encryption_status, EncryptionStatus::Encrypted);
    assert!(encrypted_file.encryption_iv.is_some());
    assert!(encrypted_file.encryption_metadata.is_some());
    
    // Check that there's an encrypted file on disk
    assert!(PathBuf::from(encrypted_file.local_path.clone().unwrap()).exists());
    
    // Test decrypting the file
    let dest_path = std::env::temp_dir().join("oxicloud_test").join("decrypted_file.txt");
    let decrypted_path = sync_service.decrypt_file_after_download(&encrypted_file, &dest_path.to_string_lossy()).await
        .expect("Failed to decrypt file");
    
    // Verify that decrypted content matches original
    let decrypted_content = fs::read_to_string(decrypted_path).await
        .expect("Failed to read decrypted file");
    assert_eq!(decrypted_content, test_content);
    
    // Clean up
    let _ = fs::remove_file(&file_path).await;
    if let Some(path) = &encrypted_file.local_path {
        let _ = fs::remove_file(path).await;
    }
    let _ = fs::remove_file(&dest_path).await;
}

#[tokio::test]
async fn test_sync_service_with_encryption_password_check() {
    // Create the encryption service
    let db_pool = create_test_db_pool();
    let encryption_repository: Arc<dyn EncryptionRepository> = Arc::new(SqliteEncryptionRepository::new(db_pool));
    let encryption_service: Arc<dyn EncryptionService> = Arc::new(EncryptionServiceImpl::new(encryption_repository));
    
    // Initialize encryption with test settings
    let password = "test_password";
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
    
    let _ = encryption_service.initialize(password, &settings).await
        .expect("Failed to initialize encryption");
    
    // Create mock repositories
    let file_repo_mock = FileRepoMock::new();
    let mut sync_repo_mock = SyncRepoMock::new();
    
    // Setup mock expectations
    sync_repo_mock.expect_start_sync()
        .returning(|| Ok(()));
    
    // Create sync service with encryption enabled but no password
    let sync_service = SyncServiceImpl::new(
        Arc::new(sync_repo_mock),
        Arc::new(file_repo_mock),
        Some(encryption_service.clone()),
    );
    
    // Try to start sync - should fail because encryption is enabled but no password is set
    let result = sync_service.start_sync().await;
    assert!(result.is_err());
    let err = result.unwrap_err();
    match err {
        oxicloud_desktop::domain::entities::sync::SyncError::EncryptionError(_) => {
            // This is the expected error
        },
        _ => panic!("Expected EncryptionError but got {:?}", err),
    }
    
    // Now set the password and try again
    sync_service.set_encryption_password(Some(password.to_string())).await;
    let result = sync_service.start_sync().await;
    assert!(result.is_ok());
}