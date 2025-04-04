use async_trait::async_trait;
use std::sync::Arc;
use tokio::sync::broadcast;

use crate::domain::entities::sync::{SyncConfig, SyncDirection, SyncResult, SyncState, SyncStatus};
use crate::domain::entities::file::{FileItem, SyncStatus as FileSyncStatus};
use crate::domain::repositories::sync_repository::SyncRepository;
use crate::domain::repositories::file_repository::FileRepository;

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
}

#[async_trait]
pub trait SyncService: Send + Sync + 'static {
    // Sync control
    async fn start_sync(&self) -> SyncResult<()>;
    async fn pause_sync(&self) -> SyncResult<()>;
    async fn resume_sync(&self) -> SyncResult<()>;
    async fn cancel_sync(&self) -> SyncResult<()>;
    
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
    event_sender: broadcast::Sender<SyncEvent>,
}

impl SyncServiceImpl {
    pub fn new(
        sync_repository: Arc<dyn SyncRepository>,
        file_repository: Arc<dyn FileRepository>,
    ) -> Self {
        let (event_sender, _) = broadcast::channel(100);
        Self {
            sync_repository,
            file_repository,
            event_sender,
        }
    }
    
    // Helper to broadcast events
    async fn broadcast_event(&self, event: SyncEvent) {
        let _ = self.event_sender.send(event);
    }
}

#[async_trait]
impl SyncService for SyncServiceImpl {
    async fn start_sync(&self) -> SyncResult<()> {
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
