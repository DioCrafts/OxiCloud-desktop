use async_trait::async_trait;
use chrono::{DateTime, Utc};
use rusqlite::{params, Connection, Result as SqliteResult};
use serde_json;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::Mutex;
use tracing::{debug, error, info, warn};

use crate::domain::entities::file::{FileItem, FileResult};
use crate::domain::entities::sync::{SyncConfig, SyncEvent, SyncError, SyncResult, SyncStatus, SyncState};
use crate::domain::repositories::sync_repository::SyncRepository;
use crate::infrastructure::repositories::sqlite_repository::ConnectionPool;

/// Implementation of SyncRepository that stores sync state and configuration in SQLite
pub struct SyncSqliteAdapter {
    /// SQLite connection pool
    pool: Arc<ConnectionPool>,
    /// Current sync status
    status: Arc<Mutex<SyncStatus>>,
}

impl SyncSqliteAdapter {
    pub fn new(pool: Arc<ConnectionPool>) -> Self {
        Self {
            pool,
            status: Arc::new(Mutex::new(SyncStatus::default())),
        }
    }
    
    /// Initialize database tables for sync repository
    pub fn init_tables(&self) -> SyncResult<()> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        // Create sync_config table
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_config (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                enabled BOOLEAN NOT NULL,
                sync_interval_secs INTEGER NOT NULL,
                sync_on_startup BOOLEAN NOT NULL,
                sync_on_file_change BOOLEAN NOT NULL,
                sync_direction TEXT NOT NULL,
                max_concurrent_transfers INTEGER NOT NULL,
                bandwidth_limit_kbps INTEGER,
                sync_hidden_files BOOLEAN NOT NULL,
                auto_resolve_conflicts BOOLEAN NOT NULL,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL
            )",
            [],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to create sync_config table: {}", e))
        })?;
        
        // Create sync_excluded_paths table
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_excluded_paths (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                path TEXT NOT NULL UNIQUE,
                created_at TIMESTAMP NOT NULL
            )",
            [],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to create sync_excluded_paths table: {}", e))
        })?;
        
        // Create sync_events table
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                file_id TEXT,
                message TEXT,
                event_data TEXT,
                timestamp TIMESTAMP NOT NULL
            )",
            [],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to create sync_events table: {}", e))
        })?;
        
        // Create sync_file_status table
        conn.execute(
            "CREATE TABLE IF NOT EXISTS sync_file_status (
                file_id TEXT PRIMARY KEY,
                last_synced_at TIMESTAMP,
                sync_status TEXT NOT NULL,
                last_error TEXT,
                remote_modified_at TIMESTAMP,
                local_modified_at TIMESTAMP,
                created_at TIMESTAMP NOT NULL,
                updated_at TIMESTAMP NOT NULL
            )",
            [],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to create sync_file_status table: {}", e))
        })?;
        
        // Insert default config if not exists
        let count: i64 = conn.query_row(
            "SELECT COUNT(*) FROM sync_config",
            [],
            |row| row.get(0),
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to count sync config: {}", e))
        })?;
        
        if count == 0 {
            let config = SyncConfig::default();
            let now = Utc::now();
            
            conn.execute(
                "INSERT INTO sync_config (
                    id, enabled, sync_interval_secs, sync_on_startup, sync_on_file_change, 
                    sync_direction, max_concurrent_transfers, bandwidth_limit_kbps,
                    sync_hidden_files, auto_resolve_conflicts, created_at, updated_at
                ) VALUES (
                    1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?
                )",
                params![
                    config.enabled,
                    config.sync_interval.as_secs(),
                    config.sync_on_startup,
                    config.sync_on_file_change,
                    serde_json::to_string(&config.sync_direction).unwrap(),
                    config.max_concurrent_transfers,
                    config.bandwidth_limit_kbps,
                    config.sync_hidden_files,
                    config.auto_resolve_conflicts,
                    now,
                    now,
                ],
            ).map_err(|e| {
                SyncError::FileSystemError(format!("Failed to insert default sync config: {}", e))
            })?;
            
            // Insert default excluded paths
            for path in &config.excluded_paths {
                conn.execute(
                    "INSERT OR IGNORE INTO sync_excluded_paths (path, created_at) VALUES (?, ?)",
                    params![path, now],
                ).map_err(|e| {
                    SyncError::FileSystemError(format!("Failed to insert excluded path: {}", e))
                })?;
            }
        }
        
        Ok(())
    }
    
    /// Parse sync event from JSON
    fn parse_sync_event(event_type: &str, file_id: Option<String>, message: Option<String>, data: &str, timestamp: DateTime<Utc>) -> SyncResult<SyncEvent> {
        let event_type = serde_json::from_str(event_type).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to parse event type: {}", e))
        })?;
        
        Ok(SyncEvent {
            event_type,
            file_id,
            message,
            timestamp,
        })
    }
}

