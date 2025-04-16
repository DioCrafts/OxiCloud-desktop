use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::{params, Result as SqliteResult, Row};
use std::sync::Arc;
use std::time::Duration;
use chrono::{DateTime, Utc};
use async_trait::async_trait;
use tokio::task;

use crate::domain::entities::sync::{
    SyncConfig, SyncStatus, SyncDirection, SyncState, SyncEvent, SyncEventType, SyncResult, SyncError
};
use crate::domain::repositories::sync_repository::{SyncRepository, SyncRepositoryFactory};

/// SQLite implementation of the SyncRepository
pub struct SqliteSyncRepository {
    pool: Pool<SqliteConnectionManager>,
}

impl SqliteSyncRepository {
    pub fn new(pool: Pool<SqliteConnectionManager>) -> Self {
        Self { pool }
    }
    
    /// Convert a row from the database to a SyncConfig
    fn row_to_sync_config(row: &Row) -> SqliteResult<SyncConfig> {
        let enabled: bool = row.get::<_, i64>(0)? != 0;
        let sync_interval_secs: i64 = row.get(1)?;
        let sync_on_startup: bool = row.get::<_, i64>(2)? != 0;
        let sync_on_file_change: bool = row.get::<_, i64>(3)? != 0;
        let sync_direction_str: String = row.get(4)?;
        let max_concurrent_transfers: i64 = row.get(5)?;
        let bandwidth_limit_kbps: Option<i64> = row.get(6)?;
        let sync_hidden_files: bool = row.get::<_, i64>(7)? != 0;
        let auto_resolve_conflicts: bool = row.get::<_, i64>(8)? != 0;
        
        let sync_direction = match sync_direction_str.as_str() {
            "Upload" => SyncDirection::Upload,
            "Download" => SyncDirection::Download,
            _ => SyncDirection::Bidirectional,
        };
        
        Ok(SyncConfig {
            enabled,
            sync_interval: Duration::from_secs(sync_interval_secs as u64),
            sync_on_startup,
            sync_on_file_change,
            sync_direction,
            excluded_paths: Vec::new(), // We'll load these separately
            max_concurrent_transfers: max_concurrent_transfers as u32,
            bandwidth_limit_kbps: bandwidth_limit_kbps.map(|v| v as u32),
            sync_hidden_files,
            auto_resolve_conflicts,
        })
    }
    
    /// Convert a row from the database to a SyncStatus
    fn row_to_sync_status(row: &Row) -> SqliteResult<SyncStatus> {
        let state_str: String = row.get(0)?;
        let last_sync: Option<String> = row.get(1)?;
        let current_operation: Option<String> = row.get(2)?;
        let current_file: Option<String> = row.get(3)?;
        let total_files: i64 = row.get(4)?;
        let processed_files: i64 = row.get(5)?;
        let total_bytes: i64 = row.get(6)?;
        let processed_bytes: i64 = row.get(7)?;
        let error_message: Option<String> = row.get(8)?;
        
        let state = match state_str.as_str() {
            "Syncing" => SyncState::Syncing,
            "Paused" => SyncState::Paused,
            "Stopped" => SyncState::Stopped,
            "Error" => SyncState::Error(error_message.unwrap_or_else(|| "Unknown error".to_string())),
            _ => SyncState::Idle,
        };
        
        let last_sync_datetime = last_sync.map(|s| {
            DateTime::parse_from_rfc3339(&s)
                .map(|dt| dt.with_timezone(&Utc))
                .unwrap_or_else(|_| Utc::now())
        });
        
        Ok(SyncStatus {
            state,
            last_sync: last_sync_datetime,
            current_operation,
            current_file,
            total_files: total_files as u32,
            processed_files: processed_files as u32,
            total_bytes: total_bytes as u64,
            processed_bytes: processed_bytes as u64,
            error_message,
        })
    }
    
