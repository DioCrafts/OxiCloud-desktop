use async_trait::async_trait;
use std::sync::Arc;
use tokio::sync::{broadcast, Mutex};

use crate::domain::entities::sync::{SyncConfig, SyncDirection, SyncResult, SyncState, SyncStatus};
use crate::domain::entities::file::{FileItem, SyncStatus as FileSyncStatus, EncryptionStatus};
use crate::domain::repositories::sync_repository::SyncRepository;
use crate::domain::repositories::file_repository::FileRepository;
use crate::domain::services::encryption_service::EncryptionService;
use crate::domain::entities::encryption::EncryptionSettings;

#[derive(Debug, Clone)]
pub enum SyncEvent {
    Started,
    Progress(SyncStatus),
    Completed,
    Paused,
    Resumed,
    Cancelled,
    Error(String),
    FileChanged(FileItem),
    EncryptionStarted(String),   // File path being encrypted
    EncryptionCompleted(String), // File path that was encrypted
    DecryptionStarted(String),   // File path being decrypted
    DecryptionCompleted(String), // File path that was decrypted
    EncryptionError(String),     // Error message
}

#[async_trait]
pub trait SyncService: Send + Sync + 'static {
    // Sync control
    async fn start_sync(&self) -> SyncResult<()>;
    async fn pause_sync(&self) -> SyncResult<()>;
    async fn resume_sync(&self) -> SyncResult<()>;
    async fn cancel_sync(&self) -> SyncResult<()>;
    
    // Downcast support for setting encryption password
    fn as_any(&self) -> &dyn std::any::Any;
    
    // Sync status
    async fn get_sync_status(&self) -> SyncResult<SyncStatus>;
    async fn subscribe_to_events(&self) -> broadcast::Receiver<SyncEvent>;
    
    // Configuration
    async fn get_sync_config(&self) -> SyncResult<SyncConfig>;
    async fn update_sync_config(&self, config: SyncConfig) -> SyncResult<()>;
    
    // Selective sync
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()>;
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>>;
    
    // Conflicts
    async fn get_conflicts(&self) -> SyncResult<Vec<FileItem>>;
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileItem>;
}

pub struct SyncServiceImpl {
    sync_repository: Arc<dyn SyncRepository>,
    file_repository: Arc<dyn FileRepository>,
    encryption_service: Option<Arc<dyn EncryptionService>>,  // Optional because encryption might be disabled
    encryption_password: Arc<Mutex<Option<String>>>, // Password for encryption/decryption, stored securely
    event_sender: broadcast::Sender<SyncEvent>,
}

impl SyncServiceImpl {
    pub fn new(
        sync_repository: Arc<dyn SyncRepository>,
        file_repository: Arc<dyn FileRepository>,
        encryption_service: Option<Arc<dyn EncryptionService>>,
    ) -> Self {
        let (event_sender, _) = broadcast::channel(100);
        Self {
            sync_repository,
            file_repository,
            encryption_service,
            encryption_password: Arc::new(Mutex::new(None)),
            event_sender,
        }
    }
    
    // Helper to broadcast events
    async fn broadcast_event(&self, event: SyncEvent) {
        let _ = self.event_sender.send(event);
    }
    
    // Set the password for encryption/decryption operations
    pub async fn set_encryption_password(&self, password: Option<String>) {
        let mut password_lock = self.encryption_password.lock().await;
        *password_lock = password;
    }
    
    // Helper to check if encryption is enabled
    async fn is_encryption_enabled(&self) -> bool {
        if let Some(encryption_service) = &self.encryption_service {
            if let Ok(settings) = encryption_service.get_settings().await {
                return settings.enabled;
            }
        }
        false
    }
    
    // Helper to encrypt a file before uploading
    async fn encrypt_file_for_upload(&self, file_path: &str) -> SyncResult<Option<FileItem>> {
        // Check if encryption is enabled and password is set
        if !self.is_encryption_enabled().await {
            return Ok(None); // Encryption not enabled, return None to indicate no encryption
        }
        
        let encryption_service = match &self.encryption_service {
            Some(service) => service.clone(),
            None => return Ok(None),
        };
        
        let password = self.encryption_password.lock().await.clone();
        let password = match password {
            Some(pwd) => pwd,
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Encryption password not set".to_string())
            ),
        };
        
        // Broadcast that we're starting encryption
        self.broadcast_event(SyncEvent::EncryptionStarted(file_path.to_string())).await;
        
