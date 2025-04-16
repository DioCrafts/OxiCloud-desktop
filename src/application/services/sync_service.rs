use async_trait::async_trait;
use std::sync::Arc;
use tokio::sync::broadcast;

use crate::application::dtos::file_dto::FileDto;
use crate::application::dtos::sync_dto::{SyncConfigDto, SyncDirectionDto, SyncEventDto, SyncStatusDto, SyncStateDto};
use crate::application::ports::sync_port::{SyncPort, SyncResult};
use crate::domain::entities::sync::{SyncConfig, SyncDirection, SyncEvent, SyncState, SyncError};
use crate::domain::services::sync_service::SyncService;

pub struct SyncApplicationService {
    sync_service: Arc<dyn SyncService>,
    event_broadcaster: broadcast::Sender<SyncEventDto>,
}

impl SyncApplicationService {
    pub fn new(sync_service: Arc<dyn SyncService>) -> Self {
        let (event_broadcaster, _) = broadcast::channel(100);
        
        // Start listening to domain events and forward them to application layer
        let domain_receiver = sync_service.subscribe_to_events();
        let broadcaster = event_broadcaster.clone();
        
        tokio::spawn(async move {
            Self::forward_domain_events(domain_receiver, broadcaster).await;
        });
        
        Self {
            sync_service,
            event_broadcaster,
        }
    }
    
    // Map domain status to DTO
    fn map_sync_status(status: crate::domain::entities::sync::SyncStatus) -> SyncStatusDto {
        SyncStatusDto {
            state: match status.state {
                SyncState::Idle => SyncStateDto::Idle,
                SyncState::Syncing => SyncStateDto::Syncing,
                SyncState::Paused => SyncStateDto::Paused,
                SyncState::Error(_) => SyncStateDto::Error,
                SyncState::Stopped => SyncStateDto::Idle,
            },
            last_sync: status.last_sync,
            current_operation: status.current_operation,
            current_file: status.current_file,
            total_files: status.total_files,
            processed_files: status.processed_files,
            total_bytes: status.total_bytes,
            processed_bytes: status.processed_bytes,
            error_message: status.error_message,
        }
    }
    
    // Map domain config to DTO
    fn map_sync_config(config: SyncConfig) -> SyncConfigDto {
        SyncConfigDto {
            enabled: config.enabled,
            sync_interval_seconds: config.sync_interval.as_secs(),
            sync_on_startup: config.sync_on_startup,
            sync_on_file_change: config.sync_on_file_change,
            sync_direction: match config.sync_direction {
                SyncDirection::Upload => SyncDirectionDto::Upload,
                SyncDirection::Download => SyncDirectionDto::Download,
                SyncDirection::Bidirectional => SyncDirectionDto::Bidirectional,
            },
            excluded_paths: config.excluded_paths,
            max_concurrent_transfers: config.max_concurrent_transfers,
            bandwidth_limit_kbps: config.bandwidth_limit_kbps,
            sync_hidden_files: config.sync_hidden_files,
            auto_resolve_conflicts: config.auto_resolve_conflicts,
        }
    }
    
    // Forward domain events to application layer
    async fn forward_domain_events(
        mut domain_receiver: broadcast::Receiver<crate::domain::services::sync_service::SyncEvent>,
        app_broadcaster: broadcast::Sender<SyncEventDto>,
    ) {
        while let Ok(event) = domain_receiver.recv().await {
            let app_event = match event {
                crate::domain::services::sync_service::SyncEvent::Started => {
                    SyncEventDto::Started
                },
                crate::domain::services::sync_service::SyncEvent::Progress(status) => {
                    // Map domain status to DTO
                    SyncEventDto::Progress(Self::map_sync_status(status))
                },
                crate::domain::services::sync_service::SyncEvent::Completed => {
                    SyncEventDto::Completed
                },
                crate::domain::services::sync_service::SyncEvent::Paused => {
                    SyncEventDto::Paused
                },
                crate::domain::services::sync_service::SyncEvent::Resumed => {
                    SyncEventDto::Resumed
                },
                crate::domain::services::sync_service::SyncEvent::Cancelled => {
                    SyncEventDto::Cancelled
                },
                crate::domain::services::sync_service::SyncEvent::Error(msg) => {
                    SyncEventDto::Error(msg)
                },
                crate::domain::services::sync_service::SyncEvent::FileChanged(file) => {
                    // In a complete implementation we would map the file to a DTO
                    // For simplicity, just send a generic event
                    SyncEventDto::Progress(SyncStatusDto {
                        state: SyncStateDto::Syncing,
                        last_sync: None,
                        current_operation: Some("Processing file changes".to_string()),
                        current_file: Some(file.name.clone()),
                        total_files: 0,
                        processed_files: 0,
                        total_bytes: 0,
                        processed_bytes: 0,
                        error_message: None,
                    })
                },
                crate::domain::services::sync_service::SyncEvent::EncryptionStarted(path) => {
                    SyncEventDto::EncryptionStarted(path)
                },
                crate::domain::services::sync_service::SyncEvent::EncryptionCompleted(path) => {
                    SyncEventDto::EncryptionCompleted(path)
                },
                crate::domain::services::sync_service::SyncEvent::DecryptionStarted(path) => {
                    SyncEventDto::DecryptionStarted(path)
                },
                crate::domain::services::sync_service::SyncEvent::DecryptionCompleted(path) => {
                    SyncEventDto::DecryptionCompleted(path)
                },
                crate::domain::services::sync_service::SyncEvent::EncryptionError(msg) => {
                    SyncEventDto::EncryptionError(msg)
                },
            };
            
            // Send the event - ignoring errors (no subscribers)
            let _ = app_broadcaster.send(app_event);
        }
    }
}

