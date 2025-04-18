use async_trait::async_trait;
use std::sync::Arc;
use std::path::PathBuf;

use crate::domain::entities::config::{
    ApplicationConfig, ConfigResult, Theme, SyncMode, UpdateCheck,
};
use crate::domain::entities::config::ConfigRepository;

/// Service for managing application configuration
#[async_trait]
pub trait ConfigService: Send + Sync + 'static {
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
}

/// Implementation of the ConfigService
pub struct ConfigServiceImpl {
    repository: Arc<dyn ConfigRepository>,
}

impl ConfigServiceImpl {
    pub fn new(repository: Arc<dyn ConfigRepository>) -> Self {
        Self { repository }
    }
}

#[async_trait]
impl ConfigService for ConfigServiceImpl {
    async fn get_config(&self) -> ConfigResult<ApplicationConfig> {
        self.repository.load_config()
    }
    
    async fn save_config(&self, config: &ApplicationConfig) -> ConfigResult<()> {
        self.repository.save_config(config)
    }
    
    async fn get_theme(&self) -> ConfigResult<Theme> {
        let config = self.repository.load_config()?;
        Ok(config.ui.theme)
    }
    
    async fn set_theme(&self, theme: Theme) -> ConfigResult<()> {
        let mut config = self.repository.load_config()?;
        config.ui.theme = theme;
        self.repository.save_config(&config)
    }
    
    async fn get_sync_folder(&self) -> ConfigResult<PathBuf> {
        let config = self.repository.load_config()?;
        if let Some(path) = config.sync.sync_folder {
            Ok(path)
        } else {
            // Return default path
            let home_dir = dirs::home_dir().ok_or_else(|| {
                crate::domain::entities::config::ConfigError::InvalidConfig(
                    "Could not determine home directory".to_string()
                )
            })?;
            
            Ok(home_dir.join("OxiCloud"))
        }
    }
    
    async fn set_sync_folder(&self, path: &PathBuf) -> ConfigResult<()> {
        let mut config = self.repository.load_config()?;
        config.sync.sync_folder = Some(path.clone());
        self.repository.save_config(&config)
    }
    
    async fn set_server_url(&self, url: &str) -> ConfigResult<()> {
        let mut config = self.repository.load_config()?;
        config.server_url = Some(url.to_string());
        self.repository.save_config(&config)
    }
    
    async fn config_exists(&self) -> bool {
        match self.repository.load_config() {
            Ok(_) => true,
            Err(_) => false,
        }
    }
    
    async fn create_default_config(&self) -> ConfigResult<ApplicationConfig> {
        let config = ApplicationConfig::default();
        self.repository.save_config(&config)?;
        Ok(config)
    }
}