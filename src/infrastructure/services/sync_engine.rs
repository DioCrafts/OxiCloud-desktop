use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use tokio::sync::{broadcast, Mutex, RwLock};
use tokio::time;
use chrono::{DateTime, Utc};
use uuid::Uuid;
use async_trait::async_trait;
use tracing::{debug, error, info, warn};

use crate::domain::entities::file::{FileItem, FileType, SyncStatus as FileSyncStatus, EncryptionStatus};
use crate::domain::entities::sync::{SyncConfig, SyncDirection, SyncError, SyncResult, SyncState, SyncStatus};
use crate::domain::repositories::file_repository::FileRepository;
use crate::domain::repositories::sync_repository::SyncRepository;
use crate::domain::services::sync_service::{SyncEvent, SyncService};

/// The sync engine handles the actual synchronization process between local and remote repositories
pub struct SyncEngine {
    local_repository: Arc<dyn FileRepository>,
    remote_repository: Arc<dyn FileRepository>,
    sync_repository: Arc<dyn SyncRepository>,
    sync_service: Arc<dyn SyncService>,
    running: Arc<RwLock<bool>>,
    sync_interval: Arc<RwLock<Duration>>,
    sync_direction: Arc<RwLock<SyncDirection>>,
    excluded_paths: Arc<RwLock<HashSet<String>>>,
    status: Arc<RwLock<SyncStatus>>,
    event_sender: broadcast::Sender<SyncEvent>,
}

impl SyncEngine {
    pub fn new(
        local_repository: Arc<dyn FileRepository>,
        remote_repository: Arc<dyn FileRepository>,
        sync_repository: Arc<dyn SyncRepository>,
        sync_service: Arc<dyn SyncService>,
    ) -> Self {
        let (event_sender, _) = broadcast::channel(100);
        
        Self {
            local_repository,
            remote_repository,
            sync_repository,
            sync_service,
            running: Arc::new(RwLock::new(false)),
            sync_interval: Arc::new(RwLock::new(Duration::from_secs(300))), // Default 5 minutes
            sync_direction: Arc::new(RwLock::new(SyncDirection::Bidirectional)),
            excluded_paths: Arc::new(RwLock::new(HashSet::new())),
            status: Arc::new(RwLock::new(SyncStatus::default())),
            event_sender,
        }
    }
    
    /// Starts the sync engine as a background task
    pub async fn start(&self) -> SyncResult<()> {
        // Check if already running
        if *self.running.read().await {
            return Err(SyncError::AlreadySyncing);
        }
        
        // Load configuration
        let config = self.sync_repository.get_sync_config().await?;
        
        // Update settings
        *self.sync_interval.write().await = config.sync_interval;
        *self.sync_direction.write().await = config.sync_direction;
        
        let excluded = config.excluded_paths.iter().cloned().collect();
        *self.excluded_paths.write().await = excluded;
        
        // Start the sync engine
        *self.running.write().await = true;
        
        // Create a cloned instance for the background task
        let running = self.running.clone();
        let sync_interval = self.sync_interval.clone();
        let sync_service = self.sync_service.clone();
        let sync_repository = self.sync_repository.clone();
        let local_repository = self.local_repository.clone();
        let remote_repository = self.remote_repository.clone();
        let status = self.status.clone();
        let excluded_paths = self.excluded_paths.clone();
        let sync_direction = self.sync_direction.clone();
        let event_sender = self.event_sender.clone();
        
        // Launch background task
        tokio::spawn(async move {
            let mut first_sync = true;
            
            while *running.read().await {
                // Get current interval
                let interval = *sync_interval.read().await;
                
                if first_sync || config.sync_on_startup {
                    // Perform initial sync
                    let sync_result = Self::perform_sync(
                        sync_repository.clone(),
                        local_repository.clone(),
                        remote_repository.clone(),
                        status.clone(),
                        excluded_paths.clone(),
                        sync_direction.clone(),
                        event_sender.clone(),
                    ).await;
                    
                    if let Err(e) = sync_result {
                        error!("Sync failed: {:?}", e);
                        let mut status_lock = status.write().await;
                        status_lock.state = SyncState::Error(e.to_string());
                        status_lock.error_message = Some(e.to_string());
                        
                        // Update status in repository
                        if let Err(update_err) = sync_repository.update_sync_status(&status_lock).await {
                            error!("Failed to update sync status: {:?}", update_err);
                        }
                        
                        // Broadcast error event
                        let _ = event_sender.send(SyncEvent::Error(e.to_string()));
                    } else {
                        // Sync completed successfully
                        let mut status_lock = status.write().await;
                        status_lock.state = SyncState::Idle;
                        status_lock.last_sync = Some(Utc::now());
                        
                        // Update status in repository
                        if let Err(update_err) = sync_repository.update_sync_status(&status_lock).await {
                            error!("Failed to update sync status: {:?}", update_err);
                        }
                        
                        // Broadcast completion event
                        let _ = event_sender.send(SyncEvent::Completed);
                    }
                    
                    first_sync = false;
                }
                
                // Sleep until next sync
                let delay_time = if config.sync_on_file_change {
                    // Shorter delay if we're watching for file changes
                    std::cmp::min(interval, Duration::from_secs(10))
                } else {
                    interval
                };
                
                // Wait but also check if we've been stopped
                let mut timer = time::interval(Duration::from_secs(1));
                let mut elapsed = Duration::from_secs(0);
                
                while elapsed < delay_time {
                    timer.tick().await;
                    
                    if !*running.read().await {
                        break;
                    }
                    
                    // Skip rest of delay if sync state has changed
                    let status_check = status.read().await;
                    if status_check.state == SyncState::Syncing || status_check.state == SyncState::Paused {
                        break;
                    }
                    
                    elapsed += Duration::from_secs(1);
                }
            }
            
            debug!("Sync engine stopped");
        });
        
        Ok(())
    }
    
