use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::{Duration, Instant};

use tokio::sync::{broadcast, mpsc, Mutex, RwLock};
use tokio::time;
use notify::{Config, Event, EventKind, RecommendedWatcher, RecursiveMode, Watcher, WatcherKind};
use futures::stream::{self, Stream, StreamExt};
use async_trait::async_trait;
use tracing::{debug, error, info, warn};

use crate::domain::entities::file::{FileError, FileResult, FileItem, FileType, SyncStatus};
use crate::domain::entities::sync::{SyncConfig, SyncError, SyncResult};
use crate::domain::repositories::file_repository::FileRepository;
use crate::domain::repositories::sync_repository::SyncRepository;
use crate::domain::services::sync_service::{SyncEvent, SyncService};

/// Event from the file system
#[derive(Debug, Clone)]
pub enum FileSystemEvent {
    /// A file was created
    Created(PathBuf),
    /// A file was modified
    Modified(PathBuf),
    /// A file was deleted
    Deleted(PathBuf),
    /// A file was renamed
    Renamed(PathBuf, PathBuf),
    /// Multiple events batched together
    Multiple(Vec<FileSystemEvent>),
    /// Error occurred
    Error(String),
}

impl From<notify::Event> for FileSystemEvent {
    fn from(event: notify::Event) -> Self {
        match event.kind {
            EventKind::Create(_) => {
                FileSystemEvent::Created(event.paths.first().cloned().unwrap_or_default())
            }
            EventKind::Modify(_) => {
                FileSystemEvent::Modified(event.paths.first().cloned().unwrap_or_default())
            }
            EventKind::Remove(_) => {
                FileSystemEvent::Deleted(event.paths.first().cloned().unwrap_or_default())
            }
            EventKind::Rename(rename) => {
                if event.paths.len() >= 2 {
                    // We have both from and to paths
                    FileSystemEvent::Renamed(event.paths[0].clone(), event.paths[1].clone())
                } else {
                    // Only have from path, treat as deletion
                    FileSystemEvent::Deleted(event.paths.first().cloned().unwrap_or_default())
                }
            }
            _ => {
                // Other events are ignored
                FileSystemEvent::Multiple(Vec::new())
            }
        }
    }
}

/// The file watcher service monitors changes to the local file system
pub struct FileWatcher {
    /// Base directory to watch
    base_dir: PathBuf,
    /// Whether the watcher is running
    running: Arc<RwLock<bool>>,
    /// Paths excluded from watching
    excluded_paths: Arc<RwLock<HashSet<PathBuf>>>,
    /// Debounced events map (path -> last event time)
    debounced_events: Arc<Mutex<HashMap<PathBuf, Instant>>>,
    /// Event channel sender
    event_sender: Arc<Mutex<Option<mpsc::Sender<FileSystemEvent>>>>,
    /// Change queue
    change_queue: mpsc::Sender<FileSystemEvent>,
    /// Change queue receiver
    change_queue_receiver: Arc<Mutex<Option<mpsc::Receiver<FileSystemEvent>>>>,
    /// Local file repository
    file_repository: Arc<dyn FileRepository>,
    /// Sync repository
    sync_repository: Arc<dyn SyncRepository>,
    /// Sync service
    sync_service: Arc<dyn SyncService>,
    /// Broadcast sender for sync events
    sync_event_sender: broadcast::Sender<SyncEvent>,
}

impl FileWatcher {
    pub fn new(
        base_dir: PathBuf,
        file_repository: Arc<dyn FileRepository>,
        sync_repository: Arc<dyn SyncRepository>,
        sync_service: Arc<dyn SyncService>,
    ) -> Self {
        let (change_sender, change_receiver) = mpsc::channel(1000);
        let (sync_event_sender, _) = broadcast::channel(100);
        
        Self {
            base_dir,
            running: Arc::new(RwLock::new(false)),
            excluded_paths: Arc::new(RwLock::new(HashSet::new())),
            debounced_events: Arc::new(Mutex::new(HashMap::new())),
            event_sender: Arc::new(Mutex::new(None)),
            change_queue: change_sender,
            change_queue_receiver: Arc::new(Mutex::new(Some(change_receiver))),
            file_repository,
            sync_repository,
            sync_service,
            sync_event_sender,
        }
    }
    
