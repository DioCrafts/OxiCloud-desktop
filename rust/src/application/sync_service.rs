//! # Sync Service
//!
//! Main synchronization service that orchestrates file sync operations.

use std::sync::Arc;
use std::collections::HashMap;
use tokio::sync::{RwLock, mpsc, Mutex};
use tokio::time::{interval, Duration};
use chrono::Utc;

use crate::domain::entities::{
    SyncItem, SyncStatus, SyncDirection, SyncConfig, ConflictResolution,
    ConflictInfo, ConflictType, EngineStatus, SyncStats, SyncProgress,
};
use crate::domain::ports::{
    SyncPort, SyncResult, SyncError, RemoteItem,
    StoragePort, StorageResult,
    FileWatcherPort, FileEvent, FileEventType,
};
use crate::api::{SyncResult as ApiSyncResult, SyncStatusInfo, SyncHistoryEntry, RemoteFolder, SyncConflict};

/// Main sync service
pub struct SyncService {
    storage: Arc<dyn StoragePort>,
    remote: Arc<dyn SyncPort>,
    watcher: Arc<dyn FileWatcherPort>,
    config: Arc<RwLock<SyncConfig>>,
    
    status: Arc<RwLock<EngineStatus>>,
    stats: Arc<RwLock<SyncStats>>,
    progress: Arc<RwLock<Option<SyncProgress>>>,
    
    /// Channel to stop the sync loop
    stop_tx: Arc<Mutex<Option<mpsc::Sender<()>>>>,
    
    /// Sync in progress lock
    sync_lock: Arc<Mutex<()>>,
}

impl SyncService {
    /// Create a new sync service
    pub fn new(
        storage: Arc<dyn StoragePort>,
        remote: Arc<dyn SyncPort>,
        watcher: Arc<dyn FileWatcherPort>,
        config: SyncConfig,
    ) -> Self {
        Self {
            storage,
            remote,
            watcher,
            config: Arc::new(RwLock::new(config)),
            status: Arc::new(RwLock::new(EngineStatus::Idle)),
            stats: Arc::new(RwLock::new(SyncStats::default())),
            progress: Arc::new(RwLock::new(None)),
            stop_tx: Arc::new(Mutex::new(None)),
            sync_lock: Arc::new(Mutex::new(())),
        }
    }
    
    /// Start automatic synchronization
    pub async fn start(&self) -> Result<(), String> {
        let config = self.config.read().await;
        
        if config.sync_interval_seconds == 0 {
            return Err("Sync interval is 0, automatic sync disabled".to_string());
        }
        
        // Setup file watcher if enabled
        if config.watch_filesystem {
            let sync_folder = std::path::PathBuf::from(&config.sync_folder);
            self.watcher.watch(&sync_folder).await
                .map_err(|e| format!("Failed to start file watcher: {}", e))?;
            
            // Setup watcher callback
            let storage = self.storage.clone();
            let status = self.status.clone();
            self.watcher.set_callback(Box::new(move |event| {
                // Handle file events - queue for sync
                let storage = storage.clone();
                let status = status.clone();
                tokio::spawn(async move {
                    Self::handle_file_event(event, storage, status).await;
                });
            }));
        }
        
        // Start sync loop
        let (stop_tx, mut stop_rx) = mpsc::channel::<()>(1);
        *self.stop_tx.lock().await = Some(stop_tx);
        
        let interval_secs = config.sync_interval_seconds;
        drop(config);
        
        let service = SyncServiceRef {
            storage: self.storage.clone(),
            remote: self.remote.clone(),
            config: self.config.clone(),
            status: self.status.clone(),
            stats: self.stats.clone(),
            progress: self.progress.clone(),
            sync_lock: self.sync_lock.clone(),
        };
        
        tokio::spawn(async move {
            let mut ticker = interval(Duration::from_secs(interval_secs as u64));
            
            loop {
                tokio::select! {
                    _ = ticker.tick() => {
                        tracing::info!("Running scheduled sync");
                        if let Err(e) = service.do_sync().await {
                            tracing::error!("Scheduled sync failed: {}", e);
                        }
                    }
                    _ = stop_rx.recv() => {
                        tracing::info!("Sync loop stopped");
                        break;
                    }
                }
            }
        });
        
        *self.status.write().await = EngineStatus::Idle;
        tracing::info!("Automatic sync started with interval: {}s", interval_secs);
        
        Ok(())
    }
    
