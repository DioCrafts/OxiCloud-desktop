use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FileTypeDto {
    File,
    Directory,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncStatusDto {
    Synced,
    Syncing,
    PendingUpload,
    PendingDownload,
    Error,
    Conflicted,
    Ignored,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileDto {
    pub id: String,
    pub name: String,
    pub path: String,
    pub file_type: FileTypeDto,
    pub size: u64,
    pub mime_type: Option<String>,
    pub parent_id: Option<String>,
    pub created_at: DateTime<Utc>,
    pub modified_at: DateTime<Utc>,
    pub sync_status: SyncStatusDto,
    pub is_favorite: bool,
    pub local_path: Option<String>,
}

impl FileDto {
    pub fn is_directory(&self) -> bool {
        matches!(self.file_type, FileTypeDto::Directory)
    }
    
    pub fn extension(&self) -> Option<&str> {
        if self.is_directory() {
            return None;
        }
        self.name.split('.').last()
    }
    
    pub fn formatted_size(&self) -> String {
        if self.is_directory() {
            return "Folder".to_string();
        }
        format_bytes(self.size)
    }
    
    pub fn formatted_date(&self) -> String {
        self.modified_at.format("%b %d, %Y %H:%M").to_string()
    }
    
    pub fn is_pending_sync(&self) -> bool {
        matches!(self.sync_status, 
            SyncStatusDto::PendingUpload | 
            SyncStatusDto::PendingDownload | 
            SyncStatusDto::Syncing)
    }
    
    pub fn has_error(&self) -> bool {
        matches!(self.sync_status, 
            SyncStatusDto::Error | 
            SyncStatusDto::Conflicted)
    }
}

fn format_bytes(bytes: u64) -> String {
    const KB: u64 = 1024;
    const MB: u64 = KB * 1024;
    const GB: u64 = MB * 1024;
    const TB: u64 = GB * 1024;
    
    if bytes < KB {
        format!("{} B", bytes)
    } else if bytes < MB {
        format!("{:.1} KB", bytes as f64 / KB as f64)
    } else if bytes < GB {
        format!("{:.1} MB", bytes as f64 / MB as f64)
    } else if bytes < TB {
        format!("{:.1} GB", bytes as f64 / GB as f64)
    } else {
        format!("{:.1} TB", bytes as f64 / TB as f64)
    }
}