#[async_trait]
impl SyncPort for SyncApplicationService {
    async fn start_sync(&self) -> SyncResult<()> {
        self.sync_service.start_sync().await
    }
    
    async fn pause_sync(&self) -> SyncResult<()> {
        self.sync_service.pause_sync().await
    }
    
    async fn resume_sync(&self) -> SyncResult<()> {
        self.sync_service.resume_sync().await
    }
    
    async fn cancel_sync(&self) -> SyncResult<()> {
        self.sync_service.cancel_sync().await
    }
    
    async fn set_encryption_password(&self, password: Option<String>) -> SyncResult<()> {
        match self.sync_service.as_any().downcast_ref::<crate::domain::services::sync_service::SyncServiceImpl>() {
            Some(sync_service_impl) => {
                sync_service_impl.set_encryption_password(password).await;
                Ok(())
            },
            None => Err(SyncError::OperationError("Unable to set encryption password: service implementation mismatch".to_string()))
        }
    }
    
    async fn get_sync_status(&self) -> SyncResult<SyncStatusDto> {
        // This is a bit hacky since our domains differ from the ports in this example,
        // but in a full implementation we'd map from domain SyncStatus to SyncStatusDto
        
        // In a real implementation, we would:
        // 1. Get the domain status from the service
        // 2. Map it to the application DTO
        // For this MVP, we'll return a placeholder status
        Ok(SyncStatusDto {
            state: SyncStateDto::Idle,
            last_sync: None,
            current_operation: None,
            current_file: None,
            total_files: 0,
            processed_files: 0,
            total_bytes: 0,
            processed_bytes: 0,
            error_message: None,
        })
    }
    
    async fn subscribe_to_events(&self) -> broadcast::Receiver<SyncEventDto> {
        self.event_broadcaster.subscribe()
    }
    
    async fn get_sync_config(&self) -> SyncResult<SyncConfigDto> {
        // Same as with status, in a full implementation we'd:
        // 1. Get the domain config from the service
        // 2. Map it to the application DTO
        // For now, return a default config
        Ok(SyncConfigDto {
            enabled: true,
            sync_interval_seconds: 300, // 5 minutes
            sync_on_startup: true,
            sync_on_file_change: true,
            sync_direction: SyncDirectionDto::Bidirectional,
            excluded_paths: vec![
                ".git".to_string(),
                ".DS_Store".to_string(),
            ],
            max_concurrent_transfers: 3,
            bandwidth_limit_kbps: None,
            sync_hidden_files: false,
            auto_resolve_conflicts: false,
        })
    }
    
    async fn update_sync_config(&self, config: SyncConfigDto) -> SyncResult<()> {
        // In a full implementation, we'd:
        // 1. Map the DTO to a domain config
        // 2. Pass it to the service
        // For this MVP, we'll just set the sync interval
        self.sync_service.set_sync_interval(config.sync_interval_seconds).await
    }
    
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>> {
        // In a full implementation, get them from the service
        Ok(vec![])
    }
    
    async fn set_excluded_items(&self, _paths: Vec<String>) -> SyncResult<()> {
        // In a full implementation, pass to the service
        Ok(())
    }
    
    async fn get_conflict_items(&self) -> SyncResult<Vec<FileDto>> {
        // In a full implementation, get from service and map to DTOs
        Ok(vec![])
    }
    
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileDto> {
        // Map keep_local flag to SyncDirection
        let direction = if keep_local {
            SyncDirection::Upload
        } else {
            SyncDirection::Download
        };
        
        // Resolve the conflict in the domain
        let _ = self.sync_service.resolve_conflict(file_id, direction).await?;
        
        // Return a placeholder for now
        // In a full implementation, we'd map the updated file to a DTO
        Err(crate::domain::entities::sync::SyncError::SyncError(
            "Not fully implemented in MVP".to_string()
        ))
    }
}