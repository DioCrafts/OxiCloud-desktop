use async_trait::async_trait;
use std::sync::Arc;
use std::path::PathBuf;

use crate::application::ports::config_port::ConfigPort;
use crate::domain::services::config_service::ConfigService;
use crate::domain::entities::config::{
    ApplicationConfig, ConfigResult, Theme, SyncMode, UpdateCheck,
};

/// Implementation of the ConfigPort
pub struct ConfigApplicationService {
    config_service: Arc<dyn ConfigService>,
}

impl ConfigApplicationService {
    pub fn new(config_service: Arc<dyn ConfigService>) -> Self {
        Self { config_service }
    }
}

#[async_trait]
impl ConfigPort for ConfigApplicationService {
    async fn get_config(&self) -> ConfigResult<ApplicationConfig> {
        self.config_service.get_config().await
    }
    
    async fn save_config(&self, config: &ApplicationConfig) -> ConfigResult<()> {
        self.config_service.save_config(config).await
    }
    
    async fn get_theme(&self) -> ConfigResult<Theme> {
        self.config_service.get_theme().await
    }
    
    async fn set_theme(&self, theme: Theme) -> ConfigResult<()> {
        self.config_service.set_theme(theme).await
    }
    
    async fn get_sync_folder(&self) -> ConfigResult<PathBuf> {
        self.config_service.get_sync_folder().await
    }
    
    async fn set_sync_folder(&self, path: &PathBuf) -> ConfigResult<()> {
        self.config_service.set_sync_folder(path).await
    }
    
    async fn set_server_url(&self, url: &str) -> ConfigResult<()> {
        self.config_service.set_server_url(url).await
    }
    
    async fn config_exists(&self) -> bool {
        self.config_service.config_exists().await
    }
    
    async fn create_default_config(&self) -> ConfigResult<ApplicationConfig> {
        self.config_service.create_default_config().await
    }
    
    async fn configure_auto_startup(&self, enabled: bool) -> ConfigResult<()> {
        // Get current config
        let mut config = self.config_service.get_config().await?;
        
        // Update setting
        if enabled {
            config.ui.start_minimized = true;
        }
        
        // Save config
        self.config_service.save_config(&config).await?;
        
        // Platform-specific auto-startup configuration
        // This is a simplified implementation
        #[cfg(target_os = "windows")]
        {
            // On Windows, we would use the registry to add autostart entry
            // For simplicity, we're just updating the config here
        }
        
        #[cfg(target_os = "macos")]
        {
            // On macOS, we would add to login items
            // For simplicity, we're just updating the config here
        }
        
        #[cfg(target_os = "linux")]
        {
            // On Linux, we would create a .desktop file in autostart directory
            // For simplicity, we're just updating the config here
        }
        
        Ok(())
    }
    
    async fn set_bandwidth_limits(&self, upload_limit: u32, download_limit: u32) -> ConfigResult<()> {
        let mut config = self.config_service.get_config().await?;
        
        config.network.upload_limit = upload_limit;
        config.network.download_limit = download_limit;
        config.network.rate_limiting = upload_limit > 0 || download_limit > 0;
        
        self.config_service.save_config(&config).await
    }
    
    async fn set_sync_mode(&self, mode: SyncMode) -> ConfigResult<()> {
        let mut config = self.config_service.get_config().await?;
        
        config.sync.mode = mode;
        
        self.config_service.save_config(&config).await
    }
    
    async fn get_performance_settings(&self) -> ConfigResult<(u8, u8, u32, bool, u8)> {
        let config = self.config_service.get_config().await?;
        
        Ok((
            config.performance.upload_threads,
            config.performance.download_threads,
            config.performance.chunk_size,
            config.performance.parallel_encryption,
            config.performance.max_parallel_encryption,
        ))
    }
    
    async fn set_performance_settings(
        &self, 
        upload_threads: u8, 
        download_threads: u8, 
        chunk_size: u32,
        parallel_encryption: bool,
        max_parallel_encryption: u8
    ) -> ConfigResult<()> {
        let mut config = self.config_service.get_config().await?;
        
        config.performance.upload_threads = upload_threads;
        config.performance.download_threads = download_threads;
        config.performance.chunk_size = chunk_size;
        config.performance.parallel_encryption = parallel_encryption;
        config.performance.max_parallel_encryption = max_parallel_encryption;
        
        self.config_service.save_config(&config).await
    }
}