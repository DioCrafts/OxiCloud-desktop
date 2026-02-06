//! # Sync Port
//!
//! Port interface for remote synchronization operations (WebDAV).

use async_trait::async_trait;
use crate::domain::entities::{SyncItem, SyncConfig};

/// Result type for sync operations
pub type SyncResult<T> = Result<T, SyncError>;

/// Sync operation errors
#[derive(Debug, thiserror::Error)]
pub enum SyncError {
    #[error("Connection failed: {0}")]
    ConnectionFailed(String),
    
    #[error("Authentication failed: {0}")]
    AuthenticationFailed(String),
    
    #[error("Item not found: {0}")]
    NotFound(String),
    
    #[error("Conflict detected: {0}")]
    Conflict(String),
    
    #[error("Quota exceeded")]
    QuotaExceeded,
    
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Server error: {0}")]
    ServerError(String),
    
    #[error("IO error: {0}")]
    IoError(String),
    
    #[error("Parse error: {0}")]
    ParseError(String),
}

/// Remote file/folder metadata
#[derive(Debug, Clone)]
pub struct RemoteItem {
    pub id: String,
    pub path: String,
    pub name: String,
    pub is_directory: bool,
    pub size: u64,
    pub modified: chrono::DateTime<chrono::Utc>,
    pub etag: Option<String>,
    pub mime_type: Option<String>,
}

/// Port interface for remote sync operations
#[async_trait]
pub trait SyncPort: Send + Sync {
    /// Configure the remote connection
    async fn configure(&self, server_url: &str, username: &str, access_token: &str) -> SyncResult<()>;
    
    /// List contents of a remote directory
    async fn list_directory(&self, path: &str) -> SyncResult<Vec<RemoteItem>>;
    
    /// Get metadata for a single item
    async fn get_item(&self, path: &str) -> SyncResult<RemoteItem>;
    
    /// Download a file
    async fn download(
        &self,
        remote_path: &str,
        local_path: &str,
        progress_callback: Option<Box<dyn Fn(u64, u64) + Send + Sync>>,
    ) -> SyncResult<()>;
    
    /// Upload a file
    async fn upload(
        &self,
        local_path: &str,
        remote_path: &str,
        progress_callback: Option<Box<dyn Fn(u64, u64) + Send + Sync>>,
    ) -> SyncResult<String>; // Returns ETag
    
    /// Create a directory
    async fn create_directory(&self, path: &str) -> SyncResult<()>;
    
    /// Delete an item (file or directory)
    async fn delete(&self, path: &str) -> SyncResult<()>;
    
    /// Move/rename an item
    async fn move_item(&self, from_path: &str, to_path: &str) -> SyncResult<()>;
    
    /// Copy an item
    async fn copy(&self, from_path: &str, to_path: &str) -> SyncResult<()>;
    
    /// Check if item exists
    async fn exists(&self, path: &str) -> SyncResult<bool>;
    
    /// Get server quota information
    async fn get_quota(&self) -> SyncResult<(u64, u64)>; // (used, total)
    
    /// Check if server supports delta sync
    async fn supports_delta_sync(&self) -> bool;
    
    /// Upload delta (for large files)
    async fn upload_delta(
        &self,
        local_path: &str,
        remote_path: &str,
        base_checksum: &str,
    ) -> SyncResult<String>;
}
