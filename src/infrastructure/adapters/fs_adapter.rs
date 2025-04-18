use async_trait::async_trait;
use chrono::{DateTime, Utc};
use dirs;
use notify::{Config, EventKind, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use tokio::fs::{self, File};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::sync::mpsc::{self, Receiver, Sender};
use tokio::sync::Mutex;
use tokio::time::{sleep, Duration};
use tracing::{debug, error, info, warn};
use uuid::Uuid;
use walkdir::WalkDir;

use crate::domain::entities::file::{FileError, FileItem, FileResult, FileType, SyncStatus};
use crate::domain::repositories::auth_repository::AuthRepository;
use crate::domain::repositories::file_repository::FileRepository;

/// Implementation of the FileRepository that interacts with the local file system
/// This adapter is responsible for watching local files and managing sync between
/// local and remote state.
pub struct FileSystemAdapter {
    /// Base directory for synced files
    sync_dir: PathBuf,
    /// Cache of file metadata indexed by ID
    file_cache: Arc<Mutex<HashMap<String, FileItem>>>,
    /// Cache of file metadata indexed by path
    path_cache: Arc<Mutex<HashMap<PathBuf, String>>>,
    /// Authentication repository for user info
    auth_repository: Arc<dyn AuthRepository>,
    /// Channel for file system events
    event_sender: Option<Sender<(PathBuf, EventKind)>>,
    /// File watcher to monitor changes
    _watcher: Option<RecommendedWatcher>,
}

impl FileSystemAdapter {
    pub async fn new(auth_repository: Arc<dyn AuthRepository>) -> Result<Self, FileError> {
        // Determine the sync directory based on the user's home directory
        let home_dir = dirs::home_dir().ok_or_else(|| {
            FileError::OperationError("Could not determine home directory".to_string())
        })?;
        
        let sync_dir = home_dir.join("OxiCloud");
        
        // Create the sync directory if it doesn't exist
        if !sync_dir.exists() {
            fs::create_dir_all(&sync_dir)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to create sync directory: {}", e)))?;
            
            info!("Created sync directory at {:?}", sync_dir);
        }
        
        let file_cache = Arc::new(Mutex::new(HashMap::new()));
        let path_cache = Arc::new(Mutex::new(HashMap::new()));
        
        Ok(Self {
            sync_dir,
            file_cache,
            path_cache,
            auth_repository,
            event_sender: None,
            _watcher: None,
        })
    }

    /// Start watching the sync directory for changes
    pub async fn start_watching(&mut self) -> FileResult<()> {
        // Create channel for file system events
        let (tx, rx) = mpsc::channel(100);
        
        // Create file watcher
        let watcher = Self::create_watcher(self.sync_dir.clone(), tx.clone())?;
        
        self.event_sender = Some(tx);
        self._watcher = Some(watcher);
        
        // Spawn a task to process file system events
        let file_cache = self.file_cache.clone();
        let path_cache = self.path_cache.clone();
        let sync_dir = self.sync_dir.clone();
        
        tokio::spawn(async move {
            Self::process_events(rx, file_cache, path_cache, sync_dir).await;
        });
        
        Ok(())
    }
    
    /// Create a file watcher for the sync directory
    fn create_watcher(
        sync_dir: PathBuf,
        tx: Sender<(PathBuf, EventKind)>,
    ) -> FileResult<RecommendedWatcher> {
        let mut watcher = notify::recommended_watcher(move |res| {
            match res {
                Ok(event) => {
                    if let Some(path) = event.paths.first() {
                        // Clone the sender and path for async dispatch
                        let tx_clone = tx.clone();
                        let path_clone = path.clone();
                        let kind = event.kind.clone();
                        
                        // Dispatch event to channel
                        tokio::spawn(async move {
                            if let Err(e) = tx_clone.send((path_clone, kind)).await {
                                error!("Failed to send file system event: {}", e);
                            }
                        });
                    }
                }
                Err(e) => error!("File system watcher error: {}", e),
            }
        })
        .map_err(|e| FileError::OperationError(format!("Failed to create file watcher: {}", e)))?;
        
        // Start watching the sync directory
        watcher
            .watch(&sync_dir, RecursiveMode::Recursive)
            .map_err(|e| FileError::OperationError(format!("Failed to watch directory: {}", e)))?;
        
        info!("Started watching directory: {:?}", sync_dir);
        
        Ok(watcher)
    }
    
    /// Process file system events from the watcher
    async fn process_events(
        mut rx: Receiver<(PathBuf, EventKind)>,
        file_cache: Arc<Mutex<HashMap<String, FileItem>>>,
        path_cache: Arc<Mutex<HashMap<PathBuf, String>>>,
        sync_dir: PathBuf,
    ) {
        // Map to collect and deduplicate events within a short time window
        let mut event_batch: HashMap<PathBuf, EventKind> = HashMap::new();
        
        loop {
            // Collect events with a short timeout to batch related events
            tokio::select! {
                Some((path, kind)) = rx.recv() => {
                    // Update the most recent event for this path
                    event_batch.insert(path, kind);
                }
                _ = sleep(Duration::from_millis(500)) => {
                    if !event_batch.is_empty() {
                        // Process the batch of events
                        for (path, kind) in event_batch.drain() {
                            Self::handle_file_event(&path, kind, &file_cache, &path_cache, &sync_dir).await;
                        }
                    }
                }
            }
        }
    }
    
    /// Handle a single file system event
    async fn handle_file_event(
        path: &Path,
        kind: EventKind,
        file_cache: &Arc<Mutex<HashMap<String, FileItem>>>,
        path_cache: &Arc<Mutex<HashMap<PathBuf, String>>>,
        sync_dir: &Path,
    ) {
        // Check if the path is within the sync directory
        if !path.starts_with(sync_dir) {
            return;
        }
        
        // Get relative path from sync directory
        let rel_path = path.strip_prefix(sync_dir).unwrap_or(path);
        
        match kind {
            // File created or modified
            EventKind::Create(_) | EventKind::Modify(_) => {
                if path.is_file() {
                    // Update file in cache
                    if let Ok(metadata) = tokio::fs::metadata(path).await {
                        let file_id = {
                            let path_cache_lock = path_cache.lock().await;
                            path_cache_lock.get(path).cloned()
                        };
                        
                        // Get or create file ID
                        let file_id = file_id.unwrap_or_else(|| Uuid::new_v4().to_string());
                        
                        // Create file item
                        let file_type = if path.is_dir() {
                            FileType::Directory
                        } else {
                            FileType::File
                        };
                        
                        let name = path.file_name()
                            .and_then(|n| n.to_str())
                            .unwrap_or("unnamed")
                            .to_string();
                            
                        let parent_id = {
                            if let Some(parent) = path.parent() {
                                if parent != sync_dir {
                                    let parent_rel = parent.strip_prefix(sync_dir).unwrap_or(parent);
                                    let path_cache_lock = path_cache.lock().await;
                                    path_cache_lock.get(&parent.to_path_buf()).cloned()
                                } else {
                                    None
                                }
                            } else {
                                None
                            }
                        };
                        
                        let mime_type = if path.is_file() {
                            mime_guess::from_path(path)
                                .first_or_octet_stream()
                                .to_string()
                        } else {
                            "application/directory".to_string()
                        };
                        
                        // Create file item
                        let file_item = FileItem {
                            id: file_id.clone(),
                            name,
                            path: rel_path.to_string_lossy().to_string(),
                            file_type,
                            size: metadata.len(),
                            mime_type: Some(mime_type),
                            parent_id,
                            created_at: DateTime::<Utc>::from(metadata.created().unwrap_or_else(|_| std::time::SystemTime::now())),
                            modified_at: DateTime::<Utc>::from(metadata.modified().unwrap_or_else(|_| std::time::SystemTime::now())),
                            sync_status: SyncStatus::PendingUpload,
                            is_favorite: false,
                            local_path: Some(path.to_string_lossy().to_string()),
                        };
                        
                        // Update caches
                        {
                            let mut file_cache_lock = file_cache.lock().await;
                            file_cache_lock.insert(file_id.clone(), file_item);
                            
                            let mut path_cache_lock = path_cache.lock().await;
                            path_cache_lock.insert(path.to_path_buf(), file_id);
                        }
                        
                        debug!("Updated file in cache: {:?}", path);
                    }
                }
            },
            // File removed
            EventKind::Remove(_) => {
                // Remove from caches
                let file_id = {
                    let mut path_cache_lock = path_cache.lock().await;
                    path_cache_lock.remove(path)
                };
                
                if let Some(id) = file_id {
                    let mut file_cache_lock = file_cache.lock().await;
                    file_cache_lock.remove(&id);
                    debug!("Removed file from cache: {:?}", path);
                }
            },
            _ => {
                // Ignore other event types
            }
        }
    }
    
    /// Get the base sync directory
    pub fn get_sync_dir(&self) -> &Path {
        &self.sync_dir
    }
    
    /// Scan the local sync directory to populate caches
    pub async fn scan_directory(&self) -> FileResult<Vec<FileItem>> {
        let mut files = Vec::new();
        
        // Walk through the sync directory recursively
        for entry in WalkDir::new(&self.sync_dir) {
            let entry = match entry {
                Ok(e) => e,
                Err(e) => {
                    warn!("Failed to access entry during directory scan: {}", e);
                    continue;
                }
            };
            
            let path = entry.path();
            
            // Skip the root sync directory itself
            if path == self.sync_dir {
                continue;
            }
            
            // Get relative path from sync directory
            let rel_path = path.strip_prefix(&self.sync_dir).unwrap_or(path);
            
            // Get file metadata
            if let Ok(metadata) = path.metadata() {
                let file_id = Uuid::new_v4().to_string();
                
                let file_type = if path.is_dir() {
                    FileType::Directory
                } else {
                    FileType::File
                };
                
                let name = path.file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("unnamed")
                    .to_string();
                    
                let parent_path = path.parent().unwrap_or(Path::new(""));
                let parent_id = if parent_path != self.sync_dir {
                    // Find parent ID in cache
                    let path_cache = self.path_cache.lock().await;
                    path_cache.get(&parent_path.to_path_buf()).cloned()
                } else {
                    None
                };
                
                let mime_type = if path.is_file() {
                    mime_guess::from_path(path)
                        .first_or_octet_stream()
                        .to_string()
                } else {
                    "application/directory".to_string()
                };
                
                // Create file item
                let file_item = FileItem {
                    id: file_id.clone(),
                    name,
                    path: rel_path.to_string_lossy().to_string(),
                    file_type,
                    size: if path.is_file() { metadata.len() } else { 0 },
                    mime_type: Some(mime_type),
                    parent_id,
                    created_at: DateTime::<Utc>::from(metadata.created().unwrap_or_else(|_| std::time::SystemTime::now())),
                    modified_at: DateTime::<Utc>::from(metadata.modified().unwrap_or_else(|_| std::time::SystemTime::now())),
                    sync_status: SyncStatus::PendingUpload,
                    is_favorite: false,
                    local_path: Some(path.to_string_lossy().to_string()),
                };
                
                // Update caches
                {
                    let mut file_cache = self.file_cache.lock().await;
                    file_cache.insert(file_id.clone(), file_item.clone());
                    
                    let mut path_cache = self.path_cache.lock().await;
                    path_cache.insert(path.to_path_buf(), file_id);
                }
                
                files.push(file_item);
            }
        }
        
        info!("Scanned {} local files/folders", files.len());
        
        Ok(files)
    }
    
    /// Resolve local path for a file
    fn resolve_path(&self, path: &str) -> PathBuf {
        // If path is absolute and within sync directory, use it directly
        let abs_path = PathBuf::from(path);
        if abs_path.is_absolute() && abs_path.starts_with(&self.sync_dir) {
            return abs_path;
        }
        
        // Otherwise, join with sync directory
        self.sync_dir.join(path.trim_start_matches('/'))
    }
}

#[async_trait]
impl FileRepository for FileSystemAdapter {
    async fn get_file_by_id(&self, file_id: &str) -> FileResult<FileItem> {
        let file_cache = self.file_cache.lock().await;
        
        file_cache.get(file_id)
            .cloned()
            .ok_or_else(|| FileError::OperationError(format!("File not found: {}", file_id)))
    }
    
    async fn get_files_by_folder(&self, folder_id: Option<&str>) -> FileResult<Vec<FileItem>> {
        let file_cache = self.file_cache.lock().await;
        
        let files = file_cache.values()
            .filter(|file| file.parent_id.as_deref() == folder_id)
            .cloned()
            .collect();
        
        Ok(files)
    }
    
    async fn get_file_content(&self, file_id: &str) -> FileResult<Vec<u8>> {
        let file_item = self.get_file_by_id(file_id).await?;
        
        let path = match &file_item.local_path {
            Some(p) => PathBuf::from(p),
            None => {
                return Err(FileError::OperationError(
                    format!("No local path for file: {}", file_id)
                ));
            }
        };
        
        let mut file = File::open(&path)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to open file: {}", e)))?;
            
        let mut content = Vec::new();
        file.read_to_end(&mut content)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to read file: {}", e)))?;
            
        Ok(content)
    }
    
    async fn create_file(&self, file: FileItem, content: Vec<u8>) -> FileResult<FileItem> {
        // Create path based on parent ID and filename
        let path = match &file.parent_id {
            Some(parent_id) => {
                let parent = self.get_file_by_id(parent_id).await?;
                let parent_path = match &parent.local_path {
                    Some(p) => PathBuf::from(p),
                    None => self.sync_dir.join(&parent.path.trim_start_matches('/')),
                };
                parent_path.join(&file.name)
            },
            None => self.sync_dir.join(&file.name),
        };
        
        // Create parent directories if needed
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to create directory: {}", e)))?;
        }
        
        // Write file content
        let mut file_handle = File::create(&path)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to create file: {}", e)))?;
            
        file_handle.write_all(&content)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to write file: {}", e)))?;
            
        // Create updated file item
        let mut new_file = file.clone();
        new_file.local_path = Some(path.to_string_lossy().to_string());
        new_file.size = content.len() as u64;
        new_file.modified_at = Utc::now();
        
        // Add to cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.insert(new_file.id.clone(), new_file.clone());
            
            let mut path_cache = self.path_cache.lock().await;
            path_cache.insert(path, new_file.id.clone());
        }
        
        Ok(new_file)
    }
    
    async fn update_file(&self, file: FileItem, content: Option<Vec<u8>>) -> FileResult<FileItem> {
        let current_file = self.get_file_by_id(&file.id).await?;
        
        let path = match &current_file.local_path {
            Some(p) => PathBuf::from(p),
            None => {
                return Err(FileError::OperationError(
                    format!("No local path for file: {}", file.id)
                ));
            }
        };
        
        // If parent ID changed, move the file
        if current_file.parent_id != file.parent_id {
            let new_path = match &file.parent_id {
                Some(parent_id) => {
                    let parent = self.get_file_by_id(parent_id).await?;
                    let parent_path = match &parent.local_path {
                        Some(p) => PathBuf::from(p),
                        None => self.sync_dir.join(&parent.path.trim_start_matches('/')),
                    };
                    parent_path.join(&file.name)
                },
                None => self.sync_dir.join(&file.name),
            };
            
            // Create parent directories if needed
            if let Some(parent) = new_path.parent() {
                fs::create_dir_all(parent)
                    .await
                    .map_err(|e| FileError::IOError(format!("Failed to create directory: {}", e)))?;
            }
            
            // Move file
            fs::rename(&path, &new_path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to move file: {}", e)))?;
                
            // Update cache
            {
                let mut path_cache = self.path_cache.lock().await;
                path_cache.remove(&path);
                path_cache.insert(new_path.clone(), file.id.clone());
            }
        }
        // If name changed but not parent, rename the file
        else if current_file.name != file.name {
            let new_path = path.with_file_name(&file.name);
            
            // Rename file
            fs::rename(&path, &new_path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to rename file: {}", e)))?;
                
            // Update cache
            {
                let mut path_cache = self.path_cache.lock().await;
                path_cache.remove(&path);
                path_cache.insert(new_path.clone(), file.id.clone());
            }
        }
        
        // Clone content early to avoid move issues
        let content_clone = content.clone();
        
        // If content provided, update file content
        if let Some(content_data) = content {
            let file_path = match &file.parent_id {
                Some(parent_id) => {
                    let parent = self.get_file_by_id(parent_id).await?;
                    let parent_path = match &parent.local_path {
                        Some(p) => PathBuf::from(p),
                        None => self.sync_dir.join(&parent.path.trim_start_matches('/')),
                    };
                    parent_path.join(&file.name)
                },
                None => self.sync_dir.join(&file.name),
            };
            
            let mut file_handle = File::create(&file_path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to create file: {}", e)))?;
                
            file_handle.write_all(&content_data)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to write file: {}", e)))?;
        }
        
        // Create updated file item
        let mut new_file = file.clone();
        new_file.modified_at = Utc::now();
        
        // If content was updated, update size
        if let Some(content_data) = &content_clone {
            new_file.size = content_data.len() as u64;
        }
        
        // Update cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.insert(new_file.id.clone(), new_file.clone());
        }
        
        Ok(new_file)
    }
    
    async fn delete_file(&self, file_id: &str) -> FileResult<()> {
        let file = self.get_file_by_id(file_id).await?;
        
        let path = match &file.local_path {
            Some(p) => PathBuf::from(p),
            None => {
                return Err(FileError::OperationError(
                    format!("No local path for file: {}", file_id)
                ));
            }
        };
        
        // Delete file
        fs::remove_file(&path)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to delete file: {}", e)))?;
            
        // Update cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.remove(file_id);
            
            let mut path_cache = self.path_cache.lock().await;
            path_cache.remove(&path);
        }
        
        Ok(())
    }
    
    async fn create_folder(&self, folder: FileItem) -> FileResult<FileItem> {
        // Create path based on parent ID and folder name
        let path = match &folder.parent_id {
            Some(parent_id) => {
                let parent = self.get_file_by_id(parent_id).await?;
                let parent_path = match &parent.local_path {
                    Some(p) => PathBuf::from(p),
                    None => self.sync_dir.join(&parent.path.trim_start_matches('/')),
                };
                parent_path.join(&folder.name)
            },
            None => self.sync_dir.join(&folder.name),
        };
        
        // Create directory
        fs::create_dir_all(&path)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to create directory: {}", e)))?;
            
        // Create updated folder item
        let mut new_folder = folder.clone();
        new_folder.local_path = Some(path.to_string_lossy().to_string());
        new_folder.modified_at = Utc::now();
        
        // Add to cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.insert(new_folder.id.clone(), new_folder.clone());
            
            let mut path_cache = self.path_cache.lock().await;
            path_cache.insert(path, new_folder.id.clone());
        }
        
        Ok(new_folder)
    }
    
    async fn delete_folder(&self, folder_id: &str, recursive: bool) -> FileResult<()> {
        let folder = self.get_file_by_id(folder_id).await?;
        
        if folder.file_type != FileType::Directory {
            return Err(FileError::OperationError(
                format!("Not a directory: {}", folder_id)
            ));
        }
        
        let path = match &folder.local_path {
            Some(p) => PathBuf::from(p),
            None => {
                return Err(FileError::OperationError(
                    format!("No local path for folder: {}", folder_id)
                ));
            }
        };
        
        // Delete directory
        if recursive {
            fs::remove_dir_all(&path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to delete directory: {}", e)))?;
        } else {
            fs::remove_dir(&path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to delete directory: {}", e)))?;
        }
        
        // Remove from cache recursively if needed
        {
            let mut file_cache = self.file_cache.lock().await;
            let mut path_cache = self.path_cache.lock().await;
            
            // First remove the folder itself
            file_cache.remove(folder_id);
            path_cache.remove(&path);
            
            // If recursive, remove all children
            if recursive {
                // Get all files in cache
                let all_files: Vec<_> = file_cache.values().cloned().collect();
                
                // Find all files with this folder as parent (directly or indirectly)
                for file in all_files {
                    if let Some(local_path) = &file.local_path {
                        let file_path = PathBuf::from(local_path);
                        if file_path.starts_with(&path) {
                            file_cache.remove(&file.id);
                            path_cache.remove(&file_path);
                        }
                    }
                }
            }
        }
        
        Ok(())
    }
    
    async fn get_changed_files(&self, since: Option<DateTime<Utc>>) -> FileResult<Vec<FileItem>> {
        let file_cache = self.file_cache.lock().await;
        
        let files = match since {
            Some(timestamp) => {
                file_cache.values()
                    .filter(|file| file.modified_at > timestamp)
                    .cloned()
                    .collect()
            },
            None => file_cache.values().cloned().collect(),
        };
        
        Ok(files)
    }
    
    async fn get_files_by_sync_status(&self, status: SyncStatus) -> FileResult<Vec<FileItem>> {
        let file_cache = self.file_cache.lock().await;
        
        let files = file_cache.values()
            .filter(|file| file.sync_status == status)
            .cloned()
            .collect();
        
        Ok(files)
    }
    
    async fn get_file_from_path(&self, path: &Path) -> FileResult<Option<FileItem>> {
        // Try to resolve relative to sync directory
        let abs_path = if path.is_relative() {
            self.sync_dir.join(path)
        } else {
            path.to_path_buf()
        };
        
        // Check if path exists in cache
        let file_id = {
            let path_cache = self.path_cache.lock().await;
            path_cache.get(&abs_path).cloned()
        };
        
        if let Some(id) = file_id {
            let file_cache = self.file_cache.lock().await;
            return Ok(file_cache.get(&id).cloned());
        }
        
        // If not in cache, try to create a new entry if the file exists
        if abs_path.exists() {
            let rel_path = match abs_path.strip_prefix(&self.sync_dir) {
                Ok(p) => p,
                Err(_) => {
                    return Err(FileError::OperationError(
                        format!("Path not within sync directory: {:?}", path)
                    ));
                }
            };
            
            let metadata = match abs_path.metadata() {
                Ok(m) => m,
                Err(e) => {
                    return Err(FileError::IOError(
                        format!("Failed to read file metadata: {}", e)
                    ));
                }
            };
            
            let file_id = Uuid::new_v4().to_string();
            
            let name = abs_path.file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("unnamed")
                .to_string();
                
            let file_type = if abs_path.is_dir() {
                FileType::Directory
            } else {
                FileType::File
            };
            
            let mime_type = if abs_path.is_file() {
                mime_guess::from_path(&abs_path)
                    .first_or_octet_stream()
                    .to_string()
            } else {
                "application/directory".to_string()
            };
            
            let parent_id = if let Some(parent) = abs_path.parent() {
                if parent != &self.sync_dir {
                    let path_cache = self.path_cache.lock().await;
                    path_cache.get(&parent.to_path_buf()).cloned()
                } else {
                    None
                }
            } else {
                None
            };
            
            let file_item = FileItem {
                id: file_id.clone(),
                name,
                path: rel_path.to_string_lossy().to_string(),
                file_type,
                size: if abs_path.is_file() { metadata.len() } else { 0 },
                mime_type: Some(mime_type),
                parent_id,
                created_at: DateTime::<Utc>::from(metadata.created().unwrap_or_else(|_| std::time::SystemTime::now())),
                modified_at: DateTime::<Utc>::from(metadata.modified().unwrap_or_else(|_| std::time::SystemTime::now())),
                sync_status: SyncStatus::PendingUpload,
                is_favorite: false,
                local_path: Some(abs_path.to_string_lossy().to_string()),
            };
            
            // Update cache
            {
                let mut file_cache = self.file_cache.lock().await;
                file_cache.insert(file_id.clone(), file_item.clone());
                
                let mut path_cache = self.path_cache.lock().await;
                path_cache.insert(abs_path, file_id);
            }
            
            return Ok(Some(file_item));
        }
        
        Ok(None)
    }
    
    async fn download_file_to_path(&self, file_id: &str, local_path: &Path) -> FileResult<()> {
        let file = self.get_file_by_id(file_id).await?;
        
        // If file is already at the target path, no need to copy
        if let Some(current_path) = &file.local_path {
            if Path::new(current_path) == local_path {
                return Ok(());
            }
        }
        
        // Get file content
        let content = self.get_file_content(file_id).await?;
        
        // Create parent directories if needed
        if let Some(parent) = local_path.parent() {
            fs::create_dir_all(parent)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to create directory: {}", e)))?;
        }
        
        // Write file
        let mut file_handle = File::create(local_path)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to create file: {}", e)))?;
            
        file_handle.write_all(&content)
            .await
            .map_err(|e| FileError::IOError(format!("Failed to write file: {}", e)))?;
            
        Ok(())
    }
    
    async fn upload_file_from_path(&self, local_path: &Path, parent_id: Option<&str>) -> FileResult<FileItem> {
        // Check if file exists
        if !local_path.exists() {
            return Err(FileError::OperationError(
                format!("File not found: {:?}", local_path)
            ));
        }
        
        // Check if it's already in our cache
        if let Ok(Some(existing_file)) = self.get_file_from_path(local_path).await {
            return Ok(existing_file);
        }
        
        // Read metadata
        let metadata = local_path.metadata()
            .map_err(|e| FileError::IOError(format!("Failed to read file metadata: {}", e)))?;
            
        // Determine target path within sync directory
        let target_path = if let Some(parent) = parent_id {
            let parent_file = self.get_file_by_id(parent).await?;
            
            let parent_path = match &parent_file.local_path {
                Some(p) => PathBuf::from(p),
                None => {
                    return Err(FileError::OperationError(
                        format!("No local path for parent folder: {}", parent)
                    ));
                }
            };
            
            let filename = local_path.file_name().ok_or_else(|| {
                FileError::OperationError("Invalid file path".to_string())
            })?;
            
            parent_path.join(filename)
        } else {
            let filename = local_path.file_name().ok_or_else(|| {
                FileError::OperationError("Invalid file path".to_string())
            })?;
            
            self.sync_dir.join(filename)
        };
        
        // Create parent directories if needed
        if let Some(parent) = target_path.parent() {
            fs::create_dir_all(parent)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to create directory: {}", e)))?;
        }
        
        // If the file is not already in the target location, copy it
        if local_path != target_path {
            fs::copy(local_path, &target_path)
                .await
                .map_err(|e| FileError::IOError(format!("Failed to copy file: {}", e)))?;
        }
        
        // Create file item
        let file_id = Uuid::new_v4().to_string();
        let name = target_path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("unnamed")
            .to_string();
            
        let rel_path = target_path.strip_prefix(&self.sync_dir)
            .unwrap_or(&target_path)
            .to_string_lossy()
            .to_string();
            
        let mime_type = if target_path.is_file() {
            mime_guess::from_path(&target_path)
                .first_or_octet_stream()
                .to_string()
        } else {
            "application/directory".to_string()
        };
        
        let file_item = FileItem {
            id: file_id.clone(),
            name,
            path: rel_path,
            file_type: if target_path.is_dir() { FileType::Directory } else { FileType::File },
            size: if target_path.is_file() { metadata.len() } else { 0 },
            mime_type: Some(mime_type),
            parent_id: parent_id.map(String::from),
            created_at: DateTime::<Utc>::from(metadata.created().unwrap_or_else(|_| std::time::SystemTime::now())),
            modified_at: DateTime::<Utc>::from(metadata.modified().unwrap_or_else(|_| std::time::SystemTime::now())),
            sync_status: SyncStatus::PendingUpload,
            is_favorite: false,
            local_path: Some(target_path.to_string_lossy().to_string()),
        };
        
        // Update cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.insert(file_id.clone(), file_item.clone());
            
            let mut path_cache = self.path_cache.lock().await;
            path_cache.insert(target_path, file_id);
        }
        
        Ok(file_item)
    }
    
    async fn get_favorites(&self) -> FileResult<Vec<FileItem>> {
        let file_cache = self.file_cache.lock().await;
        
        let files = file_cache.values()
            .filter(|file| file.is_favorite)
            .cloned()
            .collect();
        
        Ok(files)
    }
    
    async fn set_favorite(&self, file_id: &str, is_favorite: bool) -> FileResult<FileItem> {
        let mut file = self.get_file_by_id(file_id).await?;
        
        // Update favorite status
        file.is_favorite = is_favorite;
        
        // Update cache
        {
            let mut file_cache = self.file_cache.lock().await;
            file_cache.insert(file_id.to_string(), file.clone());
        }
        
        Ok(file)
    }
}

/// Factory for creating FileSystemAdapter instances
pub struct FileSystemAdapterFactory {
    auth_repository: Arc<dyn AuthRepository>,
}

impl FileSystemAdapterFactory {
    pub fn new(auth_repository: Arc<dyn AuthRepository>) -> Self {
        Self { auth_repository }
    }
}

impl crate::domain::repositories::file_repository::FileRepositoryFactory for FileSystemAdapterFactory {
    fn create_repository(&self) -> Arc<dyn FileRepository> {
        let adapter = tokio::runtime::Handle::current().block_on(async {
            FileSystemAdapter::new(self.auth_repository.clone()).await
                .expect("Failed to create file system adapter")
        });
        
        // Start watching for file changes
        let mut adapter_clone = adapter.clone();
        tokio::spawn(async move {
            if let Err(e) = adapter_clone.start_watching().await {
                error!("Failed to start file watcher: {}", e);
            }
        });
        
        Arc::new(adapter)
    }
}