    /// Stop automatic synchronization
    pub async fn stop(&self) {
        if let Some(tx) = self.stop_tx.lock().await.take() {
            let _ = tx.send(()).await;
        }
        
        self.watcher.unwatch_all().await.ok();
        *self.status.write().await = EngineStatus::Paused;
        
        tracing::info!("Sync service stopped");
    }
    
    /// Trigger immediate sync
    pub async fn sync_now(&self) -> Result<ApiSyncResult, String> {
        let _lock = self.sync_lock.lock().await;
        
        *self.status.write().await = EngineStatus::Syncing;
        let start = std::time::Instant::now();
        
        let result = self.do_full_sync().await;
        
        let duration_ms = start.elapsed().as_millis() as u64;
        *self.status.write().await = EngineStatus::Idle;
        
        match result {
            Ok((uploaded, downloaded, conflicts, errors)) => {
                Ok(ApiSyncResult {
                    success: errors.is_empty(),
                    items_uploaded: uploaded,
                    items_downloaded: downloaded,
                    items_deleted: 0,
                    conflicts,
                    errors,
                    duration_ms,
                })
            }
            Err(e) => Err(e)
        }
    }
    
    /// Perform full synchronization
    async fn do_full_sync(&self) -> Result<(u32, u32, u32, Vec<String>), String> {
        let config = self.config.read().await;
        let mut uploaded = 0u32;
        let mut downloaded = 0u32;
        let mut conflicts = 0u32;
        let mut errors = Vec::new();
        
        // 1. Get local state
        let local_items = self.storage.get_pending_items().await
            .map_err(|e| format!("Failed to get pending items: {}", e))?;
        
        // 2. Get remote state
        let remote_items = self.remote.list_directory("/").await
            .map_err(|e| format!("Failed to list remote: {}", e))?;
        
        // 3. Compare and sync
        for item in local_items {
            match item.direction {
                SyncDirection::Upload => {
                    match self.upload_item(&item).await {
                        Ok(_) => uploaded += 1,
                        Err(e) => errors.push(format!("{}: {}", item.path, e)),
                    }
                }
                SyncDirection::Download => {
                    match self.download_item(&item).await {
                        Ok(_) => downloaded += 1,
                        Err(e) => errors.push(format!("{}: {}", item.path, e)),
                    }
                }
                SyncDirection::None => {}
            }
        }
        
        // 4. Update stats
        let mut stats = self.stats.write().await;
        stats.last_sync = Some(Utc::now());
        stats.pending_uploads = 0;
        stats.pending_downloads = 0;
        
        Ok((uploaded, downloaded, conflicts, errors))
    }
    
    /// Upload a single item
    async fn upload_item(&self, item: &SyncItem) -> Result<(), String> {
        let config = self.config.read().await;
        let local_path = format!("{}/{}", config.sync_folder, item.path);
        
        self.storage.update_item_status(&item.path, SyncStatus::Syncing).await
            .map_err(|e| e.to_string())?;
        
        let etag = self.remote.upload(&local_path, &item.path, None).await
            .map_err(|e| e.to_string())?;
        
        let mut updated_item = item.clone();
        updated_item.status = SyncStatus::Synced;
        updated_item.etag = Some(etag);
        
        self.storage.save_item(&updated_item).await
            .map_err(|e| e.to_string())?;
        
        Ok(())
    }
    
