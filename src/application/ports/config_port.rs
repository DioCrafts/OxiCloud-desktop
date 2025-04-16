use async_trait::async_trait;
use std::path::PathBuf;

use crate::domain::entities::config::{
    ApplicationConfig, ConfigResult, Theme, SyncMode, UpdateCheck,
};

/// Application port for configuration
#[async_trait]
pub trait ConfigPort: Send + Sync + 'static {
    /// Get the current configuration
    async fn get_config(&self) -> ConfigResult<ApplicationConfig>;
    
    /// Save the configuration
    async fn save_config(&self, config: &ApplicationConfig) -> ConfigResult<()>;
    
    /// Get the theme
    async fn get_theme(&self) -> ConfigResult<Theme>;
    
    /// Set the theme
    async fn set_theme(&self, theme: Theme) -> ConfigResult<()>;
    
    /// Get sync folder path
    async fn get_sync_folder(&self) -> ConfigResult<PathBuf>;
    
    /// Set sync folder path
    async fn set_sync_folder(&self, path: &PathBuf) -> ConfigResult<()>;
    
    /// Update server URL
    async fn set_server_url(&self, url: &str) -> ConfigResult<()>;
    
    /// Check if a configuration exists
    async fn config_exists(&self) -> bool;
    
    /// Create default configuration
    async fn create_default_config(&self) -> ConfigResult<ApplicationConfig>;
    
    /// Configure automatic startup
    async fn configure_auto_startup(&self, enabled: bool) -> ConfigResult<()>;
    
    /// Set network bandwidth limits
    async fn set_bandwidth_limits(&self, upload_limit: u32, download_limit: u32) -> ConfigResult<()>;
    
    /// Set sync mode
    async fn set_sync_mode(&self, mode: SyncMode) -> ConfigResult<()>;
    
    /// Get performance settings
    async fn get_performance_settings(&self) -> ConfigResult<(u8, u8, u32, bool, u8)>;
    
    /// Set performance settings
    async fn set_performance_settings(
        &self, 
        upload_threads: u8, 
        download_threads: u8, 
        chunk_size: u32,
        parallel_encryption: bool,
        max_parallel_encryption: u8
    ) -> ConfigResult<()>;
}