    /// Stops the sync engine
    pub async fn stop(&self) -> SyncResult<()> {
        if !*self.running.read().await {
            return Err(SyncError::NotStarted);
        }
        
        *self.running.write().await = false;
        Ok(())
    }
    
    /// Performs the actual synchronization
    async fn perform_sync(
        sync_repository: Arc<dyn SyncRepository>,
        local_repository: Arc<dyn FileRepository>,
        remote_repository: Arc<dyn FileRepository>,
        status: Arc<RwLock<SyncStatus>>,
        excluded_paths: Arc<RwLock<HashSet<String>>>,
        sync_direction: Arc<RwLock<SyncDirection>>,
        event_sender: broadcast::Sender<SyncEvent>,
    ) -> SyncResult<()> {
        // Update status to indicate we're starting
        {
            let mut status_lock = status.write().await;
            status_lock.state = SyncState::Syncing;
            status_lock.current_operation = Some("Starting synchronization".to_string());
            status_lock.current_file = None;
            status_lock.total_files = 0;
            status_lock.processed_files = 0;
            status_lock.total_bytes = 0;
            status_lock.processed_bytes = 0;
            status_lock.error_message = None;
            
            // Update status in repository
            sync_repository.update_sync_status(&status_lock).await?;
            
            // Broadcast event
            let _ = event_sender.send(SyncEvent::Started);
        }
        
        // Get sync direction
        let direction = *sync_direction.read().await;
        
        // Get the last sync time
        let last_sync = sync_repository.get_last_sync_time().await?;
        
        // Step 1: Index local and remote files
        debug!("Indexing files...");
        let mut status_lock = status.write().await;
        status_lock.current_operation = Some("Indexing files".to_string());
        sync_repository.update_sync_status(&status_lock).await?;
        drop(status_lock);
        
        // Broadcast progress
        let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        
        // Index files recursively
        let (local_files, remote_files) = Self::index_files(
            local_repository.clone(),
            remote_repository.clone(),
            excluded_paths.clone(),
        ).await?;
        
        // Update status with file counts
        let mut status_lock = status.write().await;
        let total_files = local_files.len() + remote_files.len();
        status_lock.total_files = total_files as u32;
        sync_repository.update_sync_status(&status_lock).await?;
        drop(status_lock);
        
        // Broadcast progress
        let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        
        // Step A: Handle uploads (local to remote) if enabled
        if direction == SyncDirection::Upload || direction == SyncDirection::Bidirectional {
            Self::process_uploads(
                sync_repository.clone(),
                local_repository.clone(), 
                remote_repository.clone(),
                status.clone(),
                &local_files,
                &remote_files,
                last_sync,
                event_sender.clone(),
            ).await?;
        }
        
        // Check if we need to continue
        if *status.read().await.state == SyncState::Paused {
            return Ok(());
        }
        
        // Step B: Handle downloads (remote to local) if enabled
        if direction == SyncDirection::Download || direction == SyncDirection::Bidirectional {
            Self::process_downloads(
                sync_repository.clone(),
                local_repository.clone(), 
                remote_repository.clone(),
                status.clone(),
                &local_files,
                &remote_files,
                last_sync,
                event_sender.clone(),
            ).await?;
        }
        
        // Update the last sync time
        sync_repository.set_last_sync_time(Utc::now()).await?;
        
        // Update status to indicate we're done
        let mut status_lock = status.write().await;
        status_lock.state = SyncState::Idle;
        status_lock.current_operation = None;
        status_lock.current_file = None;
        status_lock.last_sync = Some(Utc::now());
        
        // Update status in repository
        sync_repository.update_sync_status(&status_lock).await?;
        
        // Broadcast completion event
        let _ = event_sender.send(SyncEvent::Completed);
        
        Ok(())
    }
    
