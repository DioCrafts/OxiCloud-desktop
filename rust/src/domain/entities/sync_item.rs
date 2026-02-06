//! # SyncItem Entity
//!
//! Represents a file or folder that can be synchronized between
//! local storage and the OxiCloud server.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use flutter_rust_bridge::frb;

/// Represents a syncable item (file or folder)
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SyncItem {
    /// Unique identifier
    pub id: String,
    
    /// Relative path from sync root
    pub path: String,
    
    /// File name
    pub name: String,
    
    /// Whether this is a directory
    pub is_directory: bool,
    
    /// File size in bytes (0 for directories)
    pub size: u64,
    
    /// Content hash (for change detection)
    pub content_hash: Option<String>,
    
    /// Local modification time
    pub local_modified: Option<DateTime<Utc>>,
    
    /// Remote modification time  
    pub remote_modified: Option<DateTime<Utc>>,
    
    /// Current sync status
    pub status: SyncStatus,
    
    /// Sync direction
    pub direction: SyncDirection,
    
    /// ETag from server (for efficient sync)
    pub etag: Option<String>,
    
    /// MIME type
    pub mime_type: Option<String>,
}

impl SyncItem {
    /// Create a new SyncItem for a local file
    pub fn from_local(
        path: String,
        name: String,
        is_directory: bool,
        size: u64,
        modified: DateTime<Utc>,
        content_hash: Option<String>,
    ) -> Self {
        Self {
            id: uuid::Uuid::new_v4().to_string(),
            path,
            name,
            is_directory,
            size,
            content_hash,
            local_modified: Some(modified),
            remote_modified: None,
            status: SyncStatus::Pending,
            direction: SyncDirection::Upload,
            etag: None,
            mime_type: None,
        }
    }
    
    /// Create a new SyncItem from remote metadata
    pub fn from_remote(
        id: String,
        path: String,
        name: String,
        is_directory: bool,
        size: u64,
        modified: DateTime<Utc>,
        etag: Option<String>,
        mime_type: Option<String>,
    ) -> Self {
        Self {
            id,
            path,
            name,
            is_directory,
            size,
            content_hash: None,
            local_modified: None,
            remote_modified: Some(modified),
            status: SyncStatus::Pending,
            direction: SyncDirection::Download,
            etag,
            mime_type,
        }
    }
    
    /// Check if item needs syncing
    pub fn needs_sync(&self) -> bool {
        matches!(self.status, SyncStatus::Pending | SyncStatus::Error(_))
    }
    
    /// Check if there's a conflict
    pub fn has_conflict(&self) -> bool {
        matches!(self.status, SyncStatus::Conflict(_))
    }
    
    /// Get the newer modified time
    pub fn newer_modified(&self) -> Option<DateTime<Utc>> {
        match (self.local_modified, self.remote_modified) {
            (Some(local), Some(remote)) => Some(if local > remote { local } else { remote }),
            (Some(local), None) => Some(local),
            (None, Some(remote)) => Some(remote),
            (None, None) => None,
        }
    }
}

/// Sync status of an item
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum SyncStatus {
    /// Item is in sync
    Synced,
    /// Item needs to be synced
    Pending,
    /// Item is currently being synced
    Syncing,
    /// Item has a conflict
    Conflict(ConflictInfo),
    /// Sync error occurred
    Error(String),
    /// Item is ignored
    Ignored,
}

/// Sync direction
#[frb]
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum SyncDirection {
    /// Upload to server
    Upload,
    /// Download from server
    Download,
    /// No sync needed
    None,
}

/// Conflict information
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ConflictInfo {
    pub conflict_type: ConflictType,
    pub detected_at: DateTime<Utc>,
}

/// Type of conflict
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum ConflictType {
    /// Both local and remote were modified
    BothModified,
    /// Deleted locally but modified remotely
    DeletedLocally,
    /// Modified locally but deleted remotely
    DeletedRemotely,
    /// File vs folder type mismatch
    TypeMismatch,
}

/// Conflict resolution strategy
#[frb]
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
pub enum ConflictResolution {
    /// Keep local version
    KeepLocal,
    /// Keep remote version
    KeepRemote,
    /// Keep both (rename local)
    KeepBoth,
    /// Skip this item
    Skip,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_sync_item_from_local() {
        let item = SyncItem::from_local(
            "/documents/test.txt".to_string(),
            "test.txt".to_string(),
            false,
            1024,
            Utc::now(),
            Some("abc123".to_string()),
        );
        
        assert!(!item.is_directory);
        assert_eq!(item.size, 1024);
        assert_eq!(item.direction, SyncDirection::Upload);
        assert!(item.needs_sync());
    }
    
    #[test]
    fn test_sync_item_conflict() {
        let mut item = SyncItem::from_local(
            "/test.txt".to_string(),
            "test.txt".to_string(),
            false,
            100,
            Utc::now(),
            None,
        );
        
        item.status = SyncStatus::Conflict(ConflictInfo {
            conflict_type: ConflictType::BothModified,
            detected_at: Utc::now(),
        });
        
        assert!(item.has_conflict());
    }
}