    /// Start watching for file system changes
    pub async fn start(&self) -> FileResult<()> {
        // Check if already running
        if *self.running.read().await {
            return Err(FileError::OperationError("File watcher already running".to_string()));
        }
        
        // Load excluded paths from sync config
        let config = self.sync_repository.get_sync_config().await
            .map_err(|e| FileError::OperationError(format!("Failed to get sync config: {}", e)))?;
            
        // Convert excluded paths to PathBuf
        let excluded = config.excluded_paths.iter()
            .map(|p| self.base_dir.join(p))
            .collect();
            
        *self.excluded_paths.write().await = excluded;
        
        // Create a channel for the watcher to send events
        let (tx, mut rx) = mpsc::channel(1000);
        *self.event_sender.lock().await = Some(tx);
        
        // Start the watcher thread
        let running = self.running.clone();
        let base_dir = self.base_dir.clone();
        let excluded_paths = self.excluded_paths.clone();
        let debounced_events = self.debounced_events.clone();
        let change_queue = self.change_queue.clone();
        
        *running.write().await = true;
        
        // Launch the filesystem watcher in a background task
        tokio::spawn(async move {
            // Create the watcher
            let (watcher_tx, mut watcher_rx) = mpsc::channel(1000);
            
            let mut watcher = match RecommendedWatcher::new(
                move |res| {
                    let _ = futures::executor::block_on(watcher_tx.send(res));
                },
                Config::default(),
            ) {
                Ok(w) => w,
                Err(e) => {
                    error!("Failed to create file watcher: {}", e);
                    return;
                }
            };
            
            // Start watching the base directory
            if let Err(e) = watcher.watch(base_dir.as_path(), RecursiveMode::Recursive) {
                error!("Failed to watch directory: {}", e);
                return;
            }
            
            info!("Started watching directory: {}", base_dir.display());
            
            // Event processing loop
            let debounce_timeout = Duration::from_millis(500);
            
            while *running.read().await {
                // Process all pending events
                while let Ok(Some(event)) = tokio::time::timeout(Duration::from_millis(100), watcher_rx.recv()).await {
                    match event {
                        Ok(event) => {
                            // Convert to our event type
                            let fs_event = FileSystemEvent::from(event);
                            
                            // Skip excluded paths
                            let should_skip = match &fs_event {
                                FileSystemEvent::Created(path) | 
                                FileSystemEvent::Modified(path) | 
                                FileSystemEvent::Deleted(path) => {
                                    Self::should_exclude(path, &excluded_paths.read().await)
                                },
                                FileSystemEvent::Renamed(from, to) => {
                                    Self::should_exclude(from, &excluded_paths.read().await) || 
                                    Self::should_exclude(to, &excluded_paths.read().await)
                                },
                                FileSystemEvent::Multiple(events) => {
                                    events.iter().any(|e| {
                                        match e {
                                            FileSystemEvent::Created(path) | 
                                            FileSystemEvent::Modified(path) | 
                                            FileSystemEvent::Deleted(path) => {
                                                Self::should_exclude(path, &excluded_paths.read().await)
                                            },
                                            FileSystemEvent::Renamed(from, to) => {
                                                Self::should_exclude(from, &excluded_paths.read().await) || 
                                                Self::should_exclude(to, &excluded_paths.read().await)
                                            },
                                            _ => false,
                                        }
                                    })
                                },
                                _ => false,
                            };
                            
                            if should_skip {
                                continue;
                            }
                            
                            // Debounce the event
                            let should_process = match &fs_event {
                                FileSystemEvent::Created(path) | 
                                FileSystemEvent::Modified(path) => {
                                    let mut debounced = debounced_events.lock().await;
                                    let now = Instant::now();
                                    
                                    if let Some(last_time) = debounced.get(path) {
                                        if now.duration_since(*last_time) < debounce_timeout {
                                            // Too soon, update timestamp and skip
                                            debounced.insert(path.clone(), now);
                                            false
                                        } else {
                                            // Enough time passed, update timestamp and process
                                            debounced.insert(path.clone(), now);
                                            true
                                        }
                                    } else {
                                        // First time seeing this path, add and process
                                        debounced.insert(path.clone(), now);
                                        true
                                    }
                                },
                                FileSystemEvent::Deleted(path) => {
                                    // Always process deletions
                                    debounced_events.lock().await.remove(path);
                                    true
                                },
                                FileSystemEvent::Renamed(from, to) => {
                                    // Always process renames
                                    debounced_events.lock().await.remove(from);
                                    debounced_events.lock().await.insert(to.clone(), Instant::now());
                                    true
                                },
                                FileSystemEvent::Multiple(_) | FileSystemEvent::Error(_) => true,
                            };
                            
                            if should_process {
                                // Send event to change queue
                                debug!("Detected file system event: {:?}", fs_event);
                                
                                if let Err(e) = change_queue.send(fs_event).await {
                                    error!("Failed to send file system event to change queue: {}", e);
                                }
                            }
                        },
                        Err(e) => {
                            error!("File watcher error: {}", e);
                            
                            // Send error to change queue
                            let error_event = FileSystemEvent::Error(format!("File watcher error: {}", e));
                            if let Err(e) = change_queue.send(error_event).await {
                                error!("Failed to send error event to change queue: {}", e);
                            }
                        }
                    }
                }
                
                // Clean up old debounced events
                let mut debounced = debounced_events.lock().await;
                let now = Instant::now();
                debounced.retain(|_, time| now.duration_since(*time) < debounce_timeout * 2);
                
                // Sleep a bit to avoid high CPU usage
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
            
            info!("File watcher stopped");
        });
        
        // Start the change processor
        self.start_change_processor().await;
        
        Ok(())
    }
    
    /// Start the change processor thread
    async fn start_change_processor(&self) {
        let running = self.running.clone();
        let base_dir = self.base_dir.clone();
        let file_repository = self.file_repository.clone();
        let sync_service = self.sync_service.clone();
        let sync_event_sender = self.sync_event_sender.clone();
        
        // Get the change queue receiver
        let mut receiver = self.change_queue_receiver.lock().await.take()
            .expect("Change queue receiver already taken");
        
        // Launch the change processor in a background task
        tokio::spawn(async move {
            info!("Change processor started");
            
            while *running.read().await {
                // Process any pending events
                if let Some(event) = receiver.recv().await {
                    match event {
                        FileSystemEvent::Created(path) => {
                            debug!("Processing file creation: {}", path.display());
                            Self::handle_file_created(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                        },
                        FileSystemEvent::Modified(path) => {
                            debug!("Processing file modification: {}", path.display());
                            Self::handle_file_modified(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                        },
                        FileSystemEvent::Deleted(path) => {
                            debug!("Processing file deletion: {}", path.display());
                            Self::handle_file_deleted(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                        },
                        FileSystemEvent::Renamed(from, to) => {
                            debug!("Processing file rename: {} -> {}", from.display(), to.display());
                            Self::handle_file_renamed(file_repository.clone(), &base_dir, &from, &to, sync_event_sender.clone()).await;
                        },
                        FileSystemEvent::Multiple(events) => {
                            for event in events {
                                match event {
                                    FileSystemEvent::Created(path) => {
                                        Self::handle_file_created(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                                    },
                                    FileSystemEvent::Modified(path) => {
                                        Self::handle_file_modified(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                                    },
                                    FileSystemEvent::Deleted(path) => {
                                        Self::handle_file_deleted(file_repository.clone(), &base_dir, &path, sync_event_sender.clone()).await;
                                    },
                                    FileSystemEvent::Renamed(from, to) => {
                                        Self::handle_file_renamed(file_repository.clone(), &base_dir, &from, &to, sync_event_sender.clone()).await;
                                    },
                                    _ => {},
                                }
                            }
                        },
                        FileSystemEvent::Error(error) => {
                            error!("File system error: {}", error);
                            // Broadcast error event
                            let _ = sync_event_sender.send(SyncEvent::Error(format!("File system error: {}", error)));
                        }
                    }
                    
                    // Trigger a sync if needed
                    if let Ok(config) = sync_service.get_sync_config().await {
                        if config.sync_on_file_change {
                            debug!("Triggering sync due to file change");
                            let _ = sync_service.start_sync().await;
                        }
                    }
                }
                
                // Sleep a bit to avoid high CPU usage
                tokio::time::sleep(Duration::from_millis(100)).await;
            }
            
            info!("Change processor stopped");
        });
    }
    
    /// Stop watching for file system changes
    pub async fn stop(&self) -> FileResult<()> {
        if !*self.running.read().await {
            return Err(FileError::OperationError("File watcher not running".to_string()));
        }
        
        *self.running.write().await = false;
        
        // Clear the event sender
        self.event_sender.lock().await.take();
        
        Ok(())
    }
    
    /// Check if a path should be excluded
    fn should_exclude(path: &Path, excluded_paths: &HashSet<PathBuf>) -> bool {
        // Check if the path is excluded
        if excluded_paths.contains(path) {
            return true;
        }
        
        // Check if any parent directory is excluded
        let mut current = Some(path);
        while let Some(p) = current {
            if excluded_paths.contains(p) {
                return true;
            }
            current = p.parent();
        }
        
        // Check if path is hidden (starts with .)
        if let Some(file_name) = path.file_name() {
            if let Some(name_str) = file_name.to_str() {
                if name_str.starts_with(".") {
                    return true;
                }
            }
        }
        
        false
    }
    
    /// Handle file creation event
    async fn handle_file_created(
        file_repository: Arc<dyn FileRepository>,
        base_dir: &Path,
        path: &Path,
        event_sender: broadcast::Sender<SyncEvent>,
    ) {
        // Make sure this is a path under our base directory
        if !path.starts_with(base_dir) {
            return;
        }
        
        // Convert to relative path
        let rel_path = path.strip_prefix(base_dir).unwrap_or(path);
        
        // Check if the file already exists in the repository
        match file_repository.get_file_from_path(path).await {
            Ok(Some(_)) => {
                // File already exists in repository, ignore creation event
                return;
            },
            Ok(None) => {
                // File doesn't exist yet, add it
                let parent_id = if let Some(parent) = path.parent() {
                    if parent == base_dir {
                        None
                    } else {
                        // Find the parent file item
                        match file_repository.get_file_from_path(parent).await {
                            Ok(Some(parent_item)) => Some(parent_item.id),
                            _ => None,
                        }
                    }
                } else {
                    None
                };
                
                // Create the file item
                let result = file_repository.upload_file_from_path(path, parent_id.as_deref()).await;
                
                match result {
                    Ok(file) => {
                        debug!("Added new file to repository: {} ({})", path.display(), file.id);
                        
                        // Broadcast file changed event
                        let _ = event_sender.send(SyncEvent::FileChanged(file));
                    },
                    Err(e) => {
                        error!("Failed to add file to repository: {}", e);
                        
                        // Broadcast error event
                        let _ = event_sender.send(SyncEvent::Error(format!("Failed to add file to repository: {}", e)));
                    }
                }
            },
            Err(e) => {
                error!("Failed to check if file exists: {}", e);
            }
        }
    }
    
    /// Handle file modification event
    async fn handle_file_modified(
        file_repository: Arc<dyn FileRepository>,
        base_dir: &Path,
        path: &Path,
        event_sender: broadcast::Sender<SyncEvent>,
    ) {
        // Make sure this is a path under our base directory
        if !path.starts_with(base_dir) {
            return;
        }
        
        // Check if the file exists in the repository
        match file_repository.get_file_from_path(path).await {
            Ok(Some(mut file)) => {
                // Update the file's metadata
                let metadata = match tokio::fs::metadata(path).await {
                    Ok(meta) => meta,
                    Err(e) => {
                        error!("Failed to get file metadata: {}", e);
                        return;
                    }
                };
                
                // Update file size and modification time
                file.size = metadata.len();
                file.modified_at = chrono::Utc::now();
                file.sync_status = SyncStatus::PendingUpload;
                
                // Update the file
                match file_repository.update_file(file.clone(), None).await {
                    Ok(_) => {
                        debug!("Updated file in repository: {} ({})", path.display(), file.id);
                        
                        // Broadcast file changed event
                        let _ = event_sender.send(SyncEvent::FileChanged(file));
                    },
                    Err(e) => {
                        error!("Failed to update file in repository: {}", e);
                        
                        // Broadcast error event
                        let _ = event_sender.send(SyncEvent::Error(format!("Failed to update file in repository: {}", e)));
                    }
                }
            },
            Ok(None) => {
                // File doesn't exist in repository, treat as creation
                Self::handle_file_created(file_repository, base_dir, path, event_sender).await;
            },
            Err(e) => {
                error!("Failed to check if file exists: {}", e);
            }
        }
    }
    
    /// Handle file deletion event
    async fn handle_file_deleted(
        file_repository: Arc<dyn FileRepository>,
        base_dir: &Path,
        path: &Path,
        event_sender: broadcast::Sender<SyncEvent>,
    ) {
        // Make sure this is a path under our base directory
        if !path.starts_with(base_dir) {
            return;
        }
        
        // Check if the file exists in the repository
        match file_repository.get_file_from_path(path).await {
            Ok(Some(file)) => {
                // Delete the file from the repository
                let is_dir = file.file_type == FileType::Folder;
                
                let result = if is_dir {
                    file_repository.delete_folder(&file.id, true).await
                } else {
                    file_repository.delete_file(&file.id).await
                };
                
                match result {
                    Ok(_) => {
                        debug!("Deleted {} from repository: {} ({})", 
                            if is_dir { "folder" } else { "file" },
                            path.display(), file.id);
                            
                        // Broadcast file changed event (with deleted flag)
                        let mut deleted_file = file.clone();
                        deleted_file.sync_status = SyncStatus::PendingUpload;
                        let _ = event_sender.send(SyncEvent::FileChanged(deleted_file));
                    },
                    Err(e) => {
                        error!("Failed to delete {} from repository: {}", 
                            if is_dir { "folder" } else { "file" }, e);
                            
                        // Broadcast error event
                        let _ = event_sender.send(SyncEvent::Error(format!("Failed to delete file from repository: {}", e)));
                    }
                }
            },
            Ok(None) => {
                // File doesn't exist in repository, nothing to do
            },
            Err(e) => {
                error!("Failed to check if file exists: {}", e);
            }
        }
    }
    
    /// Handle file rename event
    async fn handle_file_renamed(
        file_repository: Arc<dyn FileRepository>,
        base_dir: &Path,
        from: &Path,
        to: &Path,
        event_sender: broadcast::Sender<SyncEvent>,
    ) {
        // Make sure paths are under our base directory
        if !from.starts_with(base_dir) || !to.starts_with(base_dir) {
            return;
        }
        
        // Check if the source file exists in the repository
        match file_repository.get_file_from_path(from).await {
            Ok(Some(mut file)) => {
                // Update the file's metadata
                file.name = to.file_name().unwrap_or_default().to_string_lossy().to_string();
                file.local_path = Some(to.to_string_lossy().to_string());
                file.sync_status = SyncStatus::PendingUpload;
                
                // If parent directory changed, update parent_id
                if from.parent() != to.parent() {
                    let parent_id = if let Some(parent) = to.parent() {
                        if parent == base_dir {
                            None
                        } else {
                            // Find the parent file item
                            match file_repository.get_file_from_path(parent).await {
                                Ok(Some(parent_item)) => Some(parent_item.id),
                                _ => None,
                            }
                        }
                    } else {
                        None
                    };
                    
                    file.parent_id = parent_id;
                }
                
                // Update the file
                match file_repository.update_file(file.clone(), None).await {
                    Ok(_) => {
                        debug!("Renamed file in repository: {} -> {} ({})", 
                            from.display(), to.display(), file.id);
                            
                        // Broadcast file changed event
                        let _ = event_sender.send(SyncEvent::FileChanged(file));
                    },
                    Err(e) => {
                        error!("Failed to rename file in repository: {}", e);
                        
                        // Broadcast error event
                        let _ = event_sender.send(SyncEvent::Error(format!("Failed to rename file in repository: {}", e)));
                    }
                }
            },
            Ok(None) => {
                // Source file doesn't exist in repository, treat as creation of target
                Self::handle_file_created(file_repository, base_dir, to, event_sender).await;
            },
            Err(e) => {
                error!("Failed to check if file exists: {}", e);
            }
        }
    }
}