        // Read the file
        let file_content = match tokio::fs::read(file_path).await {
            Ok(content) => content,
            Err(e) => {
                self.broadcast_event(SyncEvent::EncryptionError(
                    format!("Failed to read file for encryption: {}", e)
                )).await;
                
                return Err(
                    crate::domain::entities::sync::SyncError::IOError(
                        format!("Failed to read file for encryption: {}", e)
                    )
                );
            }
        };
        
        // Encrypt the data
        let (encrypted_data, iv, metadata) = match encryption_service.encrypt_data(&password, &file_content).await {
            Ok(data) => data,
            Err(e) => {
                self.broadcast_event(SyncEvent::EncryptionError(
                    format!("Failed to encrypt file: {}", e)
                )).await;
                
                return Err(
                    crate::domain::entities::sync::SyncError::EncryptionError(
                        format!("Failed to encrypt file: {}", e)
                    )
                );
            }
        };
        
        // Create an encrypted file path
        let encrypted_path = format!("{}.encrypted", file_path);
        
        // Write the encrypted data to disk
        if let Err(e) = tokio::fs::write(&encrypted_path, &encrypted_data).await {
            self.broadcast_event(SyncEvent::EncryptionError(
                format!("Failed to write encrypted file: {}", e)
            )).await;
            
            return Err(
                crate::domain::entities::sync::SyncError::IOError(
                    format!("Failed to write encrypted file: {}", e)
                )
            );
        }
        
        // Create a FileItem for the encrypted file
        let path_obj = std::path::Path::new(file_path);
        let file_name = path_obj.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unknown.file");
            
        let encrypted_name = format!("{}.encrypted", file_name);
        
        let mut file_item = FileItem::new_file(
            uuid::Uuid::new_v4().to_string(),
            encrypted_name,
            format!("/{}", encrypted_name),
            encrypted_data.len() as u64,
            Some("application/octet-stream".to_string()),
            None, // Parent ID will be set by the caller
            Some(encrypted_path.clone()),
        );
        
        // Set encryption metadata
        file_item.encryption_status = EncryptionStatus::Encrypted;
        file_item.encryption_iv = Some(iv);
        file_item.encryption_metadata = Some(metadata);
        
        self.broadcast_event(SyncEvent::EncryptionCompleted(file_path.to_string())).await;
        
        Ok(Some(file_item))
    }
    
    // Helper to decrypt a file after downloading
    async fn decrypt_file_after_download(&self, encrypted_file: &FileItem, destination_path: &str) -> SyncResult<String> {
        if encrypted_file.encryption_status != EncryptionStatus::Encrypted || 
            encrypted_file.encryption_iv.is_none() || 
            encrypted_file.encryption_metadata.is_none() {
            // File is not encrypted, just return the destination path
            return Ok(destination_path.to_string());
        }
        
        // Check if encryption is enabled and password is set
        if !self.is_encryption_enabled().await {
            return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Encryption is not enabled but file is encrypted".to_string()
                )
            );
        }
        
        let encryption_service = match &self.encryption_service {
            Some(service) => service.clone(),
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Encryption service not available".to_string()
                )
            ),
        };
        
        let password = self.encryption_password.lock().await.clone();
        let password = match password {
            Some(pwd) => pwd,
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Encryption password not set".to_string()
                )
            ),
        };
        
        let encrypted_path = match &encrypted_file.local_path {
            Some(path) => path.clone(),
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Encrypted file has no local path".to_string()
                )
            ),
        };
        
        // Broadcast that we're starting decryption
        self.broadcast_event(SyncEvent::DecryptionStarted(encrypted_path.clone())).await;
        
        // Read the encrypted file
        let encrypted_data = match tokio::fs::read(&encrypted_path).await {
            Ok(content) => content,
            Err(e) => {
                self.broadcast_event(SyncEvent::EncryptionError(
                    format!("Failed to read encrypted file: {}", e)
                )).await;
                
                return Err(
                    crate::domain::entities::sync::SyncError::IOError(
                        format!("Failed to read encrypted file: {}", e)
                    )
                );
            }
        };
        
        // Get encryption metadata
        let iv = match &encrypted_file.encryption_iv {
            Some(iv) => iv.clone(),
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Missing encryption IV".to_string()
                )
            ),
        };
        
        let metadata = match &encrypted_file.encryption_metadata {
            Some(metadata) => metadata.clone(),
            None => return Err(
                crate::domain::entities::sync::SyncError::EncryptionError(
                    "Missing encryption metadata".to_string()
                )
            ),
        };
        
        // Decrypt the data
        let decrypted_data = match encryption_service.decrypt_data(&password, &encrypted_data, &iv, &metadata).await {
            Ok(data) => data,
            Err(e) => {
                self.broadcast_event(SyncEvent::EncryptionError(
                    format!("Failed to decrypt file: {}", e)
                )).await;
                
                return Err(
                    crate::domain::entities::sync::SyncError::EncryptionError(
                        format!("Failed to decrypt file: {}", e)
                    )
                );
            }
        };
        
        // Determine the decrypted file path - strip .encrypted extension if present
        let decrypted_path = if destination_path.ends_with(".encrypted") {
            let path_without_ext = &destination_path[0..destination_path.len() - 10];
            path_without_ext.to_string()
        } else {
            format!("{}_decrypted", destination_path)
        };
        
        // Write the decrypted data to disk
        if let Err(e) = tokio::fs::write(&decrypted_path, &decrypted_data).await {
            self.broadcast_event(SyncEvent::EncryptionError(
                format!("Failed to write decrypted file: {}", e)
            )).await;
            
            return Err(
                crate::domain::entities::sync::SyncError::IOError(
                    format!("Failed to write decrypted file: {}", e)
                )
            );
        }
        
        self.broadcast_event(SyncEvent::DecryptionCompleted(decrypted_path.clone())).await;
        
        Ok(decrypted_path)
    }
}

