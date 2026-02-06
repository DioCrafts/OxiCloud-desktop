//! # Sync Status Entity
//!
//! Global sync status and statistics for the sync engine.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use flutter_rust_bridge::frb;

/// Overall sync engine status
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum EngineStatus {
    /// Sync engine is idle
    Idle,
    /// Sync is in progress
    Syncing,
    /// Sync is paused
    Paused,
    /// Sync has errors
    Error(String),
    /// Offline mode
    Offline,
}

/// Detailed sync statistics
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SyncStats {
    /// Total files tracked
    pub total_files: u64,
    
    /// Total folders tracked
    pub total_folders: u64,
    
    /// Total size in bytes
    pub total_size: u64,
    
    /// Files pending upload
    pub pending_uploads: u32,
    
    /// Files pending download
    pub pending_downloads: u32,
    
    /// Active conflicts
    pub conflicts: u32,
    
    /// Files with errors
    pub errors: u32,
    
    /// Last successful sync time
    pub last_sync: Option<DateTime<Utc>>,
    
    /// Next scheduled sync time
    pub next_sync: Option<DateTime<Utc>>,
    
    /// Bytes uploaded this session
    pub bytes_uploaded: u64,
    
    /// Bytes downloaded this session
    pub bytes_downloaded: u64,
}

impl SyncStats {
    /// Update stats after a sync operation
    pub fn record_sync(&mut self, uploaded: u64, downloaded: u64) {
        self.bytes_uploaded += uploaded;
        self.bytes_downloaded += downloaded;
        self.last_sync = Some(Utc::now());
    }
    
    /// Check if there are pending operations
    pub fn has_pending(&self) -> bool {
        self.pending_uploads > 0 || self.pending_downloads > 0
    }
    
    /// Check if sync is healthy
    pub fn is_healthy(&self) -> bool {
        self.errors == 0 && self.conflicts == 0
    }
}

/// Sync progress information
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncProgress {
    /// Current operation description
    pub operation: String,
    
    /// Current item path
    pub current_item: Option<String>,
    
    /// Items completed
    pub items_done: u32,
    
    /// Total items to sync
    pub items_total: u32,
    
    /// Bytes transferred
    pub bytes_done: u64,
    
    /// Total bytes to transfer
    pub bytes_total: u64,
    
    /// Current transfer speed (bytes/sec)
    pub speed: u64,
    
    /// Estimated time remaining (seconds)
    pub eta_seconds: Option<u32>,
}

impl SyncProgress {
    /// Calculate progress percentage
    pub fn percent(&self) -> f32 {
        if self.items_total == 0 {
            return 100.0;
        }
        (self.items_done as f32 / self.items_total as f32) * 100.0
    }
    
    /// Calculate bytes progress percentage
    pub fn bytes_percent(&self) -> f32 {
        if self.bytes_total == 0 {
            return 100.0;
        }
        (self.bytes_done as f64 / self.bytes_total as f64 * 100.0) as f32
    }
    
    /// Format speed for display
    pub fn speed_formatted(&self) -> String {
        format_bytes_per_sec(self.speed)
    }
    
    /// Format ETA for display
    pub fn eta_formatted(&self) -> String {
        match self.eta_seconds {
            Some(secs) if secs < 60 => format!("{}s", secs),
            Some(secs) if secs < 3600 => format!("{}m {}s", secs / 60, secs % 60),
            Some(secs) => format!("{}h {}m", secs / 3600, (secs % 3600) / 60),
            None => "calculating...".to_string(),
        }
    }
}

/// Format bytes per second for display
fn format_bytes_per_sec(bps: u64) -> String {
    if bps < 1024 {
        format!("{} B/s", bps)
    } else if bps < 1024 * 1024 {
        format!("{:.1} KB/s", bps as f64 / 1024.0)
    } else if bps < 1024 * 1024 * 1024 {
        format!("{:.1} MB/s", bps as f64 / (1024.0 * 1024.0))
    } else {
        format!("{:.1} GB/s", bps as f64 / (1024.0 * 1024.0 * 1024.0))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_sync_progress_percent() {
        let progress = SyncProgress {
            operation: "Uploading".to_string(),
            current_item: Some("/test.txt".to_string()),
            items_done: 5,
            items_total: 10,
            bytes_done: 500,
            bytes_total: 1000,
            speed: 100,
            eta_seconds: Some(5),
        };
        
        assert_eq!(progress.percent(), 50.0);
        assert_eq!(progress.bytes_percent(), 50.0);
    }
    
    #[test]
    fn test_speed_formatting() {
        assert_eq!(format_bytes_per_sec(500), "500 B/s");
        assert_eq!(format_bytes_per_sec(1500), "1.5 KB/s");
        assert_eq!(format_bytes_per_sec(1500000), "1.4 MB/s");
    }
}
