//! # File Watcher Service
//!
//! Service for monitoring file system changes.

use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::RwLock;

use crate::domain::ports::{FileWatcherPort, FileEvent, FileEventCallback, WatcherResult};

/// Wrapper service for file watcher with debouncing
pub struct FileWatcherService {
    watcher: Arc<dyn FileWatcherPort>,
    debounce_ms: u64,
    pending_events: Arc<RwLock<Vec<FileEvent>>>,
}

impl FileWatcherService {
    /// Create a new file watcher service
    pub fn new(watcher: Arc<dyn FileWatcherPort>, debounce_ms: u64) -> Self {
        Self {
            watcher,
            debounce_ms,
            pending_events: Arc::new(RwLock::new(Vec::new())),
        }
    }
    
    /// Start watching with debounced events
    pub async fn start(&self, path: &PathBuf, callback: FileEventCallback) -> WatcherResult<()> {
        let pending = self.pending_events.clone();
        let debounce_ms = self.debounce_ms;
        
        // Setup debouncing callback
        self.watcher.set_callback(Box::new(move |event| {
            let pending = pending.clone();
            tokio::spawn(async move {
                pending.write().await.push(event);
            });
        }));
        
        // Start watching
        self.watcher.watch(path).await?;
        
        // Start debounce processor
        let pending = self.pending_events.clone();
        tokio::spawn(async move {
            loop {
                tokio::time::sleep(tokio::time::Duration::from_millis(debounce_ms)).await;
                
                let events: Vec<FileEvent> = {
                    let mut pending = pending.write().await;
                    std::mem::take(&mut *pending)
                };
                
                // Deduplicate and process events
                let deduped = deduplicate_events(events);
                for event in deduped {
                    callback(event);
                }
            }
        });
        
        Ok(())
    }
    
    /// Stop watching
    pub async fn stop(&self) -> WatcherResult<()> {
        self.watcher.unwatch_all().await
    }
    
    /// Pause watching
    pub fn pause(&self) {
        self.watcher.pause();
    }
    
    /// Resume watching
    pub fn resume(&self) {
        self.watcher.resume();
    }
}

/// Deduplicate file events (keep only latest for each path)
fn deduplicate_events(events: Vec<FileEvent>) -> Vec<FileEvent> {
    use std::collections::HashMap;
    
    let mut by_path: HashMap<PathBuf, FileEvent> = HashMap::new();
    
    for event in events {
        by_path.insert(event.path.clone(), event);
    }
    
    by_path.into_values().collect()
}
