use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserDto {
    pub id: String,
    pub username: String,
    pub email: String,
    pub role: String,
    pub storage_quota_bytes: i64,
    pub storage_used_bytes: i64,
    pub server_url: String,
    pub last_login_at: Option<DateTime<Utc>>,
}

impl UserDto {
    pub fn new(
        id: String,
        username: String,
        email: String,
        role: String,
        storage_quota_bytes: i64,
        storage_used_bytes: i64,
        server_url: String,
        last_login_at: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            id,
            username,
            email,
            role,
            storage_quota_bytes,
            storage_used_bytes,
            server_url,
            last_login_at,
        }
    }
    
    pub fn storage_usage_percentage(&self) -> f64 {
        if self.storage_quota_bytes <= 0 {
            return 0.0;
        }
        
        (self.storage_used_bytes as f64 / self.storage_quota_bytes as f64) * 100.0
    }
    
    pub fn formatted_storage_used(&self) -> String {
        format_bytes(self.storage_used_bytes as u64)
    }
    
    pub fn formatted_storage_quota(&self) -> String {
        format_bytes(self.storage_quota_bytes as u64)
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
