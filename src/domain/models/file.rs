use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Represents a file in the system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct File {
    /// Unique identifier for the file
    pub id: String,
    
    /// Name of the file
    pub name: String,
    
    /// Path to the file from the root
    pub path: String,
    
    /// MIME type of the file
    pub mime_type: String,
    
    /// Size of the file in bytes
    pub size: u64,
    
    /// When the file was created
    pub created_at: DateTime<Utc>,
    
    /// When the file was last modified
    pub modified_at: DateTime<Utc>,
    
    /// ETag for change detection
    pub etag: String,
    
    /// Path to the cached file on local system
    pub local_path: Option<String>,
    
    /// Whether the file has been modified locally
    pub is_modified_locally: bool,
    
    /// Whether the file is a favorite
    pub is_favorite: bool,
    
    /// Whether the file is shared
    pub is_shared: bool,
    
    /// Parent folder ID
    pub parent_id: String,
}

impl File {
    /// Create a new File instance
    pub fn new(id: String, name: String, path: String, parent_id: String) -> Self {
        let now = Utc::now();
        
        Self {
            id,
            name,
            path,
            mime_type: "application/octet-stream".to_string(),
            size: 0,
            created_at: now,
            modified_at: now,
            etag: Uuid::new_v4().to_string(),
            local_path: None,
            is_modified_locally: false,
            is_favorite: false,
            is_shared: false,
            parent_id,
        }
    }
    
    /// Check if the file is locally cached
    pub fn is_cached(&self) -> bool {
        self.local_path.is_some()
    }
    
    /// Get file extension
    pub fn extension(&self) -> Option<&str> {
        self.name.split('.').last()
    }
    
    /// Check if this is an image file
    pub fn is_image(&self) -> bool {
        self.mime_type.starts_with("image/")
    }
    
    /// Check if this is a text file
    pub fn is_text(&self) -> bool {
        self.mime_type.starts_with("text/")
    }
    
    /// Check if this is a video file
    pub fn is_video(&self) -> bool {
        self.mime_type.starts_with("video/")
    }
    
    /// Check if this is an audio file
    pub fn is_audio(&self) -> bool {
        self.mime_type.starts_with("audio/")
    }
}