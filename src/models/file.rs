use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum FileType {
    File,
    Directory,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileItem {
    pub id: String,
    pub name: String,
    pub path: String,
    pub file_type: FileType,
    pub size: u64,
    pub created: DateTime<Utc>,
    pub modified: DateTime<Utc>,
    pub is_favorite: bool,
    pub is_shared: bool,
    pub sync_status: FileSyncStatus,
    pub etag: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum FileSyncStatus {
    Synced,
    Pending,
    Syncing,
    Error(String),
    OutOfSync,
    Ignored,
    LocalOnly,
    RemoteOnly,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncedFile {
    pub local_path: String,
    pub remote_path: String,
    pub etag: String,
    pub last_sync: DateTime<Utc>,
    pub status: FileSyncStatus,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ShareInfo {
    pub id: String,
    pub url: String,
    pub expires: Option<DateTime<Utc>>,
    pub password_protected: bool,
    pub created: DateTime<Utc>,
}

impl FileItem {
    pub fn is_directory(&self) -> bool {
        self.file_type == FileType::Directory
    }
    
    pub fn extension(&self) -> Option<String> {
        if self.is_directory() {
            return None;
        }
        
        let parts: Vec<&str> = self.name.split('.').collect();
        if parts.len() > 1 {
            Some(parts.last().unwrap().to_string())
        } else {
            None
        }
    }
    
    pub fn mime_type(&self) -> String {
        if self.is_directory() {
            return "inode/directory".to_string();
        }
        
        if let Some(ext) = self.extension() {
            match ext.to_lowercase().as_str() {
                "pdf" => "application/pdf",
                "jpg" | "jpeg" => "image/jpeg",
                "png" => "image/png",
                "gif" => "image/gif",
                "txt" => "text/plain",
                "md" => "text/markdown",
                "html" | "htm" => "text/html",
                "css" => "text/css",
                "js" => "application/javascript",
                "json" => "application/json",
                "xml" => "application/xml",
                "zip" => "application/zip",
                "doc" | "docx" => "application/msword",
                "xls" | "xlsx" => "application/vnd.ms-excel",
                "ppt" | "pptx" => "application/vnd.ms-powerpoint",
                "mp3" => "audio/mpeg",
                "mp4" => "video/mp4",
                "webm" => "video/webm",
                "ogg" => "audio/ogg",
                _ => "application/octet-stream",
            }.to_string()
        } else {
            "application/octet-stream".to_string()
        }
    }
}