#[async_trait]
impl SyncService for SyncServiceImpl {
    fn as_any(&self) -> &dyn std::any::Any {
        self
    }
    async fn start_sync(&self) -> SyncResult<()> {
        // Check if encryption is enabled but password not set
        if self.is_encryption_enabled().await && self.encryption_password.lock().await.is_none() {
            let error_msg = "Encryption is enabled but no password is set. Please set the encryption password before syncing.".to_string();
            self.broadcast_event(SyncEvent::Error(error_msg.clone())).await;
            return Err(SyncError::EncryptionError(error_msg));
        }
        
        // Proceed with normal sync start
        let result = self.sync_repository.start_sync().await;
        
        if result.is_ok() {
            self.broadcast_event(SyncEvent::Started).await;
            
            // Get current status to broadcast initial progress
            if let Ok(status) = self.sync_repository.get_sync_status().await {
                self.broadcast_event(SyncEvent::Progress(status)).await;
            }
        } else if let Err(ref e) = result {
            self.broadcast_event(SyncEvent::Error(e.to_string())).await;
        }
        
        result
    }
    
    async fn pause_sync(&self) -> SyncResult<()> {
        let result = self.sync_repository.pause_sync().await;
        
        if result.is_ok() {
            self.broadcast_event(SyncEvent::Paused).await;
        } else if let Err(ref e) = result {
            self.broadcast_event(SyncEvent::Error(e.to_string())).await;
        }
        
        result
    }
    
    async fn resume_sync(&self) -> SyncResult<()> {
        let result = self.sync_repository.resume_sync().await;
        
        if result.is_ok() {
            self.broadcast_event(SyncEvent::Resumed).await;
        } else if let Err(ref e) = result {
            self.broadcast_event(SyncEvent::Error(e.to_string())).await;
        }
        
        result
    }
    
    async fn cancel_sync(&self) -> SyncResult<()> {
        let result = self.sync_repository.cancel_sync().await;
        
        if result.is_ok() {
            self.broadcast_event(SyncEvent::Cancelled).await;
        } else if let Err(ref e) = result {
            self.broadcast_event(SyncEvent::Error(e.to_string())).await;
        }
        
        result
    }
    
    async fn get_sync_status(&self) -> SyncResult<SyncStatus> {
        self.sync_repository.get_sync_status().await
    }
    
    async fn subscribe_to_events(&self) -> broadcast::Receiver<SyncEvent> {
        self.event_sender.subscribe()
    }
    
    async fn get_sync_config(&self) -> SyncResult<SyncConfig> {
        self.sync_repository.get_sync_config().await
    }
    
    async fn update_sync_config(&self, config: SyncConfig) -> SyncResult<()> {
        self.sync_repository.save_sync_config(&config).await
    }
    
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()> {
        self.sync_repository.set_excluded_items(paths).await
    }
    
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>> {
        self.sync_repository.get_excluded_items().await
    }
    
    async fn get_conflicts(&self) -> SyncResult<Vec<FileItem>> {
        self.sync_repository.get_conflicts().await
    }
    
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileItem> {
        let result = self.sync_repository.resolve_conflict(file_id, keep_local).await;
        
        if let Ok(ref file) = result {
            self.broadcast_event(SyncEvent::FileChanged(file.clone())).await;
        }
        
        result
    }
}