    /// Download a single item
    async fn download_item(&self, item: &SyncItem) -> Result<(), String> {
        let config = self.config.read().await;
        let local_path = format!("{}/{}", config.sync_folder, item.path);
        
        self.storage.update_item_status(&item.path, SyncStatus::Syncing).await
            .map_err(|e| e.to_string())?;
        
        self.remote.download(&item.path, &local_path, None).await
            .map_err(|e| e.to_string())?;
        
        let mut updated_item = item.clone();
        updated_item.status = SyncStatus::Synced;
        
        self.storage.save_item(&updated_item).await
            .map_err(|e| e.to_string())?;
        
        Ok(())
    }
    
    /// Handle file system events
    async fn handle_file_event(
        event: FileEvent,
        storage: Arc<dyn StoragePort>,
        status: Arc<RwLock<EngineStatus>>,
    ) {
        tracing::debug!("File event: {:?}", event);
        
        let path = event.path.to_string_lossy().to_string();
        
        match event.event_type {
            FileEventType::Created | FileEventType::Modified => {
                // Queue for upload
                let item = SyncItem::from_local(
                    path.clone(),
                    event.path.file_name()
                        .map(|n| n.to_string_lossy().to_string())
                        .unwrap_or_default(),
                    event.is_directory,
                    0, // Size will be filled later
                    Utc::now(),
                    None,
                );
                
                if let Err(e) = storage.save_item(&item).await {
                    tracing::error!("Failed to queue item for sync: {}", e);
                }
            }
            FileEventType::Deleted => {
                // Mark for deletion on server
                if let Err(e) = storage.delete_item(&path).await {
                    tracing::error!("Failed to mark item for deletion: {}", e);
                }
            }
            FileEventType::Renamed { from, to } => {
                // Handle rename as delete + create
                let from_path = from.to_string_lossy().to_string();
                storage.delete_item(&from_path).await.ok();
            }
        }
    }
    
    /// Get current sync status
    pub async fn get_status(&self) -> SyncStatusInfo {
        let status = self.status.read().await;
        let stats = self.stats.read().await;
        let progress = self.progress.read().await;
        
        SyncStatusInfo {
            is_syncing: matches!(*status, EngineStatus::Syncing),
            current_operation: progress.as_ref().map(|p| p.operation.clone()),
            progress_percent: progress.as_ref().map(|p| p.percent()).unwrap_or(0.0),
            items_synced: progress.as_ref().map(|p| p.items_done).unwrap_or(0),
            items_total: progress.as_ref().map(|p| p.items_total).unwrap_or(0),
            last_sync_time: stats.last_sync.map(|t| t.timestamp()),
            next_sync_time: stats.next_sync.map(|t| t.timestamp()),
        }
    }
    
    /// Get pending items
    pub async fn get_pending_items(&self) -> Result<Vec<SyncItem>, String> {
        self.storage.get_pending_items().await
            .map_err(|e| e.to_string())
    }
    
    /// Get sync history
    pub async fn get_history(&self, limit: u32) -> Result<Vec<SyncHistoryEntry>, String> {
        let records = self.storage.get_sync_history(limit).await
            .map_err(|e| e.to_string())?;
        
        Ok(records.into_iter().map(|r| SyncHistoryEntry {
            id: r.id,
            timestamp: r.timestamp.timestamp(),
            operation: r.operation,
            item_path: r.item_path,
            direction: SyncDirection::Upload, // TODO: Store direction
            status: if r.success { SyncStatus::Synced } else { SyncStatus::Error(r.error_message.clone().unwrap_or_default()) },
            error_message: r.error_message,
        }).collect())
    }
    
    /// Get remote folders for selective sync
    pub async fn get_remote_folders(&self) -> Result<Vec<RemoteFolder>, String> {
        let items = self.remote.list_directory("/").await
            .map_err(|e| e.to_string())?;
        
        let selected = self.storage.load_sync_folders().await
            .unwrap_or_default();
        
        Ok(items.into_iter()
            .filter(|i| i.is_directory)
            .map(|i| RemoteFolder {
                id: i.id.clone(),
                name: i.name.clone(),
                path: i.path.clone(),
                size_bytes: i.size,
                item_count: 0, // TODO: Count items
                is_selected: selected.contains(&i.id),
            })
            .collect())
    }
    