#[async_trait]
impl SyncRepository for SyncSqliteAdapter {
    async fn get_sync_config(&self) -> SyncResult<SyncConfig> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let row = conn.query_row(
            "SELECT
                enabled, sync_interval_secs, sync_on_startup, sync_on_file_change,
                sync_direction, max_concurrent_transfers, bandwidth_limit_kbps,
                sync_hidden_files, auto_resolve_conflicts
            FROM sync_config WHERE id = 1",
            [],
            |row| {
                let enabled: bool = row.get(0)?;
                let sync_interval_secs: u64 = row.get(1)?;
                let sync_on_startup: bool = row.get(2)?;
                let sync_on_file_change: bool = row.get(3)?;
                let sync_direction_str: String = row.get(4)?;
                let max_concurrent_transfers: u32 = row.get(5)?;
                let bandwidth_limit_kbps: Option<u32> = row.get(6)?;
                let sync_hidden_files: bool = row.get(7)?;
                let auto_resolve_conflicts: bool = row.get(8)?;
                
                let sync_direction = serde_json::from_str(&sync_direction_str).unwrap_or_default();
                
                // Get excluded paths
                let mut stmt = conn.prepare("SELECT path FROM sync_excluded_paths")?;
                let excluded_paths: Result<Vec<String>, rusqlite::Error> = stmt
                    .query_map([], |row| row.get(0))?
                    .collect();
                
                Ok(SyncConfig {
                    enabled,
                    sync_interval: Duration::from_secs(sync_interval_secs),
                    sync_on_startup,
                    sync_on_file_change,
                    sync_direction,
                    excluded_paths: excluded_paths?,
                    max_concurrent_transfers,
                    bandwidth_limit_kbps,
                    sync_hidden_files,
                    auto_resolve_conflicts,
                })
            },
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get sync config: {}", e))
        })?;
        
        Ok(row)
    }
    
    async fn save_sync_config(&self, config: &SyncConfig) -> SyncResult<()> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let now = Utc::now();
        
        // Update config
        conn.execute(
            "UPDATE sync_config SET
                enabled = ?,
                sync_interval_secs = ?,
                sync_on_startup = ?,
                sync_on_file_change = ?,
                sync_direction = ?,
                max_concurrent_transfers = ?,
                bandwidth_limit_kbps = ?,
                sync_hidden_files = ?,
                auto_resolve_conflicts = ?,
                updated_at = ?
            WHERE id = 1",
            params![
                config.enabled,
                config.sync_interval.as_secs(),
                config.sync_on_startup,
                config.sync_on_file_change,
                serde_json::to_string(&config.sync_direction).unwrap(),
                config.max_concurrent_transfers,
                config.bandwidth_limit_kbps,
                config.sync_hidden_files,
                config.auto_resolve_conflicts,
                now,
            ],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to update sync config: {}", e))
        })?;
        
        // Clear and re-insert excluded paths
        conn.execute("DELETE FROM sync_excluded_paths", []).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to clear excluded paths: {}", e))
        })?;
        
        for path in &config.excluded_paths {
            conn.execute(
                "INSERT INTO sync_excluded_paths (path, created_at) VALUES (?, ?)",
                params![path, now],
            ).map_err(|e| {
                SyncError::FileSystemError(format!("Failed to insert excluded path: {}", e))
            })?;
        }
        
        Ok(())
    }
    
    async fn get_sync_status(&self) -> SyncResult<SyncStatus> {
        let status = self.status.lock().await;
        Ok(status.clone())
    }
    
    async fn update_sync_status(&self, status: &SyncStatus) -> SyncResult<()> {
        let mut current_status = self.status.lock().await;
        *current_status = status.clone();
        Ok(())
    }
    
    async fn start_sync(&self) -> SyncResult<()> {
        let mut status = self.status.lock().await;
        
        // Check if already syncing
        if let SyncState::Syncing = status.state {
            return Err(SyncError::SyncError("Sync already in progress".to_string()));
        }
        
        // Update status
        status.state = SyncState::Syncing;
        
        // Record event
        drop(status);
        self.record_event(SyncEvent {
            event_type: crate::domain::entities::sync::SyncEventType::SyncRequested,
            file_id: None,
            message: Some("Sync started".to_string()),
            timestamp: Utc::now(),
        }).await?;
        
        Ok(())
    }
    
    async fn pause_sync(&self) -> SyncResult<()> {
        let mut status = self.status.lock().await;
        
        // Check if currently syncing
        if let SyncState::Syncing = status.state {
            // Update status
            status.state = SyncState::Paused;
            
            // Record event
            drop(status);
            self.record_event(SyncEvent {
                event_type: crate::domain::entities::sync::SyncEventType::StateChanged,
                file_id: None,
                message: Some("Sync paused".to_string()),
                timestamp: Utc::now(),
            }).await?;
            
            Ok(())
        } else {
            Err(SyncError::SyncError("Sync not in progress".to_string()))
        }
    }
    
    async fn resume_sync(&self) -> SyncResult<()> {
        let mut status = self.status.lock().await;
        
        // Check if currently paused
        if let SyncState::Paused = status.state {
            // Update status
            status.state = SyncState::Syncing;
            
            // Record event
            drop(status);
            self.record_event(SyncEvent {
                event_type: crate::domain::entities::sync::SyncEventType::StateChanged,
                file_id: None,
                message: Some("Sync resumed".to_string()),
                timestamp: Utc::now(),
            }).await?;
            
            Ok(())
        } else {
            Err(SyncError::SyncError("Sync not paused".to_string()))
        }
    }
    
    async fn cancel_sync(&self) -> SyncResult<()> {
        let mut status = self.status.lock().await;
        
        // Check if currently syncing or paused
        if matches!(status.state, SyncState::Syncing | SyncState::Paused) {
            // Update status
            status.state = SyncState::Idle;
            
            // Record event
            drop(status);
            self.record_event(SyncEvent {
                event_type: crate::domain::entities::sync::SyncEventType::StateChanged,
                file_id: None,
                message: Some("Sync cancelled".to_string()),
                timestamp: Utc::now(),
            }).await?;
            
            Ok(())
        } else {
            Err(SyncError::SyncError("Sync not in progress".to_string()))
        }
    }
    
    async fn get_excluded_items(&self) -> SyncResult<Vec<String>> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let mut stmt = conn.prepare("SELECT path FROM sync_excluded_paths").map_err(|e| {
            SyncError::FileSystemError(format!("Failed to prepare statement: {}", e))
        })?;
        
        let rows = stmt.query_map([], |row| row.get(0)).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to query excluded paths: {}", e))
        })?;
        
        let mut excluded_paths = Vec::new();
        for path_result in rows {
            let path: String = path_result.map_err(|e| {
                SyncError::FileSystemError(format!("Failed to read excluded path: {}", e))
            })?;
            excluded_paths.push(path);
        }
        
        Ok(excluded_paths)
    }
    
    async fn set_excluded_items(&self, paths: Vec<String>) -> SyncResult<()> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let now = Utc::now();
        
        // Clear and re-insert excluded paths
        conn.execute("DELETE FROM sync_excluded_paths", []).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to clear excluded paths: {}", e))
        })?;
        
        for path in &paths {
            conn.execute(
                "INSERT INTO sync_excluded_paths (path, created_at) VALUES (?, ?)",
                params![path, now],
            ).map_err(|e| {
                SyncError::FileSystemError(format!("Failed to insert excluded path: {}", e))
            })?;
        }
        
        // Update config with new excluded paths
        let mut config = self.get_sync_config().await?;
        config.excluded_paths = paths;
        self.save_sync_config(&config).await?;
        
        Ok(())
    }
    
    async fn get_last_sync_time(&self) -> SyncResult<Option<DateTime<Utc>>> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let last_sync: Option<String> = conn.query_row(
            "SELECT MAX(timestamp) FROM sync_events WHERE event_type = ?",
            params![r#"{"SyncRequested":null}"#],
            |row| row.get(0),
        ).optional().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get last sync time: {}", e))
        })?;
        
        if let Some(timestamp_str) = last_sync {
            let timestamp = DateTime::parse_from_rfc3339(&timestamp_str)
                .map_err(|e| {
                    SyncError::FileSystemError(format!("Failed to parse timestamp: {}", e))
                })?
                .with_timezone(&Utc);
            
            Ok(Some(timestamp))
        } else {
            Ok(None)
        }
    }
    
    async fn set_last_sync_time(&self, time: DateTime<Utc>) -> SyncResult<()> {
        // Record a sync completion event
        self.record_event(SyncEvent {
            event_type: crate::domain::entities::sync::SyncEventType::StateChanged,
            file_id: None,
            message: Some("Sync completed".to_string()),
            timestamp: time,
        }).await?;
        
        // Update sync status
        let mut status = self.status.lock().await;
        status.last_sync = Some(time);
        status.state = SyncState::Idle;
        
        Ok(())
    }
    
    async fn get_conflicts(&self) -> SyncResult<Vec<FileItem>> {
        // Get files with conflict status from the database
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let mut stmt = conn.prepare("
            SELECT fs.file_id, fs.last_error 
            FROM sync_file_status fs
            WHERE fs.sync_status = 'Conflicted'
        ").map_err(|e| {
            SyncError::FileSystemError(format!("Failed to prepare statement: {}", e))
        })?;
        
        let rows = stmt.query_map([], |row| {
            let file_id: String = row.get(0)?;
            let error: Option<String> = row.get(1)?;
            Ok((file_id, error))
        }).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to query conflicts: {}", e))
        })?;
        
        // For a full implementation, you would need to join with your files table
        // to get all the file metadata. This is a simplified version.
        let mut conflicts = Vec::new();
        for result in rows {
            let (file_id, _error) = result.map_err(|e| {
                SyncError::FileSystemError(format!("Failed to read conflict: {}", e))
            })?;
            
            // For a complete implementation, you would fetch the full FileItem here
            // This is just a placeholder that would need to be replaced with actual file retrieval
            // from whatever file repository you're using
            debug!("Found conflict for file: {}", file_id);
        }
        
        Ok(conflicts)
    }
    
    async fn resolve_conflict(&self, file_id: &str, keep_local: bool) -> SyncResult<FileItem> {
        // Record conflict resolution event
        self.record_event(SyncEvent {
            event_type: crate::domain::entities::sync::SyncEventType::ConflictResolved {
                file_id: file_id.to_string(),
                direction: if keep_local {
                    crate::domain::entities::sync::SyncDirection::Upload
                } else {
                    crate::domain::entities::sync::SyncDirection::Download
                },
            },
            file_id: Some(file_id.to_string()),
            message: Some(format!(
                "Conflict resolved for file {} ({})",
                file_id,
                if keep_local { "keep local" } else { "keep remote" }
            )),
            timestamp: Utc::now(),
        }).await?;
        
        // Update sync status for the file
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let now = Utc::now();
        
        conn.execute(
            "UPDATE sync_file_status 
            SET sync_status = 'PendingSync', 
                last_error = NULL,
                updated_at = ?
            WHERE file_id = ?",
            params![now, file_id],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to update file sync status: {}", e))
        })?;
        
        // For a complete implementation, you would fetch the updated FileItem here
        // This is just a placeholder
        Err(SyncError::SyncError("File fetch not implemented".to_string()))
    }
    
    async fn record_event(&self, event: SyncEvent) -> SyncResult<()> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let event_type_json = serde_json::to_string(&event.event_type).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to serialize event type: {}", e))
        })?;
        
        let event_data = serde_json::to_string(&event).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to serialize event: {}", e))
        })?;
        
        conn.execute(
            "INSERT INTO sync_events (event_type, file_id, message, event_data, timestamp)
            VALUES (?, ?, ?, ?, ?)",
            params![
                event_type_json,
                event.file_id,
                event.message,
                event_data,
                event.timestamp,
            ],
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to record sync event: {}", e))
        })?;
        
        Ok(())
    }
    
    async fn get_recent_events(&self, limit: usize) -> SyncResult<Vec<SyncEvent>> {
        let conn = self.pool.get().map_err(|e| {
            SyncError::FileSystemError(format!("Failed to get database connection: {}", e))
        })?;
        
        let mut stmt = conn.prepare(
            "SELECT event_type, file_id, message, event_data, timestamp 
            FROM sync_events 
            ORDER BY timestamp DESC 
            LIMIT ?"
        ).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to prepare statement: {}", e))
        })?;
        
        let rows = stmt.query_map(params![limit as i64], |row| {
            let event_type: String = row.get(0)?;
            let file_id: Option<String> = row.get(1)?;
            let message: Option<String> = row.get(2)?;
            let event_data: String = row.get(3)?;
            let timestamp_str: String = row.get(4)?;
            
            let timestamp = DateTime::parse_from_rfc3339(&timestamp_str)
                .map_err(|_| rusqlite::Error::InvalidColumnType(4, "timestamp".to_string(), rusqlite::types::Type::Text))?
                .with_timezone(&Utc);
            
            Ok((event_type, file_id, message, event_data, timestamp))
        }).map_err(|e| {
            SyncError::FileSystemError(format!("Failed to query events: {}", e))
        })?;
        
        let mut events = Vec::new();
        for result in rows {
            let (event_type, file_id, message, event_data, timestamp) = result.map_err(|e| {
                SyncError::FileSystemError(format!("Failed to read event: {}", e))
            })?;
            
            // Parse event using saved event data
            let event = Self::parse_sync_event(&event_type, file_id, message, &event_data, timestamp)?;
            events.push(event);
        }
        
        Ok(events)
    }
}

/// Factory for creating SyncSqliteAdapter instances
pub struct SyncSqliteAdapterFactory {
    pool: Arc<ConnectionPool>,
}

impl SyncSqliteAdapterFactory {
    pub fn new(pool: Arc<ConnectionPool>) -> Self {
        Self { pool }
    }
}

impl crate::domain::repositories::sync_repository::SyncRepositoryFactory for SyncSqliteAdapterFactory {
    fn create_repository(&self) -> Arc<dyn SyncRepository> {
        let adapter = SyncSqliteAdapter::new(self.pool.clone());
        
        // Initialize tables
        if let Err(e) = adapter.init_tables() {
            error!("Failed to initialize sync repository tables: {}", e);
        }
        
        Arc::new(adapter)
    }
}