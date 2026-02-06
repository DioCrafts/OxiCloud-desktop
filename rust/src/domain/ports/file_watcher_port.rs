//! # File Watcher Port
//!
//! Port interface for file system monitoring.

use async_trait::async_trait;
use std::path::PathBuf;

/// Result type for watcher operations
pub type WatcherResult<T> = Result<T, WatcherError>;

/// File watcher errors
#[derive(Debug, thiserror::Error)]
pub enum WatcherError {
    #[error("Watch failed: {0}")]
    WatchFailed(String),
    
    #[error("Path not found: {0}")]
    PathNotFound(String),
    
    #[error("Permission denied: {0}")]
    PermissionDenied(String),
    
    #[error("Internal error: {0}")]
    InternalError(String),
}

/// File system event type
#[derive(Debug, Clone, PartialEq)]
pub enum FileEventType {
    /// File or folder created
    Created,
    /// File or folder modified
    Modified,
    /// File or folder deleted
    Deleted,
    /// File or folder renamed/moved
    Renamed { from: PathBuf, to: PathBuf },
}

/// File system event
#[derive(Debug, Clone)]
pub struct FileEvent {
    /// Event type
    pub event_type: FileEventType,
    
    /// Path affected
    pub path: PathBuf,
    
    /// Whether it's a directory
    pub is_directory: bool,
    
    /// Timestamp of the event
    pub timestamp: chrono::DateTime<chrono::Utc>,
}

impl FileEvent {
    /// Create a new file event
    pub fn new(event_type: FileEventType, path: PathBuf, is_directory: bool) -> Self {
        Self {
            event_type,
            path,
            is_directory,
            timestamp: chrono::Utc::now(),
        }
    }
}

/// Callback type for file events
pub type FileEventCallback = Box<dyn Fn(FileEvent) + Send + Sync>;

/// Port interface for file system watching
#[async_trait]
pub trait FileWatcherPort: Send + Sync {
    /// Start watching a directory (recursively)
    async fn watch(&self, path: &PathBuf) -> WatcherResult<()>;
    
    /// Stop watching a directory
    async fn unwatch(&self, path: &PathBuf) -> WatcherResult<()>;
    
    /// Stop all watches
    async fn unwatch_all(&self) -> WatcherResult<()>;
    
    /// Set the event callback
    fn set_callback(&self, callback: FileEventCallback);
    
    /// Get list of watched paths
    fn get_watched_paths(&self) -> Vec<PathBuf>;
    
    /// Check if a path is being watched
    fn is_watching(&self, path: &PathBuf) -> bool;
    
    /// Pause watching (temporarily stop events)
    fn pause(&self);
    
    /// Resume watching
    fn resume(&self);
    
    /// Check if watcher is paused
    fn is_paused(&self) -> bool;
}
