use async_trait::async_trait;
use std::sync::Arc;

use crate::domain::entities::sync::{SyncConfig, SyncStatus, SyncResult};
use crate::domain::entities::file::FileItem;

#[async_trait]
pub trait SyncRepository: Send + Sync + 'static {
    // Sync configuration operations
    async fn get_sync_config(&self) -> SyncResult<SyncConfig>;
    async fn save_sync_config(&self, config: &SyncConfig) -> SyncResult<()>;
    
    // Sync state operations
    async fn get_sync_status(&self) -> SyncResult<SyncStatus>;
    async fn update_sync_status(&self, status: &SyncStatus) -> SyncResult<()>;
    
    // Sync operations
    async fn start_sync(&self) -> SyncResult<()>;
    async fn pause_sync(&self) -> SyncResult<()>;
    async fn resume_sync(&self) -> SyncResult<()>;
    async fn cancel_sync(&self) -> SyncResult<()>;
    
    // Selective sync operations
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>>;
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()>;
    
    // Delta sync operations
    async fn get_last_sync_time(&self) -> SyncResult<Option<chrono::DateTime<chrono::Utc>>>;
    async fn set_last_sync_time(&self, time: chrono::DateTime<chrono::Utc>) -> SyncResult<()>;
    
    // Conflict resolution
    async fn get_conflicts(&self) -> SyncResult<Vec<FileItem>>;
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileItem>;
}

pub trait SyncRepositoryFactory: Send + Sync + 'static {
    fn create_repository(&self) -> Arc<dyn SyncRepository>;
}
