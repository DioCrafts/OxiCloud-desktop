//! # SQLite Storage
//!
//! Local SQLite database for sync state persistence.

use std::path::Path;
use async_trait::async_trait;
use rusqlite::{Connection, params};
use tokio::sync::Mutex;
use chrono::{DateTime, Utc};

use crate::domain::entities::{SyncItem, SyncStatus, SyncConfig, AuthSession};
use crate::domain::ports::{StoragePort, StorageResult, StorageError, SyncHistoryRecord};

/// SQLite storage implementation
pub struct SqliteStorage {
    conn: Mutex<Connection>,
}

impl SqliteStorage {
    /// Create a new SQLite storage
    pub async fn new(db_path: &str) -> StorageResult<Self> {
        // Create parent directories if needed
        if let Some(parent) = Path::new(db_path).parent() {
            std::fs::create_dir_all(parent)
                .map_err(|e| StorageError::IoError(e.to_string()))?;
        }
        
        let conn = Connection::open(db_path)
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let storage = Self {
            conn: Mutex::new(conn),
        };
        
        storage.run_migrations().await?;
        
        tracing::info!("SQLite storage initialized at {}", db_path);
        Ok(storage)
    }
    
    /// Run database migrations
    async fn run_migrations(&self) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute_batch(r#"
            -- Sync items table
            CREATE TABLE IF NOT EXISTS sync_items (
                id TEXT PRIMARY KEY,
                path TEXT UNIQUE NOT NULL,
                name TEXT NOT NULL,
                is_directory INTEGER NOT NULL DEFAULT 0,
                size INTEGER NOT NULL DEFAULT 0,
                content_hash TEXT,
                local_modified INTEGER,
                remote_modified INTEGER,
                status TEXT NOT NULL DEFAULT 'pending',
                direction TEXT NOT NULL DEFAULT 'none',
                etag TEXT,
                mime_type TEXT,
                created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
            );
            
            CREATE INDEX IF NOT EXISTS idx_sync_items_path ON sync_items(path);
            CREATE INDEX IF NOT EXISTS idx_sync_items_status ON sync_items(status);
            
            -- Sync history table
            CREATE TABLE IF NOT EXISTS sync_history (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
                item_path TEXT NOT NULL,
                operation TEXT NOT NULL,
                success INTEGER NOT NULL DEFAULT 1,
                error_message TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_sync_history_timestamp ON sync_history(timestamp DESC);
            
            -- Configuration table
            CREATE TABLE IF NOT EXISTS config (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            
            -- Auth session table
            CREATE TABLE IF NOT EXISTS auth_session (
                id INTEGER PRIMARY KEY CHECK (id = 1),
                user_id TEXT NOT NULL,
                username TEXT NOT NULL,
                access_token TEXT NOT NULL,
                refresh_token TEXT,
                expires_at INTEGER,
                server_info TEXT NOT NULL,
                created_at INTEGER NOT NULL
            );
            
            -- Sync folders table (for selective sync)
            CREATE TABLE IF NOT EXISTS sync_folders (
                folder_id TEXT PRIMARY KEY
            );
        "#).map_err(|e| StorageError::MigrationError(e.to_string()))?;
        
        Ok(())
    }
    
    /// Serialize status to string
    fn serialize_status(status: &SyncStatus) -> String {
        match status {
            SyncStatus::Synced => "synced".to_string(),
            SyncStatus::Pending => "pending".to_string(),
            SyncStatus::Syncing => "syncing".to_string(),
            SyncStatus::Conflict(_) => "conflict".to_string(),
            SyncStatus::Error(msg) => format!("error:{}", msg),
            SyncStatus::Ignored => "ignored".to_string(),
        }
    }
    
    /// Deserialize status from string
    fn deserialize_status(s: &str) -> SyncStatus {
        match s {
            "synced" => SyncStatus::Synced,
            "pending" => SyncStatus::Pending,
            "syncing" => SyncStatus::Syncing,
            "conflict" => SyncStatus::Conflict(crate::domain::entities::ConflictInfo {
                conflict_type: crate::domain::entities::ConflictType::BothModified,
                detected_at: Utc::now(),
            }),
            "ignored" => SyncStatus::Ignored,
            s if s.starts_with("error:") => SyncStatus::Error(s[6..].to_string()),
            _ => SyncStatus::Pending,
        }
    }
    
    /// Serialize direction to string
    fn serialize_direction(direction: &crate::domain::entities::SyncDirection) -> String {
        match direction {
            crate::domain::entities::SyncDirection::Upload => "upload".to_string(),
            crate::domain::entities::SyncDirection::Download => "download".to_string(),
            crate::domain::entities::SyncDirection::None => "none".to_string(),
        }
    }
    
    /// Deserialize direction from string
    fn deserialize_direction(s: &str) -> crate::domain::entities::SyncDirection {
        match s {
            "upload" => crate::domain::entities::SyncDirection::Upload,
            "download" => crate::domain::entities::SyncDirection::Download,
            _ => crate::domain::entities::SyncDirection::None,
        }
    }
}

#[async_trait]
impl StoragePort for SqliteStorage {
    async fn get_item(&self, path: &str) -> StorageResult<Option<SyncItem>> {
        let conn = self.conn.lock().await;
        
        let mut stmt = conn.prepare(
            "SELECT id, path, name, is_directory, size, content_hash, local_modified, 
                    remote_modified, status, direction, etag, mime_type
             FROM sync_items WHERE path = ?"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let result = stmt.query_row(params![path], |row| {
            Ok(SyncItem {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                is_directory: row.get::<_, i32>(3)? != 0,
                size: row.get(4)?,
                content_hash: row.get(5)?,
                local_modified: row.get::<_, Option<i64>>(6)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                remote_modified: row.get::<_, Option<i64>>(7)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                status: Self::deserialize_status(&row.get::<_, String>(8)?),
                direction: Self::deserialize_direction(&row.get::<_, String>(9)?),
                etag: row.get(10)?,
                mime_type: row.get(11)?,
            })
        });
        
        match result {
            Ok(item) => Ok(Some(item)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(StorageError::DatabaseError(e.to_string())),
        }
    }
    
    async fn get_item_by_id(&self, id: &str) -> StorageResult<Option<SyncItem>> {
        let conn = self.conn.lock().await;
        
        let mut stmt = conn.prepare(
            "SELECT id, path, name, is_directory, size, content_hash, local_modified, 
                    remote_modified, status, direction, etag, mime_type
             FROM sync_items WHERE id = ?"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let result = stmt.query_row(params![id], |row| {
            Ok(SyncItem {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                is_directory: row.get::<_, i32>(3)? != 0,
                size: row.get(4)?,
                content_hash: row.get(5)?,
                local_modified: row.get::<_, Option<i64>>(6)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                remote_modified: row.get::<_, Option<i64>>(7)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                status: Self::deserialize_status(&row.get::<_, String>(8)?),
                direction: Self::deserialize_direction(&row.get::<_, String>(9)?),
                etag: row.get(10)?,
                mime_type: row.get(11)?,
            })
        });
        
        match result {
            Ok(item) => Ok(Some(item)),
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(StorageError::DatabaseError(e.to_string())),
        }
    }
    
    async fn get_items_in_directory(&self, directory_path: &str) -> StorageResult<Vec<SyncItem>> {
        let conn = self.conn.lock().await;
        let pattern = format!("{}%", directory_path);
        
        let mut stmt = conn.prepare(
            "SELECT id, path, name, is_directory, size, content_hash, local_modified, 
                    remote_modified, status, direction, etag, mime_type
             FROM sync_items WHERE path LIKE ?"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let iter = stmt.query_map(params![pattern], |row| {
            Ok(SyncItem {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                is_directory: row.get::<_, i32>(3)? != 0,
                size: row.get(4)?,
                content_hash: row.get(5)?,
                local_modified: row.get::<_, Option<i64>>(6)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                remote_modified: row.get::<_, Option<i64>>(7)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                status: Self::deserialize_status(&row.get::<_, String>(8)?),
                direction: Self::deserialize_direction(&row.get::<_, String>(9)?),
                etag: row.get(10)?,
                mime_type: row.get(11)?,
            })
        }).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let items: Result<Vec<_>, _> = iter.collect();
        items.map_err(|e| StorageError::DatabaseError(e.to_string()))
    }
    