    /// Index files in both repositories
    async fn index_files(
        local_repository: Arc<dyn FileRepository>,
        remote_repository: Arc<dyn FileRepository>,
        excluded_paths: Arc<RwLock<HashSet<String>>>,
    ) -> SyncResult<(HashMap<String, FileItem>, HashMap<String, FileItem>)> {
        let excluded = excluded_paths.read().await.clone();
        
        // Helper to check if a path is excluded
        let is_excluded = |path: &str| -> bool {
            for excluded_path in &excluded {
                if path == excluded_path || path.starts_with(&format!("{}/", excluded_path)) {
                    return true;
                }
            }
            false
        };
        
        // Get all local files recursively
        let mut local_files = HashMap::new();
        Self::collect_files_recursive(
            local_repository.clone(),
            None,
            &mut local_files,
            &is_excluded,
        ).await?;
        
        // Get all remote files recursively
        let mut remote_files = HashMap::new();
        Self::collect_files_recursive(
            remote_repository.clone(),
            None,
            &mut remote_files,
            &is_excluded,
        ).await?;
        
        Ok((local_files, remote_files))
    }
    
    /// Collect files recursively from a repository
    async fn collect_files_recursive(
        repository: Arc<dyn FileRepository>,
        folder_id: Option<&str>,
        files: &mut HashMap<String, FileItem>,
        is_excluded: &dyn Fn(&str) -> bool,
    ) -> SyncResult<()> {
        let items = repository.get_files_by_folder(folder_id).await?;
        
        for item in items {
            // Skip excluded paths
            if is_excluded(&item.path) {
                continue;
            }
            
            // Add the item to our map
            files.insert(item.path.clone(), item.clone());
            
            // Recurse into folders
            if item.file_type == FileType::Folder {
                Self::collect_files_recursive(
                    repository.clone(),
                    Some(&item.id),
                    files,
                    is_excluded,
                ).await?;
            }
        }
        
        Ok(())
    }
    
