use async_trait::async_trait;
use std::sync::Arc;
use tokio::sync::broadcast;

use crate::application::dtos::sync_dto::{SyncStatusDto, SyncConfigDto, SyncEventDto};
use crate::application::dtos::file_dto::FileDto;
use crate::domain::entities::sync::SyncError;

pub type SyncResult<T> = Result<T, SyncError>;

#[async_trait]
pub trait SyncPort: Send + Sync + 'static {
    // Sync control
    async fn start_sync(&self) -> SyncResult<()>;
    async fn pause_sync(&self) -> SyncResult<()>;
    async fn resume_sync(&self) -> SyncResult<()>;
    async fn cancel_sync(&self) -> SyncResult<()>;
    
    // Sync status and events
    async fn get_sync_status(&self) -> SyncResult<SyncStatusDto>;
    async fn subscribe_to_events(&self) -> broadcast::Receiver<SyncEventDto>;
    
    // Configuration
    async fn get_sync_config(&self) -> SyncResult<SyncConfigDto>;
    async fn update_sync_config(&self, config: SyncConfigDto) -> SyncResult<()>;
    
    // Selective sync
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>>;
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()>;
    
    // Conflicts
    async fn get_conflict_items(&self) -> SyncResult<Vec<FileDto>>;
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileDto>;
}