    async fn get_items_by_status(&self, status: SyncStatus) -> StorageResult<Vec<SyncItem>> {
        let conn = self.conn.lock().await;
        let status_str = Self::serialize_status(&status);
        
        let mut stmt = conn.prepare(
            "SELECT id, path, name, is_directory, size, content_hash, local_modified, 
                    remote_modified, status, direction, etag, mime_type
             FROM sync_items WHERE status = ?"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let iter = stmt.query_map(params![status_str], |row| {
            Ok(SyncItem {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                is_directory: row.get::<_, i32>(3)? != 0,
                size: row.get(4)?,
                content_hash: row.get(5)?,
                local_modified: row.get::<_, Option<i64>>(6)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                remote_modified: row.get::<_, Option<i64>>(7)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                status: Self::deserialize_status(&row.get::<_, String>(8)?),
                direction: Self::deserialize_direction(&row.get::<_, String>(9)?),
                etag: row.get(10)?,
                mime_type: row.get(11)?,
            })
        }).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let items: Result<Vec<_>, _> = iter.collect();
        items.map_err(|e| StorageError::DatabaseError(e.to_string()))
    }
    
    async fn get_pending_items(&self) -> StorageResult<Vec<SyncItem>> {
        self.get_items_by_status(SyncStatus::Pending).await
    }
    
    async fn get_conflicts(&self) -> StorageResult<Vec<SyncItem>> {
        let conn = self.conn.lock().await;
        
        let mut stmt = conn.prepare(
            "SELECT id, path, name, is_directory, size, content_hash, local_modified, 
                    remote_modified, status, direction, etag, mime_type
             FROM sync_items WHERE status = 'conflict'"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let iter = stmt.query_map([], |row| {
            Ok(SyncItem {
                id: row.get(0)?,
                path: row.get(1)?,
                name: row.get(2)?,
                is_directory: row.get::<_, i32>(3)? != 0,
                size: row.get(4)?,
                content_hash: row.get(5)?,
                local_modified: row.get::<_, Option<i64>>(6)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                remote_modified: row.get::<_, Option<i64>>(7)?
                    .and_then(|ts| DateTime::from_timestamp(ts, 0)),
                status: Self::deserialize_status(&row.get::<_, String>(8)?),
                direction: Self::deserialize_direction(&row.get::<_, String>(9)?),
                etag: row.get(10)?,
                mime_type: row.get(11)?,
            })
        }).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let items: Result<Vec<_>, _> = iter.collect();
        items.map_err(|e| StorageError::DatabaseError(e.to_string()))
    }
    
    async fn save_item(&self, item: &SyncItem) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute(
            "INSERT OR REPLACE INTO sync_items 
             (id, path, name, is_directory, size, content_hash, local_modified, 
              remote_modified, status, direction, etag, mime_type, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, strftime('%s', 'now'))",
            params![
                item.id,
                item.path,
                item.name,
                item.is_directory as i32,
                item.size as i64,
                item.content_hash,
                item.local_modified.map(|t| t.timestamp()),
                item.remote_modified.map(|t| t.timestamp()),
                Self::serialize_status(&item.status),
                Self::serialize_direction(&item.direction),
                item.etag,
                item.mime_type,
            ],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn save_items(&self, items: &[SyncItem]) -> StorageResult<()> {
        for item in items {
            self.save_item(item).await?;
        }
        Ok(())
    }
    
    async fn delete_item(&self, path: &str) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute("DELETE FROM sync_items WHERE path = ?", params![path])
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn delete_items_under_path(&self, path: &str) -> StorageResult<u32> {
        let conn = self.conn.lock().await;
        let pattern = format!("{}%", path);
        
        let count = conn.execute("DELETE FROM sync_items WHERE path LIKE ?", params![pattern])
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(count as u32)
    }
    
    async fn update_item_status(&self, path: &str, status: SyncStatus) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute(
            "UPDATE sync_items SET status = ?, updated_at = strftime('%s', 'now') WHERE path = ?",
            params![Self::serialize_status(&status), path],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn get_item_count(&self) -> StorageResult<u64> {
        let conn = self.conn.lock().await;
        
        let count: i64 = conn.query_row(
            "SELECT COUNT(*) FROM sync_items",
            [],
            |row| row.get(0),
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(count as u64)
    }
    
    async fn get_total_size(&self) -> StorageResult<u64> {
        let conn = self.conn.lock().await;
        
        let size: i64 = conn.query_row(
            "SELECT COALESCE(SUM(size), 0) FROM sync_items",
            [],
            |row| row.get(0),
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(size as u64)
    }
    
    async fn record_sync_operation(
        &self,
        item_path: &str,
        operation: &str,
        success: bool,
        error_message: Option<&str>,
    ) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute(
            "INSERT INTO sync_history (id, item_path, operation, success, error_message)
             VALUES (?, ?, ?, ?, ?)",
            params![
                uuid::Uuid::new_v4().to_string(),
                item_path,
                operation,
                success as i32,
                error_message,
            ],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn get_sync_history(&self, limit: u32) -> StorageResult<Vec<SyncHistoryRecord>> {
        let conn = self.conn.lock().await;
        
        let mut stmt = conn.prepare(
            "SELECT id, timestamp, item_path, operation, success, error_message
             FROM sync_history ORDER BY timestamp DESC LIMIT ?"
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let iter = stmt.query_map(params![limit], |row| {
            let timestamp: i64 = row.get(1)?;
            Ok(SyncHistoryRecord {
                id: row.get(0)?,
                timestamp: DateTime::from_timestamp(timestamp, 0).unwrap_or_else(Utc::now),
                item_path: row.get(2)?,
                operation: row.get(3)?,
                success: row.get::<_, i32>(4)? != 0,
                error_message: row.get(5)?,
            })
        }).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let records: Result<Vec<_>, _> = iter.collect();
        records.map_err(|e| StorageError::DatabaseError(e.to_string()))
    }
    
    async fn clear_old_history(&self, older_than_days: u32) -> StorageResult<u32> {
        let conn = self.conn.lock().await;
        let cutoff = Utc::now().timestamp() - (older_than_days as i64 * 24 * 60 * 60);
        
        let count = conn.execute(
            "DELETE FROM sync_history WHERE timestamp < ?",
            params![cutoff],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(count as u32)
    }
    
    async fn save_config(&self, config: &SyncConfig) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        let json = serde_json::to_string(config)
            .map_err(|e| StorageError::SerializationError(e.to_string()))?;
        
        conn.execute(
            "INSERT OR REPLACE INTO config (key, value) VALUES ('sync_config', ?)",
            params![json],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn load_config(&self) -> StorageResult<Option<SyncConfig>> {
        let conn = self.conn.lock().await;
        
        let result: Result<String, _> = conn.query_row(
            "SELECT value FROM config WHERE key = 'sync_config'",
            [],
            |row| row.get(0),
        );
        
        match result {
            Ok(json) => {
                let config: SyncConfig = serde_json::from_str(&json)
                    .map_err(|e| StorageError::SerializationError(e.to_string()))?;
                Ok(Some(config))
            }
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(StorageError::DatabaseError(e.to_string())),
        }
    }
    
    async fn save_session(&self, session: &AuthSession) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        let server_info_json = serde_json::to_string(&session.server_info)
            .map_err(|e| StorageError::SerializationError(e.to_string()))?;
        
        conn.execute(
            "INSERT OR REPLACE INTO auth_session 
             (id, user_id, username, access_token, refresh_token, expires_at, server_info, created_at)
             VALUES (1, ?, ?, ?, ?, ?, ?, ?)",
            params![
                session.user_id,
                session.username,
                session.access_token,
                session.refresh_token,
                session.expires_at.map(|t| t.timestamp()),
                server_info_json,
                session.created_at.timestamp(),
            ],
        ).map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn load_session(&self) -> StorageResult<Option<AuthSession>> {
        let conn = self.conn.lock().await;
        
        let result = conn.query_row(
            "SELECT user_id, username, access_token, refresh_token, expires_at, server_info, created_at
             FROM auth_session WHERE id = 1",
            [],
            |row| {
                let expires_at: Option<i64> = row.get(4)?;
                let server_info_json: String = row.get(5)?;
                let created_at: i64 = row.get(6)?;
                
                Ok((
                    row.get::<_, String>(0)?,
                    row.get::<_, String>(1)?,
                    row.get::<_, String>(2)?,
                    row.get::<_, Option<String>>(3)?,
                    expires_at,
                    server_info_json,
                    created_at,
                ))
            },
        );
        
        match result {
            Ok((user_id, username, access_token, refresh_token, expires_at, server_info_json, created_at)) => {
                let server_info: crate::domain::entities::ServerInfo = serde_json::from_str(&server_info_json)
                    .map_err(|e| StorageError::SerializationError(e.to_string()))?;
                
                Ok(Some(AuthSession {
                    user_id,
                    username,
                    access_token,
                    refresh_token,
                    expires_at: expires_at.and_then(|ts| DateTime::from_timestamp(ts, 0)),
                    server_info,
                    created_at: DateTime::from_timestamp(created_at, 0).unwrap_or_else(Utc::now),
                }))
            }
            Err(rusqlite::Error::QueryReturnedNoRows) => Ok(None),
            Err(e) => Err(StorageError::DatabaseError(e.to_string())),
        }
    }
    
    async fn clear_session(&self) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        conn.execute("DELETE FROM auth_session", [])
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        Ok(())
    }
    
    async fn save_sync_folders(&self, folder_ids: &[String]) -> StorageResult<()> {
        let conn = self.conn.lock().await;
        
        // Clear existing
        conn.execute("DELETE FROM sync_folders", [])
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        // Insert new
        for id in folder_ids {
            conn.execute("INSERT INTO sync_folders (folder_id) VALUES (?)", params![id])
                .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        }
        
        Ok(())
    }
    
    async fn load_sync_folders(&self) -> StorageResult<Vec<String>> {
        let conn = self.conn.lock().await;
        
        let mut stmt = conn.prepare("SELECT folder_id FROM sync_folders")
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let iter = stmt.query_map([], |row| row.get(0))
            .map_err(|e| StorageError::DatabaseError(e.to_string()))?;
        
        let ids: Result<Vec<_>, _> = iter.collect();
        ids.map_err(|e| StorageError::DatabaseError(e.to_string()))
    }
}
