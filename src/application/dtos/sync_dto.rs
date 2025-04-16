use serde::{Serialize, Deserialize};
use std::time::Duration;
use chrono::{DateTime, Utc};

use crate::application::dtos::file_dto::FileDto;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncStateDto {
    Idle,
    Syncing,
    Paused,
    Error,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncDirectionDto {
    Upload,
    Download,
    Bidirectional,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatusDto {
    pub state: SyncStateDto,
    pub last_sync: Option<DateTime<Utc>>,
    pub current_operation: Option<String>,
    pub current_file: Option<String>,
    pub total_files: u32,
    pub processed_files: u32,
    pub total_bytes: u64,
    pub processed_bytes: u64,
    pub error_message: Option<String>,
}

impl SyncStatusDto {
    pub fn progress_percentage(&self) -> f32 {
        if self.total_files == 0 {
            return 0.0;
        }
        
        (self.processed_files as f32 / self.total_files as f32) * 100.0
    }
    
    pub fn formatted_progress(&self) -> String {
        if self.total_files == 0 {
            return "0%".to_string();
        }
        
        format!("{:.1}%", self.progress_percentage())
    }
    
    pub fn bytes_progress_percentage(&self) -> f32 {
        if self.total_bytes == 0 {
            return 0.0;
        }
        
        (self.processed_bytes as f32 / self.total_bytes as f32) * 100.0
    }
    
    pub fn formatted_bytes_progress(&self) -> String {
        format!("{}/{}", 
            format_bytes(self.processed_bytes),
            format_bytes(self.total_bytes))
    }
    
    pub fn formatted_last_sync(&self) -> String {
        match self.last_sync {
            Some(time) => time.format("%b %d, %Y %H:%M").to_string(),
            None => "Never".to_string(),
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConfigDto {
    pub enabled: bool,
    pub sync_interval_seconds: u64,
    pub sync_on_startup: bool,
    pub sync_on_file_change: bool,
    pub sync_direction: SyncDirectionDto,
    pub excluded_paths: Vec<String>,
    pub max_concurrent_transfers: u32,
    pub bandwidth_limit_kbps: Option<u32>,
    pub sync_hidden_files: bool,
    pub auto_resolve_conflicts: bool,
}

impl SyncConfigDto {
    pub fn sync_interval_minutes(&self) -> u64 {
        self.sync_interval_seconds / 60
    }
    
    pub fn set_sync_interval_minutes(&mut self, minutes: u64) {
        self.sync_interval_seconds = minutes * 60;
    }
    
    pub fn to_domain_config(&self) -> crate::domain::entities::sync::SyncConfig {
        let direction = match self.sync_direction {
            SyncDirectionDto::Upload => crate::domain::entities::sync::SyncDirection::Upload,
            SyncDirectionDto::Download => crate::domain::entities::sync::SyncDirection::Download,
            SyncDirectionDto::Bidirectional => crate::domain::entities::sync::SyncDirection::Bidirectional,
        };
        
        crate::domain::entities::sync::SyncConfig {
            enabled: self.enabled,
            sync_interval: Duration::from_secs(self.sync_interval_seconds),
            sync_on_startup: self.sync_on_startup,
            sync_on_file_change: self.sync_on_file_change,
            sync_direction: direction,
            excluded_paths: self.excluded_paths.clone(),
            max_concurrent_transfers: self.max_concurrent_transfers,
            bandwidth_limit_kbps: self.bandwidth_limit_kbps,
            sync_hidden_files: self.sync_hidden_files,
            auto_resolve_conflicts: self.auto_resolve_conflicts,
        }
    }
}

#[derive(Debug, Clone)]
pub enum SyncEventDto {
    Started,
    Progress(SyncStatusDto),
    Completed,
    Paused,
    Resumed,
    Cancelled,
    Error(String),
    FileChanged(FileDto),
    EncryptionStarted(String),   // File path being encrypted
    EncryptionCompleted(String), // File path that was encrypted  
    DecryptionStarted(String),   // File path being decrypted
    DecryptionCompleted(String), // File path that was decrypted
    EncryptionError(String),     // Error message
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
