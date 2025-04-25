use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Represents a folder in the system
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Folder {
    /// Unique identifier for the folder
    pub id: String,
    
    /// Name of the folder
    pub name: String,
    
    /// Path to the folder from the root
    pub path: String,
    
    /// When the folder was created
    pub created_at: DateTime<Utc>,
    
    /// When the folder was last modified
    pub modified_at: DateTime<Utc>,
    
    /// ETag for change detection
    pub etag: String,
    
    /// Whether the folder is a favorite
    pub is_favorite: bool,
    
    /// Whether the folder is shared
    pub is_shared: bool,
    
    /// Parent folder ID (None for root folder)
    pub parent_id: Option<String>,
    
    /// Child folders IDs
    pub children_folders: Vec<String>,
    
    /// Child files IDs
    pub children_files: Vec<String>,
}

impl Folder {
    /// Create a new folder
    pub fn new(id: String, name: String, path: String, parent_id: Option<String>) -> Self {
        let now = Utc::now();
        
        Self {
            id,
            name,
            path,
            created_at: now,
            modified_at: now,
            etag: Uuid::new_v4().to_string(),
            is_favorite: false,
            is_shared: false,
            parent_id,
            children_folders: Vec::new(),
            children_files: Vec::new(),
        }
    }
    
    /// Check if this is the root folder
    pub fn is_root(&self) -> bool {
        self.parent_id.is_none()
    }
    
    /// Add a child folder ID
    pub fn add_folder(&mut self, folder_id: String) {
        if !self.children_folders.contains(&folder_id) {
            self.children_folders.push(folder_id);
            self.modified_at = Utc::now();
            self.etag = Uuid::new_v4().to_string();
        }
    }
    
    /// Add a child file ID
    pub fn add_file(&mut self, file_id: String) {
        if !self.children_files.contains(&file_id) {
            self.children_files.push(file_id);
            self.modified_at = Utc::now();
            self.etag = Uuid::new_v4().to_string();
        }
    }
    
    /// Remove a child folder ID
    pub fn remove_folder(&mut self, folder_id: &str) {
        self.children_folders.retain(|id| id != folder_id);
        self.modified_at = Utc::now();
        self.etag = Uuid::new_v4().to_string();
    }
    
    /// Remove a child file ID
    pub fn remove_file(&mut self, file_id: &str) {
        self.children_files.retain(|id| id != file_id);
        self.modified_at = Utc::now();
        self.etag = Uuid::new_v4().to_string();
    }
    
    /// Check if the folder has any children
    pub fn is_empty(&self) -> bool {
        self.children_folders.is_empty() && self.children_files.is_empty()
    }
}