//! # File Watcher
//!
//! File system watcher implementation using notify crate.

use std::path::PathBuf;
use std::sync::{Arc, atomic::{AtomicBool, Ordering}};
use async_trait::async_trait;
use notify::{Watcher, RecursiveMode, Event as NotifyEvent, EventKind};
use tokio::sync::RwLock;
use chrono::Utc;

use crate::domain::ports::{
    FileWatcherPort, FileEvent, FileEventType, FileEventCallback,
    WatcherResult, WatcherError,
};

/// File watcher implementation using notify
pub struct NotifyFileWatcher {
    watcher: RwLock<Option<notify::RecommendedWatcher>>,
    callback: Arc<RwLock<Option<FileEventCallback>>>,
    watched_paths: RwLock<Vec<PathBuf>>,
    paused: Arc<AtomicBool>,
}

impl NotifyFileWatcher {
    /// Create a new file watcher
    pub fn new() -> WatcherResult<Self> {
        Ok(Self {
            watcher: RwLock::new(None),
            callback: Arc::new(RwLock::new(None)),
            watched_paths: RwLock::new(Vec::new()),
            paused: Arc::new(AtomicBool::new(false)),
        })
    }
    
    /// Convert notify event to our file event
    fn convert_event(&self, event: NotifyEvent) -> Option<FileEvent> {
        if self.paused.load(Ordering::Relaxed) {
            return None;
        }
        
        let path = event.paths.first()?.clone();
        let is_directory = path.is_dir();
        
        let event_type = match event.kind {
            EventKind::Create(_) => FileEventType::Created,
            EventKind::Modify(_) => FileEventType::Modified,
            EventKind::Remove(_) => FileEventType::Deleted,
            EventKind::Any => return None,
            EventKind::Access(_) => return None, // Ignore access events
            EventKind::Other => return None,
        };
        
        Some(FileEvent {
            event_type,
            path,
            is_directory,
            timestamp: Utc::now(),
        })
    }
}

#[async_trait]
impl FileWatcherPort for NotifyFileWatcher {
    async fn watch(&self, path: &PathBuf) -> WatcherResult<()> {
        if !path.exists() {
            return Err(WatcherError::PathNotFound(path.to_string_lossy().to_string()));
        }
        
        // Create callback reference
        let callback = self.callback.clone();
        let paused = self.paused.clone();
        
        // Create the watcher with event handler
        let mut watcher = notify::recommended_watcher(move |res: Result<NotifyEvent, notify::Error>| {
            if paused.load(Ordering::Relaxed) {
                return;
            }
            
            if let Ok(event) = res {
                let path = match event.paths.first() {
                    Some(p) => p.clone(),
                    None => return,
                };
                
                let is_directory = path.is_dir();
                
                let event_type = match event.kind {
                    EventKind::Create(_) => FileEventType::Created,
                    EventKind::Modify(_) => FileEventType::Modified,
                    EventKind::Remove(_) => FileEventType::Deleted,
                    _ => return,
                };
                
                let file_event = FileEvent {
                    event_type,
                    path,
                    is_directory,
                    timestamp: Utc::now(),
                };
                
                // Can't await here, so we use blocking read
                // In production, use a channel to send events
                let callback_guard = callback.blocking_read();
                if let Some(ref cb) = *callback_guard {
                    cb(file_event);
                }
            }
        }).map_err(|e| WatcherError::WatchFailed(e.to_string()))?;
        
        // Watch the path recursively
        watcher.watch(path, RecursiveMode::Recursive)
            .map_err(|e| WatcherError::WatchFailed(e.to_string()))?;
        
        // Store watcher and path
        *self.watcher.write().await = Some(watcher);
        self.watched_paths.write().await.push(path.clone());
        
        tracing::info!("Started watching: {:?}", path);
        Ok(())
    }
    
    async fn unwatch(&self, path: &PathBuf) -> WatcherResult<()> {
        let mut watcher_guard = self.watcher.write().await;
        
        if let Some(ref mut watcher) = *watcher_guard {
            watcher.unwatch(path)
                .map_err(|e| WatcherError::WatchFailed(e.to_string()))?;
        }
        
        // Remove from watched paths
        let mut paths = self.watched_paths.write().await;
        paths.retain(|p| p != path);
        
        tracing::info!("Stopped watching: {:?}", path);
        Ok(())
    }
    
    async fn unwatch_all(&self) -> WatcherResult<()> {
        let paths: Vec<PathBuf> = self.watched_paths.read().await.clone();
        
        for path in paths {
            self.unwatch(&path).await?;
        }
        
        // Clear the watcher
        *self.watcher.write().await = None;
        
        tracing::info!("Stopped all file watching");
        Ok(())
    }
    
    fn set_callback(&self, callback: FileEventCallback) {
        // Use blocking write since this is called from non-async context
        let mut guard = self.callback.blocking_write();
        *guard = Some(callback);
    }
    
    fn get_watched_paths(&self) -> Vec<PathBuf> {
        self.watched_paths.blocking_read().clone()
    }
    
    fn is_watching(&self, path: &PathBuf) -> bool {
        self.watched_paths.blocking_read().contains(path)
    }
    
    fn pause(&self) {
        self.paused.store(true, Ordering::Relaxed);
        tracing::debug!("File watcher paused");
    }
    
    fn resume(&self) {
        self.paused.store(false, Ordering::Relaxed);
        tracing::debug!("File watcher resumed");
    }
    
    fn is_paused(&self) -> bool {
        self.paused.load(Ordering::Relaxed)
    }
}

impl Default for NotifyFileWatcher {
    fn default() -> Self {
        Self::new().expect("Failed to create file watcher")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    use std::fs::File;
    use std::io::Write;
    
    #[tokio::test]
    async fn test_file_watcher() {
        let watcher = NotifyFileWatcher::new().unwrap();
        let dir = tempdir().unwrap();
        
        // Setup callback
        let events = Arc::new(RwLock::new(Vec::<FileEvent>::new()));
        let events_clone = events.clone();
        
        watcher.set_callback(Box::new(move |event| {
            let events = events_clone.clone();
            tokio::spawn(async move {
                events.write().await.push(event);
            });
        }));
        
        // Start watching
        watcher.watch(&dir.path().to_path_buf()).await.unwrap();
        
        // Create a file
        let file_path = dir.path().join("test.txt");
        let mut file = File::create(&file_path).unwrap();
        file.write_all(b"test").unwrap();
        
        // Wait for events
        tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
        
        // Check events were captured
        let captured = events.read().await;
        assert!(!captured.is_empty());
    }
}
