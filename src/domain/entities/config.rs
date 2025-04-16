use serde::{Serialize, Deserialize};
use std::path::PathBuf;
use thiserror::Error;

/// Errors that can occur during configuration operations
#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("IO error: {0}")]
    IOError(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(String),
    
    #[error("Invalid configuration: {0}")]
    InvalidConfig(String),
}

pub type ConfigResult<T> = Result<T, ConfigError>;

/// Application theme
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Theme {
    /// Light theme (default)
    Light,
    /// Dark theme
    Dark,
    /// System theme (follows OS)
    System,
}

impl Default for Theme {
    fn default() -> Self {
        Self::System
    }
}

/// Network configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NetworkConfig {
    /// Upload bandwidth limit in KB/s (0 = unlimited)
    pub upload_limit: u32,
    /// Download bandwidth limit in KB/s (0 = unlimited)
    pub download_limit: u32,
    /// Proxy URL if needed
    pub proxy_url: Option<String>,
    /// Rate limiting enabled
    pub rate_limiting: bool,
}

impl Default for NetworkConfig {
    fn default() -> Self {
        Self {
            upload_limit: 0,
            download_limit: 0,
            proxy_url: None,
            rate_limiting: false,
        }
    }
}

/// Synchronization configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConfig {
    /// Synchronization enabled
    pub enabled: bool,
    /// Synchronization interval in seconds
    pub interval: u32,
    /// Synchronization mode (automatic, manual, scheduled)
    pub mode: SyncMode,
    /// Pause synchronization on metered connections
    pub pause_on_metered: bool,
    /// Synchronization folder path
    pub sync_folder: Option<PathBuf>,
    /// Excluded patterns (glob patterns, e.g. "*.tmp")
    pub excluded_patterns: Vec<String>,
    /// Selective sync enabled
    pub selective_sync: bool,
    /// Maximum file size for sync in MB (0 = unlimited)
    pub max_file_size: u32,
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            interval: 300, // 5 minutes
            mode: SyncMode::Automatic,
            pause_on_metered: true,
            sync_folder: None, // Will be set to ~/OxiCloud by default in the service
            excluded_patterns: vec![
                "*.tmp".to_string(),
                "*.temp".to_string(),
                "Thumbs.db".to_string(),
                ".DS_Store".to_string(),
            ],
            selective_sync: false,
            max_file_size: 0, // Unlimited
        }
    }
}

/// Synchronization mode
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncMode {
    /// Automatic syncing
    Automatic,
    /// Manual syncing (user-initiated)
    Manual,
    /// Scheduled syncing
    Scheduled,
}

/// Performance configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PerformanceConfig {
    /// Number of upload threads
    pub upload_threads: u8,
    /// Number of download threads
    pub download_threads: u8,
    /// Chunk size for large file uploads in MB
    pub chunk_size: u32,
    /// Enable parallel processing for encryption/decryption
    pub parallel_encryption: bool,
    /// Maximum parallel encryption/decryption operations
    pub max_parallel_encryption: u8,
}

impl Default for PerformanceConfig {
    fn default() -> Self {
        Self {
            upload_threads: 4,
            download_threads: 4,
            chunk_size: 4,
            parallel_encryption: true,
            max_parallel_encryption: 8,
        }
    }
}

/// UI preferences
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UIConfig {
    /// Theme (light, dark, system)
    pub theme: Theme,
    /// Show file sizes in binary (KiB, MiB) or decimal (KB, MB)
    pub binary_sizes: bool,
    /// Show notifications for sync events
    pub notifications: bool,
    /// Start application minimized
    pub start_minimized: bool,
    /// Minimize to tray when closed
    pub minimize_to_tray: bool,
    /// Update check frequency
    pub update_check: UpdateCheck,
    /// Use system file dialog
    pub use_system_dialog: bool,
}

impl Default for UIConfig {
    fn default() -> Self {
        Self {
            theme: Theme::default(),
            binary_sizes: true,
            notifications: true,
            start_minimized: false,
            minimize_to_tray: true,
            update_check: UpdateCheck::Daily,
            use_system_dialog: true,
        }
    }
}

/// Update check frequency
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum UpdateCheck {
    /// Never check for updates
    Never,
    /// Check for updates daily
    Daily,
    /// Check for updates weekly
    Weekly,
    /// Check for updates monthly
    Monthly,
}

/// Advanced configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AdvancedConfig {
    /// Enable debug logging
    pub debug_logging: bool,
    /// Maximum log file size in MB
    pub log_file_size: u32,
    /// Number of log files to keep
    pub log_file_count: u32,
    /// Custom server certificates
    pub custom_certificates: Vec<String>,
    /// Enable crash reporting
    pub crash_reporting: bool,
    /// Enable usage statistics
    pub usage_statistics: bool,
}

impl Default for AdvancedConfig {
    fn default() -> Self {
        Self {
            debug_logging: false,
            log_file_size: 10,
            log_file_count: 5,
            custom_certificates: Vec::new(),
            crash_reporting: true,
            usage_statistics: false,
        }
    }
}

/// Main application configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ApplicationConfig {
    /// Configuration version
    pub version: u8,
    /// Server URL
    pub server_url: Option<String>,
    /// Username (email)
    pub username: Option<String>,
    /// Network configuration
    pub network: NetworkConfig,
    /// Synchronization configuration
    pub sync: SyncConfig,
    /// UI preferences
    pub ui: UIConfig,
    /// Performance configuration
    pub performance: PerformanceConfig,
    /// Advanced configuration
    pub advanced: AdvancedConfig,
}

impl Default for ApplicationConfig {
    fn default() -> Self {
        Self {
            version: 1,
            server_url: None,
            username: None,
            network: NetworkConfig::default(),
            sync: SyncConfig::default(),
            ui: UIConfig::default(),
            performance: PerformanceConfig::default(),
            advanced: AdvancedConfig::default(),
        }
    }
}

/// Configuration trait
pub trait ConfigRepository: Send + Sync + 'static {
    /// Load configuration from storage
    fn load_config(&self) -> ConfigResult<ApplicationConfig>;
    
    /// Save configuration to storage
    fn save_config(&self, config: &ApplicationConfig) -> ConfigResult<()>;
    
    /// Get default configuration file path
    fn get_config_path(&self) -> PathBuf;
}