    /// Set folders to sync
    pub async fn set_sync_folders(&self, folder_ids: Vec<String>) -> Result<(), String> {
        self.storage.save_sync_folders(&folder_ids).await
            .map_err(|e| e.to_string())
    }
    
    /// Get selected sync folders
    pub async fn get_sync_folders(&self) -> Vec<String> {
        self.storage.load_sync_folders().await.unwrap_or_default()
    }
    
    /// Get conflicts
    pub async fn get_conflicts(&self) -> Result<Vec<SyncConflict>, String> {
        let items = self.storage.get_conflicts().await
            .map_err(|e| e.to_string())?;
        
        Ok(items.into_iter().map(|i| {
            let conflict_type = match &i.status {
                SyncStatus::Conflict(info) => match info.conflict_type {
                    ConflictType::BothModified => crate::api::ConflictType::BothModified,
                    ConflictType::DeletedLocally => crate::api::ConflictType::DeletedLocally,
                    ConflictType::DeletedRemotely => crate::api::ConflictType::DeletedRemotely,
                    ConflictType::TypeMismatch => crate::api::ConflictType::TypeMismatch,
                },
                _ => crate::api::ConflictType::BothModified,
            };
            
            SyncConflict {
                id: i.id.clone(),
                item_path: i.path.clone(),
                local_modified: i.local_modified.map(|t| t.timestamp()).unwrap_or(0),
                remote_modified: i.remote_modified.map(|t| t.timestamp()).unwrap_or(0),
                local_size: i.size,
                remote_size: i.size, // TODO: Store remote size
                conflict_type,
            }
        }).collect())
    }
    
    /// Resolve a conflict
    pub async fn resolve_conflict(
        &self,
        conflict_id: &str,
        resolution: ConflictResolution,
    ) -> Result<(), String> {
        let item = self.storage.get_item_by_id(conflict_id).await
            .map_err(|e| e.to_string())?
            .ok_or_else(|| format!("Conflict not found: {}", conflict_id))?;
        
        match resolution {
            ConflictResolution::KeepLocal => {
                self.upload_item(&item).await?;
            }
            ConflictResolution::KeepRemote => {
                self.download_item(&item).await?;
            }
            ConflictResolution::KeepBoth => {
                // Rename local and download remote
                // TODO: Implement rename logic
                self.download_item(&item).await?;
            }
            ConflictResolution::Skip => {
                self.storage.update_item_status(&item.path, SyncStatus::Ignored).await
                    .map_err(|e| e.to_string())?;
            }
        }
        
        Ok(())
    }
    
    /// Update configuration
    pub async fn update_config(&self, config: SyncConfig) -> Result<(), String> {
        self.storage.save_config(&config).await
            .map_err(|e| e.to_string())?;
        
        *self.config.write().await = config;
        Ok(())
    }
}

/// Reference struct for spawned tasks
struct SyncServiceRef {
    storage: Arc<dyn StoragePort>,
    remote: Arc<dyn SyncPort>,
    config: Arc<RwLock<SyncConfig>>,
    status: Arc<RwLock<EngineStatus>>,
    stats: Arc<RwLock<SyncStats>>,
    progress: Arc<RwLock<Option<SyncProgress>>>,
    sync_lock: Arc<Mutex<()>>,
}

impl SyncServiceRef {
    async fn do_sync(&self) -> Result<(), String> {
        let _lock = self.sync_lock.lock().await;
        
        *self.status.write().await = EngineStatus::Syncing;
        
        // Simplified sync logic for scheduled runs
        let pending = self.storage.get_pending_items().await
            .map_err(|e| e.to_string())?;
        
        for item in pending {
            // Sync each item...
            tracing::debug!("Syncing: {}", item.path);
        }
        
        *self.status.write().await = EngineStatus::Idle;
        
        let mut stats = self.stats.write().await;
        stats.last_sync = Some(Utc::now());
        
        Ok(())
    }
}