    /// Convert a row from the database to a SyncEvent
    fn row_to_sync_event(row: &Row) -> SqliteResult<SyncEvent> {
        let event_type_str: String = row.get(0)?;
        let file_id: Option<String> = row.get(1)?;
        let message: Option<String> = row.get(2)?;
        let timestamp_str: String = row.get(3)?;
        
        let timestamp = DateTime::parse_from_rfc3339(&timestamp_str)
            .map_err(|_| rusqlite::Error::InvalidParameterName(format!("Invalid timestamp: {}", timestamp_str)))?
            .with_timezone(&Utc);
        
        let event_type = match event_type_str.as_str() {
            "SyncRequested" => SyncEventType::SyncRequested,
            "FileChanged" => {
                if let Some(file_id) = &file_id {
                    SyncEventType::FileChanged(file_id.clone())
                } else {
                    SyncEventType::SyncRequested
                }
            },
            "ConflictResolved" => {
                if let Some(file_id) = &file_id {
                    SyncEventType::ConflictResolved {
                        file_id: file_id.clone(),
                        direction: SyncDirection::Bidirectional, // Default
                    }
                } else {
                    SyncEventType::SyncRequested
                }
            },
            "StateChanged" => SyncEventType::StateChanged,
            "Error" => {
                if let Some(msg) = &message {
                    SyncEventType::Error(msg.clone())
                } else {
                    SyncEventType::Error("Unknown error".to_string())
                }
            },
            _ => SyncEventType::SyncRequested,
        };
        
        Ok(SyncEvent {
            event_type,
            file_id,
            message,
            timestamp,
        })
    }
    