    /// Process uploads from local to remote
    async fn process_uploads(
        sync_repository: Arc<dyn SyncRepository>,
        local_repository: Arc<dyn FileRepository>,
        remote_repository: Arc<dyn FileRepository>,
        status: Arc<RwLock<SyncStatus>>,
        local_files: &HashMap<String, FileItem>,
        remote_files: &HashMap<String, FileItem>,
        last_sync: Option<DateTime<Utc>>,
        event_sender: broadcast::Sender<SyncEvent>,
    ) -> SyncResult<()> {
        debug!("Processing uploads...");
        
        let mut status_lock = status.write().await;
        status_lock.current_operation = Some("Processing uploads".to_string());
        sync_repository.update_sync_status(&status_lock).await?;
        drop(status_lock);
        
        // Broadcast progress
        let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        
        // Track processed files and bytes
        let mut processed_files = 0;
        let mut processed_bytes = 0;
        
        // First, create any missing folders on the remote
        for (path, local_item) in local_files.iter().filter(|(_, item)| item.file_type == FileType::Folder) {
            // Check if already pause or stopped
            if *status.read().await.state == SyncState::Paused {
                return Ok(());
            }
            
            // Skip if the folder already exists on the remote
            if remote_files.contains_key(path) {
                continue;
            }
            
            // Update status
            let mut status_lock = status.write().await;
            status_lock.current_operation = Some("Creating folder".to_string());
            status_lock.current_file = Some(local_item.name.clone());
            status_lock.processed_files = processed_files;
            sync_repository.update_sync_status(&status_lock).await?;
            drop(status_lock);
            
            // Broadcast progress
            let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
            
            // Create the folder on the remote
            debug!("Creating remote folder: {}", path);
            let parent_id = Self::find_parent_id(remote_files, path);
            
            let mut new_folder = local_item.clone();
            new_folder.parent_id = parent_id;
            
            let created_folder = remote_repository.create_folder(new_folder).await?;
            
            // Update in our remote files map
            let remote_files_mut = unsafe { &mut *(remote_files as *const HashMap<String, FileItem> as *mut HashMap<String, FileItem>) };
            remote_files_mut.insert(path.clone(), created_folder);
            
            processed_files += 1;
            
            // Update status
            let mut status_lock = status.write().await;
            status_lock.processed_files = processed_files;
            sync_repository.update_sync_status(&status_lock).await?;
            drop(status_lock);
            
            // Broadcast progress
            let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        }
        
        // Then upload files
        for (path, local_item) in local_files.iter().filter(|(_, item)| item.file_type != FileType::Folder) {
            // Check if already paused or stopped
            if *status.read().await.state == SyncState::Paused {
                return Ok(());
            }
            
            // Check if the file exists remotely
            let should_upload = if let Some(remote_item) = remote_files.get(path) {
                // File exists - check if the local version is newer
                match last_sync {
                    Some(last_sync_time) => local_item.modified_at > last_sync_time && local_item.modified_at > remote_item.modified_at,
                    None => local_item.modified_at > remote_item.modified_at,
                }
            } else {
                // File doesn't exist remotely - upload it
                true
            };
            
            if should_upload {
                // Update status
                let mut status_lock = status.write().await;
                status_lock.current_operation = Some("Uploading file".to_string());
                status_lock.current_file = Some(local_item.name.clone());
                status_lock.processed_files = processed_files;
                status_lock.processed_bytes = processed_bytes;
                sync_repository.update_sync_status(&status_lock).await?;
                drop(status_lock);
                
                // Broadcast progress
                let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
                
                // Get file content
                debug!("Uploading file: {}", path);
                let content = local_repository.get_file_content(&local_item.id).await?;
                
                // Find the parent folder ID
                let parent_id = Self::find_parent_id(remote_files, path);
                
                // Upload the file
                let mut new_file = local_item.clone();
                new_file.parent_id = parent_id;
                
                if let Some(remote_item) = remote_files.get(path) {
                    // Update existing file
                    let mut updated_file = remote_item.clone();
                    updated_file.size = content.len() as u64;
                    updated_file.modified_at = Utc::now();
                    
                    let _updated = remote_repository.update_file(updated_file, Some(content)).await?;
                } else {
                    // Create new file
                    let _created = remote_repository.create_file(new_file, content.clone()).await?;
                }
                
                processed_files += 1;
                processed_bytes += content.len() as u64;
                
                // Update status
                let mut status_lock = status.write().await;
                status_lock.processed_files = processed_files;
                status_lock.processed_bytes = processed_bytes;
                sync_repository.update_sync_status(&status_lock).await?;
                drop(status_lock);
                
                // Broadcast progress
                let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
            }
        }
        
        Ok(())
    }
    
