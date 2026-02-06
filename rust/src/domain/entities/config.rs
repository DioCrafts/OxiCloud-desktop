//! # Configuration Entity
//!
//! Sync engine configuration options.

use serde::{Deserialize, Serialize};
use flutter_rust_bridge::frb;

/// Sync engine configuration
#[frb]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConfig {
    /// Path to local sync folder
    pub sync_folder: String,
    
    /// Path to SQLite database file
    pub database_path: String,
    
    /// Sync interval in seconds (0 = manual only)
    pub sync_interval_seconds: u32,
    
    /// Maximum upload speed in KB/s (0 = unlimited)
    pub max_upload_speed_kbps: u32,
    
    /// Maximum download speed in KB/s (0 = unlimited)
    pub max_download_speed_kbps: u32,
    
    /// Enable delta sync for large files
    pub delta_sync_enabled: bool,
    
    /// Minimum file size for delta sync (bytes)
    pub delta_sync_min_size: u64,
    
    /// Pause sync on metered connections
    pub pause_on_metered: bool,
    
    /// Only sync on Wi-Fi (mobile)
    pub wifi_only: bool,
    
    /// Enable file system watcher for instant sync
    pub watch_filesystem: bool,
    
    /// Ignore patterns (glob)
    pub ignore_patterns: Vec<String>,
    
    /// Show desktop notifications
    pub notifications_enabled: bool,
    
    /// Launch on system startup
    pub launch_at_startup: bool,
    
    /// Minimize to tray on close (desktop)
    pub minimize_to_tray: bool,
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self {
            sync_folder: String::new(),
            database_path: String::new(),
            sync_interval_seconds: 300, // 5 minutes
            max_upload_speed_kbps: 0,   // unlimited
            max_download_speed_kbps: 0, // unlimited
            delta_sync_enabled: true,
            delta_sync_min_size: 10 * 1024 * 1024, // 10MB
            pause_on_metered: true,
            wifi_only: false,
            watch_filesystem: true,
            ignore_patterns: default_ignore_patterns(),
            notifications_enabled: true,
            launch_at_startup: false,
            minimize_to_tray: true,
        }
    }
}

/// Default ignore patterns
fn default_ignore_patterns() -> Vec<String> {
    vec![
        // System files
        ".DS_Store".to_string(),
        "Thumbs.db".to_string(),
        "desktop.ini".to_string(),
        "*.tmp".to_string(),
        "*.temp".to_string(),
        "~*".to_string(),
        "*.swp".to_string(),
        "*.swo".to_string(),
        
        // Hidden files
        ".*".to_string(),
        
        // IDE/Editor
        ".idea/**".to_string(),
        ".vscode/**".to_string(),
        "*.sublime-*".to_string(),
        
        // Build outputs
        "node_modules/**".to_string(),
        "target/**".to_string(),
        "build/**".to_string(),
        "dist/**".to_string(),
        "__pycache__/**".to_string(),
        "*.pyc".to_string(),
        
        // Logs
        "*.log".to_string(),
        "logs/**".to_string(),
    ]
}

impl SyncConfig {
    /// Create config with default ignore patterns
    pub fn new(sync_folder: String, database_path: String) -> Self {
        Self {
            sync_folder,
            database_path,
            ..Default::default()
        }
    }
    
    /// Validate configuration
    pub fn validate(&self) -> Result<(), String> {
        if self.sync_folder.is_empty() {
            return Err("Sync folder path is required".to_string());
        }
        
        if self.database_path.is_empty() {
            return Err("Database path is required".to_string());
        }
        
        Ok(())
    }
    
    /// Check if a path should be ignored
    pub fn should_ignore(&self, path: &str) -> bool {
        for pattern in &self.ignore_patterns {
            if matches_glob(pattern, path) {
                return true;
            }
        }
        false
    }
    
    /// Get upload speed limit in bytes/sec (0 = unlimited)
    pub fn upload_speed_limit(&self) -> u64 {
        self.max_upload_speed_kbps as u64 * 1024
    }
    
    /// Get download speed limit in bytes/sec (0 = unlimited)
    pub fn download_speed_limit(&self) -> u64 {
        self.max_download_speed_kbps as u64 * 1024
    }
}

/// Simple glob matching (supports * and **)
fn matches_glob(pattern: &str, path: &str) -> bool {
    // Simplified glob matching - in production use a proper glob crate
    if pattern.contains("**") {
        let prefix = pattern.split("**").next().unwrap_or("");
        return path.starts_with(prefix.trim_end_matches('/'));
    }
    
    if pattern.starts_with("*.") {
        let ext = &pattern[1..];
        return path.ends_with(ext);
    }
    
    if pattern.starts_with("*") {
        return path.contains(&pattern[1..]);
    }
    
    path.contains(pattern)
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_default_config() {
        let config = SyncConfig::default();
        assert_eq!(config.sync_interval_seconds, 300);
        assert!(config.delta_sync_enabled);
        assert!(config.notifications_enabled);
    }
    
    #[test]
    fn test_should_ignore() {
        let config = SyncConfig::default();
        
        assert!(config.should_ignore(".DS_Store"));
        assert!(config.should_ignore("file.tmp"));
        assert!(config.should_ignore(".git/config"));
        assert!(!config.should_ignore("document.pdf"));
    }
    
    #[test]
    fn test_speed_limits() {
        let mut config = SyncConfig::default();
        config.max_upload_speed_kbps = 1000; // 1 MB/s
        
        assert_eq!(config.upload_speed_limit(), 1024000);
    }
}