    /// Load excluded paths from the database
    async fn load_excluded_paths(&self) -> SyncResult<Vec<String>> {
        let pool = self.pool.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let mut stmt = conn.prepare(
                "SELECT path FROM excluded_paths ORDER BY path ASC"
            ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            let path_iter = stmt.query_map([], |row| {
                let path: String = row.get(0)?;
                Ok(path)
            }).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            let mut paths = Vec::new();
            for path_result in path_iter {
                let path = path_result.map_err(|e| SyncError::SyncError(e.to_string()))?;
                paths.push(path);
            }
            
            Ok(paths)
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
    
    /// Save excluded paths to the database
    async fn save_excluded_paths(&self, paths: &[String]) -> SyncResult<()> {
        let pool = self.pool.clone();
        let paths_clone = paths.to_vec();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            // Begin transaction
            let tx = conn.transaction().map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            // Delete all existing excluded paths
            tx.execute("DELETE FROM excluded_paths", [])
                .map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            // Insert new excluded paths
            for path in &paths_clone {
                tx.execute(
                    "INSERT INTO excluded_paths (path) VALUES (?)",
                    [path],
                ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            }
            
            // Commit transaction
            tx.commit().map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            Ok(())
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
}

#[async_trait]
impl SyncRepository for SqliteSyncRepository {
    async fn get_sync_config(&self) -> SyncResult<SyncConfig> {
        let pool = self.pool.clone();
        
        let config = task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let config = conn.query_row(
                "SELECT enabled, sync_interval_secs, sync_on_startup, sync_on_file_change,
                        sync_direction, max_concurrent_transfers, bandwidth_limit_kbps,
                        sync_hidden_files, auto_resolve_conflicts
                 FROM sync_config 
                 LIMIT 1",
                [],
                |row| Self::row_to_sync_config(row),
            ).map_err(|e| SyncError::SyncError(format!("Failed to load sync config: {}", e)))?;
            
            Ok(config)
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?;
        
        // Load excluded paths
        let excluded_paths = self.load_excluded_paths().await?;
        
        // Create a new config with the excluded paths
        let mut final_config = config;
        final_config.excluded_paths = excluded_paths;
        
        Ok(final_config)
    }
    
    async fn save_sync_config(&self, config: &SyncConfig) -> SyncResult<()> {
        let pool = self.pool.clone();
        let config_clone = config.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let sync_direction_str = match config_clone.sync_direction {
                SyncDirection::Upload => "Upload",
                SyncDirection::Download => "Download",
                SyncDirection::Bidirectional => "Bidirectional",
            };
            
            // Update sync config
            let affected = conn.execute(
                "UPDATE sync_config SET 
                    enabled = ?, sync_interval_secs = ?, sync_on_startup = ?, sync_on_file_change = ?,
                    sync_direction = ?, max_concurrent_transfers = ?, bandwidth_limit_kbps = ?,
                    sync_hidden_files = ?, auto_resolve_conflicts = ?",
                params![
                    config_clone.enabled as i64,
                    config_clone.sync_interval.as_secs() as i64,
                    config_clone.sync_on_startup as i64,
                    config_clone.sync_on_file_change as i64,
                    sync_direction_str,
                    config_clone.max_concurrent_transfers as i64,
                    config_clone.bandwidth_limit_kbps.map(|v| v as i64),
                    config_clone.sync_hidden_files as i64,
                    config_clone.auto_resolve_conflicts as i64,
                ],
            ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            // If no rows were affected, insert a new config
            if affected == 0 {
                conn.execute(
                    "INSERT INTO sync_config (
                        enabled, sync_interval_secs, sync_on_startup, sync_on_file_change,
                        sync_direction, max_concurrent_transfers, bandwidth_limit_kbps,
                        sync_hidden_files, auto_resolve_conflicts
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    params![
                        config_clone.enabled as i64,
                        config_clone.sync_interval.as_secs() as i64,
                        config_clone.sync_on_startup as i64,
                        config_clone.sync_on_file_change as i64,
                        sync_direction_str,
                        config_clone.max_concurrent_transfers as i64,
                        config_clone.bandwidth_limit_kbps.map(|v| v as i64),
                        config_clone.sync_hidden_files as i64,
                        config_clone.auto_resolve_conflicts as i64,
                    ],
                ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            }
            
            Ok(())
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?;
        
        // Save excluded paths
        self.save_excluded_paths(&config.excluded_paths).await?;
        
        Ok(())
    }
    
    async fn get_sync_status(&self) -> SyncResult<SyncStatus> {
        let pool = self.pool.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let status = conn.query_row(
                "SELECT state, last_sync, current_operation, current_file,
                        total_files, processed_files, total_bytes, processed_bytes, error_message
                 FROM sync_status 
                 LIMIT 1",
                [],
                |row| Self::row_to_sync_status(row),
            ).map_err(|e| SyncError::SyncError(format!("Failed to load sync status: {}", e)))?;
            
            Ok(status)
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
    
    async fn update_sync_status(&self, status: &SyncStatus) -> SyncResult<()> {
        let pool = self.pool.clone();
        let status_clone = status.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let state_str = match status_clone.state {
                SyncState::Idle => "Idle",
                SyncState::Syncing => "Syncing",
                SyncState::Paused => "Paused",
                SyncState::Error(_) => "Error",
                SyncState::Stopped => "Stopped",
            };
            
            let last_sync_str = status_clone.last_sync.map(|dt| dt.to_rfc3339());
            
            let error_message = match status_clone.state {
                SyncState::Error(ref msg) => Some(msg.clone()),
                _ => status_clone.error_message,
            };
            
            // Update sync status
            let affected = conn.execute(
                "UPDATE sync_status SET 
                    state = ?, last_sync = ?, current_operation = ?, current_file = ?,
                    total_files = ?, processed_files = ?, total_bytes = ?, processed_bytes = ?,
                    error_message = ?",
                params![
                    state_str,
                    last_sync_str,
                    status_clone.current_operation,
                    status_clone.current_file,
                    status_clone.total_files as i64,
                    status_clone.processed_files as i64,
                    status_clone.total_bytes as i64,
                    status_clone.processed_bytes as i64,
                    error_message,
                ],
            ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            // If no rows were affected, insert a new status
            if affected == 0 {
                conn.execute(
                    "INSERT INTO sync_status (
                        state, last_sync, current_operation, current_file,
                        total_files, processed_files, total_bytes, processed_bytes,
                        error_message
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    params![
                        state_str,
                        last_sync_str,
                        status_clone.current_operation,
                        status_clone.current_file,
                        status_clone.total_files as i64,
                        status_clone.processed_files as i64,
                        status_clone.total_bytes as i64,
                        status_clone.processed_bytes as i64,
                        error_message,
                    ],
                ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            }
            
            Ok(())
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
    
    async fn start_sync(&self) -> SyncResult<()> {
        let current_status = self.get_sync_status().await?;
        
        if matches!(current_status.state, SyncState::Syncing) {
            return Err(SyncError::AlreadySyncing);
        }
        
        let mut new_status = current_status;
        new_status.state = SyncState::Syncing;
        new_status.error_message = None;
        new_status.current_operation = Some("Starting synchronization".to_string());
        
        self.update_sync_status(&new_status).await?;
        
        // Record the event
        self.record_event(SyncEvent {
            event_type: SyncEventType::SyncRequested,
            file_id: None,
            message: None,
            timestamp: Utc::now(),
        }).await?;
        
        Ok(())
    }
    
    async fn pause_sync(&self) -> SyncResult<()> {
        let current_status = self.get_sync_status().await?;
        
        if !matches!(current_status.state, SyncState::Syncing) {
            return Err(SyncError::NotStarted);
        }
        
        let mut new_status = current_status;
        new_status.state = SyncState::Paused;
        
        self.update_sync_status(&new_status).await?;
        
        // Record the event
        self.record_event(SyncEvent {
            event_type: SyncEventType::StateChanged,
            file_id: None,
            message: Some("Sync paused".to_string()),
            timestamp: Utc::now(),
        }).await?;
        
        Ok(())
    }
    
    async fn resume_sync(&self) -> SyncResult<()> {
        let current_status = self.get_sync_status().await?;
        
        if !matches!(current_status.state, SyncState::Paused) {
            return Err(SyncError::OperationError("Sync is not paused".to_string()));
        }
        
        let mut new_status = current_status;
        new_status.state = SyncState::Syncing;
        
        self.update_sync_status(&new_status).await?;
        
        // Record the event
        self.record_event(SyncEvent {
            event_type: SyncEventType::StateChanged,
            file_id: None,
            message: Some("Sync resumed".to_string()),
            timestamp: Utc::now(),
        }).await?;
        
        Ok(())
    }
    
    async fn cancel_sync(&self) -> SyncResult<()> {
        let current_status = self.get_sync_status().await?;
        
        if !matches!(current_status.state, SyncState::Syncing) && !matches!(current_status.state, SyncState::Paused) {
            return Err(SyncError::NotStarted);
        }
        
        let mut new_status = SyncStatus::default(); // Reset to default state
        new_status.last_sync = current_status.last_sync; // Preserve the last sync time
        
        self.update_sync_status(&new_status).await?;
        
        // Record the event
        self.record_event(SyncEvent {
            event_type: SyncEventType::StateChanged,
            file_id: None,
            message: Some("Sync cancelled".to_string()),
            timestamp: Utc::now(),
        }).await?;
        
        Ok(())
    }
    
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>> {
        self.load_excluded_paths().await
    }
    
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()> {
        self.save_excluded_paths(&paths).await
    }
    
    async fn get_last_sync_time(&self) -> SyncResult<Option<chrono::DateTime<chrono::Utc>>> {
        let status = self.get_sync_status().await?;
        Ok(status.last_sync)
    }
    
    async fn set_last_sync_time(&self, time: chrono::DateTime<chrono::Utc>) -> SyncResult<()> {
        let mut status = self.get_sync_status().await?;
        status.last_sync = Some(time);
        self.update_sync_status(&status).await
    }
    
    async fn get_conflicts(&self) -> SyncResult<Vec<crate::domain::entities::file::FileItem>> {
        use crate::domain::repositories::file_repository::FileRepository;
        
        let pool = self.pool.clone();
        
        // Create a temporary file repository to get the conflicted files
        let file_repo = crate::infrastructure::repositories::file_sqlite_repository::SqliteFileRepository::new(pool);
        
        file_repo.get_files_by_sync_status(crate::domain::entities::file::SyncStatus::Conflicted).await
            .map_err(|e| SyncError::FileError(e))
    }
    
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<crate::domain::entities::file::FileItem> {
        use crate::domain::repositories::file_repository::FileRepository;
        
        let pool = self.pool.clone();
        let file_id = file_id.to_string();
        
        // Create a temporary file repository
        let file_repo = crate::infrastructure::repositories::file_sqlite_repository::SqliteFileRepository::new(pool.clone());
        
        // Get the file
        let mut file = file_repo.get_file_by_id(&file_id).await
            .map_err(|e| SyncError::FileError(e))?;
        
        // Check if the file is actually in conflict
        if file.sync_status != crate::domain::entities::file::SyncStatus::Conflicted {
            return Err(SyncError::NotInConflict);
        }
        
        // Update the file's sync status based on the resolution
        file.sync_status = if keep_local {
            crate::domain::entities::file::SyncStatus::PendingUpload
        } else {
            crate::domain::entities::file::SyncStatus::PendingDownload
        };
        
        // Update the file
        let updated_file = file_repo.update_file(file, None).await
            .map_err(|e| SyncError::FileError(e))?;
        
        // Record the event
        self.record_event(SyncEvent {
            event_type: SyncEventType::ConflictResolved {
                file_id: file_id.clone(),
                direction: if keep_local {
                    SyncDirection::Upload
                } else {
                    SyncDirection::Download
                },
            },
            file_id: Some(file_id),
            message: Some(format!(
                "Conflict resolved for file '{}' by {}",
                updated_file.name,
                if keep_local { "keeping local version" } else { "downloading remote version" }
            )),
            timestamp: Utc::now(),
        }).await?;
        
        Ok(updated_file)
    }
    
    async fn record_event(&self, event: SyncEvent) -> SyncResult<()> {
        let pool = self.pool.clone();
        let event_clone = event.clone();
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let event_type_str = match event_clone.event_type {
                SyncEventType::SyncRequested => "SyncRequested",
                SyncEventType::FileChanged(_) => "FileChanged",
                SyncEventType::ConflictResolved { .. } => "ConflictResolved",
                SyncEventType::StateChanged => "StateChanged",
                SyncEventType::Error(_) => "Error",
            };
            
            conn.execute(
                "INSERT INTO sync_events (event_type, file_id, message, timestamp)
                 VALUES (?, ?, ?, ?)",
                params![
                    event_type_str,
                    event_clone.file_id,
                    event_clone.message,
                    event_clone.timestamp.to_rfc3339(),
                ],
            ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            Ok(())
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
    
    async fn get_recent_events(&self, limit: usize) -> SyncResult<Vec<SyncEvent>> {
        let pool = self.pool.clone();
        let limit = limit as i64;
        
        task::spawn_blocking(move || {
            let conn = pool.get().map_err(|e| SyncError::FileSystemError(e.to_string()))?;
            
            let mut stmt = conn.prepare(
                "SELECT event_type, file_id, message, timestamp
                 FROM sync_events
                 ORDER BY timestamp DESC
                 LIMIT ?"
            ).map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            let event_iter = stmt.query_map([limit], |row| Self::row_to_sync_event(row))
                .map_err(|e| SyncError::SyncError(e.to_string()))?;
            
            let mut events = Vec::new();
            for event_result in event_iter {
                let event = event_result.map_err(|e| SyncError::SyncError(e.to_string()))?;
                events.push(event);
            }
            
            Ok(events)
        }).await.map_err(|e| SyncError::SyncError(e.to_string()))?
    }
}

/// Factory for creating SQLite sync repositories
pub struct SqliteSyncRepositoryFactory {
    pool: Pool<SqliteConnectionManager>,
}

impl SqliteSyncRepositoryFactory {
    pub fn new(pool: Pool<SqliteConnectionManager>) -> Self {
        Self { pool }
    }
}

impl SyncRepositoryFactory for SqliteSyncRepositoryFactory {
    fn create_repository(&self) -> Arc<dyn SyncRepository> {
        Arc::new(SqliteSyncRepository::new(self.pool.clone()))
    }
}