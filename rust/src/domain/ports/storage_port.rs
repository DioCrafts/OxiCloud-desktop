//! # Storage Port
//!
//! Port interface for local storage operations (SQLite database).

use async_trait::async_trait;
use crate::domain::entities::{SyncItem, SyncStatus, SyncConfig, AuthSession};

/// Result type for storage operations
pub type StorageResult<T> = Result<T, StorageError>;

/// Storage operation errors
#[derive(Debug, thiserror::Error)]
pub enum StorageError {
    #[error("Database error: {0}")]
    DatabaseError(String),
    
    #[error("Item not found: {0}")]
    NotFound(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(String),
    
    #[error("IO error: {0}")]
    IoError(String),
    
    #[error("Migration error: {0}")]
    MigrationError(String),
}

/// Port interface for local storage
#[async_trait]
pub trait StoragePort: Send + Sync {
    // ========================================================================
    // Sync Items
    // ========================================================================
    
    /// Get a sync item by path
    async fn get_item(&self, path: &str) -> StorageResult<Option<SyncItem>>;
    
    /// Get a sync item by ID
    async fn get_item_by_id(&self, id: &str) -> StorageResult<Option<SyncItem>>;
    
    /// Get all items in a directory
    async fn get_items_in_directory(&self, directory_path: &str) -> StorageResult<Vec<SyncItem>>;
    
    /// Get all items with a specific status
    async fn get_items_by_status(&self, status: SyncStatus) -> StorageResult<Vec<SyncItem>>;
    
    /// Get all pending items (need sync)
    async fn get_pending_items(&self) -> StorageResult<Vec<SyncItem>>;
    
    /// Get all conflicted items
    async fn get_conflicts(&self) -> StorageResult<Vec<SyncItem>>;
    
    /// Save or update a sync item
    async fn save_item(&self, item: &SyncItem) -> StorageResult<()>;
    
    /// Save multiple items in a transaction
    async fn save_items(&self, items: &[SyncItem]) -> StorageResult<()>;
    
    /// Delete a sync item
    async fn delete_item(&self, path: &str) -> StorageResult<()>;
    
    /// Delete all items under a path (for directory deletion)
    async fn delete_items_under_path(&self, path: &str) -> StorageResult<u32>;
    
    /// Update item status
    async fn update_item_status(&self, path: &str, status: SyncStatus) -> StorageResult<()>;
    
    /// Get total item count
    async fn get_item_count(&self) -> StorageResult<u64>;
    
    /// Get total size of all items
    async fn get_total_size(&self) -> StorageResult<u64>;
    
    // ========================================================================
    // Sync History
    // ========================================================================
    
    /// Record a sync operation
    async fn record_sync_operation(
        &self,
        item_path: &str,
        operation: &str,
        success: bool,
        error_message: Option<&str>,
    ) -> StorageResult<()>;
    
    /// Get sync history
    async fn get_sync_history(&self, limit: u32) -> StorageResult<Vec<SyncHistoryRecord>>;
    
    /// Clear old history entries
    async fn clear_old_history(&self, older_than_days: u32) -> StorageResult<u32>;
    
    // ========================================================================
    // Configuration
    // ========================================================================
    
    /// Save configuration
    async fn save_config(&self, config: &SyncConfig) -> StorageResult<()>;
    
    /// Load configuration
    async fn load_config(&self) -> StorageResult<Option<SyncConfig>>;
    
    // ========================================================================
    // Authentication
    // ========================================================================
    
    /// Save authentication session
    async fn save_session(&self, session: &AuthSession) -> StorageResult<()>;
    
    /// Load authentication session
    async fn load_session(&self) -> StorageResult<Option<AuthSession>>;
    
    /// Clear authentication session
    async fn clear_session(&self) -> StorageResult<()>;
    
    // ========================================================================
    // Selective Sync
    // ========================================================================
    
    /// Save selected sync folders
    async fn save_sync_folders(&self, folder_ids: &[String]) -> StorageResult<()>;
    
    /// Load selected sync folders
    async fn load_sync_folders(&self) -> StorageResult<Vec<String>>;
}

/// Sync history record
#[derive(Debug, Clone)]
pub struct SyncHistoryRecord {
    pub id: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub item_path: String,
    pub operation: String,
    pub success: bool,
    pub error_message: Option<String>,
}