    /// Process downloads from remote to local
    async fn process_downloads(
        sync_repository: Arc<dyn SyncRepository>,
        local_repository: Arc<dyn FileRepository>,
        remote_repository: Arc<dyn FileRepository>,
        status: Arc<RwLock<SyncStatus>>,
        local_files: &HashMap<String, FileItem>,
        remote_files: &HashMap<String, FileItem>,
        last_sync: Option<DateTime<Utc>>,
        event_sender: broadcast::Sender<SyncEvent>,
    ) -> SyncResult<()> {
        debug!("Processing downloads...");
        
        let mut status_lock = status.write().await;
        status_lock.current_operation = Some("Processing downloads".to_string());
        sync_repository.update_sync_status(&status_lock).await?;
        drop(status_lock);
        
        // Broadcast progress
        let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        
        // Track processed files and bytes
        let mut processed_files = 0;
        let mut processed_bytes = 0;
        
        // First check if we have a base directory to sync to
        let sync_config = sync_repository.get_sync_config().await?;
        let base_dir = match &sync_config.sync_folder {
            Some(dir) => dir.clone(),
            None => {
                // Use the default home directory + OxiCloud
                let home = dirs::home_dir()
                    .ok_or_else(|| SyncError::FileSystemError("Could not determine home directory".to_string()))?;
                home.join("OxiCloud")
            }
        };
        
        // Create the base directory if it doesn't exist
        if !base_dir.exists() {
            tokio::fs::create_dir_all(&base_dir).await
                .map_err(|e| SyncError::FileSystemError(format!("Failed to create sync directory: {}", e)))?;
        }
        
        // First, create any missing folders locally
        for (path, remote_item) in remote_files.iter().filter(|(_, item)| item.file_type == FileType::Folder) {
            // Check if already paused or stopped
            if *status.read().await.state == SyncState::Paused {
                return Ok(());
            }
            
            // Skip if the folder already exists locally
            if local_files.contains_key(path) {
                continue;
            }
            
            // Update status
            let mut status_lock = status.write().await;
            status_lock.current_operation = Some("Creating local folder".to_string());
            status_lock.current_file = Some(remote_item.name.clone());
            status_lock.processed_files = processed_files;
            sync_repository.update_sync_status(&status_lock).await?;
            drop(status_lock);
            
            // Broadcast progress
            let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
            
            // Create the local folder path
            let local_folder_path = Self::remote_path_to_local(&base_dir, path);
            
            // Create the folder locally
            debug!("Creating local folder: {}", local_folder_path.display());
            tokio::fs::create_dir_all(&local_folder_path).await
                .map_err(|e| SyncError::FileSystemError(format!("Failed to create directory: {}", e)))?;
            
            // Create the folder in our local repository
            let parent_id = Self::find_parent_id(local_files, path);
            
            let mut new_folder = remote_item.clone();
            new_folder.parent_id = parent_id;
            new_folder.local_path = Some(local_folder_path.to_string_lossy().to_string());
            
            let _created_folder = local_repository.create_folder(new_folder).await?;
            
            processed_files += 1;
            
            // Update status
            let mut status_lock = status.write().await;
            status_lock.processed_files = processed_files;
            sync_repository.update_sync_status(&status_lock).await?;
            drop(status_lock);
            
            // Broadcast progress
            let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
        }
        
        // Then download files
        for (path, remote_item) in remote_files.iter().filter(|(_, item)| item.file_type != FileType::Folder) {
            // Check if already paused or stopped
            if *status.read().await.state == SyncState::Paused {
                return Ok(());
            }
            
            // Check if the file exists locally
            let should_download = if let Some(local_item) = local_files.get(path) {
                // File exists - check if the remote version is newer
                match last_sync {
                    Some(last_sync_time) => remote_item.modified_at > last_sync_time && remote_item.modified_at > local_item.modified_at,
                    None => remote_item.modified_at > local_item.modified_at,
                }
            } else {
                // File doesn't exist locally - download it
                true
            };
            
            // Check for conflicts
            let has_conflict = if let Some(local_item) = local_files.get(path) {
                // Both files exist - check if both have been modified since last sync
                match last_sync {
                    Some(last_sync_time) => {
                        local_item.modified_at > last_sync_time && 
                        remote_item.modified_at > last_sync_time &&
                        local_item.modified_at != remote_item.modified_at
                    },
                    None => false,
                }
            } else {
                false
            };
            
            if has_conflict {
                debug!("Conflict detected for file: {}", path);
                
                // Mark the file as conflicted
                if let Some(local_item) = local_files.get(path) {
                    let mut conflicted_item = local_item.clone();
                    conflicted_item.sync_status = FileSyncStatus::Conflicted;
                    
                    // Update the local file
                    let _updated = local_repository.update_file(conflicted_item, None).await?;
                    
                    // Skip downloading this file until conflict is resolved
                    continue;
                }
            }
            
            if should_download && !has_conflict {
                // Update status
                let mut status_lock = status.write().await;
                status_lock.current_operation = Some("Downloading file".to_string());
                status_lock.current_file = Some(remote_item.name.clone());
                status_lock.processed_files = processed_files;
                status_lock.processed_bytes = processed_bytes;
                sync_repository.update_sync_status(&status_lock).await?;
                drop(status_lock);
                
                // Broadcast progress
                let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
                
                // Create the local file path
                let local_file_path = Self::remote_path_to_local(&base_dir, path);
                
                // Create parent directories if needed
                if let Some(parent) = local_file_path.parent() {
                    tokio::fs::create_dir_all(parent).await
                        .map_err(|e| SyncError::FileSystemError(format!("Failed to create parent directory: {}", e)))?;
                }
                
                // Get file content
                debug!("Downloading file: {} to {}", path, local_file_path.display());
                let content = remote_repository.get_file_content(&remote_item.id).await?;
                
                // Write the file locally
                tokio::fs::write(&local_file_path, &content).await
                    .map_err(|e| SyncError::FileSystemError(format!("Failed to write file: {}", e)))?;
                
                // Find the parent folder ID
                let parent_id = Self::find_parent_id(local_files, path);
                
                if let Some(local_item) = local_files.get(path) {
                    // Update existing file
                    let mut updated_file = local_item.clone();
                    updated_file.size = content.len() as u64;
                    updated_file.modified_at = remote_item.modified_at;
                    updated_file.sync_status = FileSyncStatus::Synced;
                    updated_file.local_path = Some(local_file_path.to_string_lossy().to_string());
                    
                    // Keep the encrypted status
                    if remote_item.encryption_status == EncryptionStatus::Encrypted {
                        updated_file.encryption_status = EncryptionStatus::Encrypted;
                        updated_file.encryption_iv = remote_item.encryption_iv.clone();
                        updated_file.encryption_metadata = remote_item.encryption_metadata.clone();
                    }
                    
                    let _updated = local_repository.update_file(updated_file, None).await?;
                } else {
                    // Create new file
                    let mut new_file = remote_item.clone();
                    new_file.parent_id = parent_id;
                    new_file.local_path = Some(local_file_path.to_string_lossy().to_string());
                    new_file.sync_status = FileSyncStatus::Synced;
                    
                    let _created = local_repository.create_file(new_file, Vec::new()).await?;
                }
                
                processed_files += 1;
                processed_bytes += content.len() as u64;
                
                // Update status
                let mut status_lock = status.write().await;
                status_lock.processed_files = processed_files;
                status_lock.processed_bytes = processed_bytes;
                sync_repository.update_sync_status(&status_lock).await?;
                drop(status_lock);
                
                // Broadcast progress
                let _ = event_sender.send(SyncEvent::Progress(status.read().await.clone()));
            }
        }
        
        Ok(())
    }
    
    /// Find the parent ID for a path
    fn find_parent_id(files: &HashMap<String, FileItem>, path: &str) -> Option<String> {
        let path_obj = Path::new(path);
        
        if let Some(parent_path) = path_obj.parent() {
            let parent_path_str = parent_path.to_string_lossy();
            
            if parent_path_str == "/" || parent_path_str.is_empty() {
                return None;
            }
            
            if let Some(parent) = files.get(&parent_path_str.to_string()) {
                return Some(parent.id.clone());
            }
        }
        
        None
    }
    
    /// Convert a remote path to a local path
    fn remote_path_to_local(base_dir: &Path, remote_path: &str) -> PathBuf {
        // Strip leading slash if present
        let path = if remote_path.starts_with('/') {
            &remote_path[1..]
        } else {
            remote_path
        };
        
        base_dir.join(path)
    }
}