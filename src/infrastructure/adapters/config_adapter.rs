use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};
use std::sync::Arc;

use dirs;
use serde_json;
use tracing::{info, error, debug, warn};

use crate::domain::entities::config::{
    ApplicationConfig, ConfigRepository, ConfigError, ConfigResult,
};
use crate::domain::repositories::config_repository::ConfigRepositoryFactory;

/// Implementation of ConfigRepository that saves to a JSON file
pub struct JsonConfigRepository {
    config_path: PathBuf,
}

impl JsonConfigRepository {
    pub fn new() -> Self {
        let config_path = Self::get_default_config_path();
        Self { config_path }
    }
    
    pub fn with_path(path: PathBuf) -> Self {
        Self { config_path: path }
    }
    
    fn get_default_config_path() -> PathBuf {
        // Use platform-specific config directory
        if let Some(config_dir) = dirs::config_dir() {
            let app_config_dir = config_dir.join("OxiCloud");
            
            // Create directory if it doesn't exist
            if !app_config_dir.exists() {
                if let Err(e) = fs::create_dir_all(&app_config_dir) {
                    error!("Failed to create config directory: {}", e);
                }
            }
            
            app_config_dir.join("config.json")
        } else {
            // Fallback to current directory
            PathBuf::from("oxicloud_config.json")
        }
    }
    
    /// Create parent directories if they don't exist
    fn ensure_parent_dir(&self) -> io::Result<()> {
        if let Some(parent) = self.config_path.parent() {
            if !parent.exists() {
                fs::create_dir_all(parent)?;
            }
        }
        Ok(())
    }
}

impl ConfigRepository for JsonConfigRepository {
    fn load_config(&self) -> ConfigResult<ApplicationConfig> {
        // Check if config file exists
        if !self.config_path.exists() {
            debug!("Config file not found at {:?}, creating default", self.config_path);
            let default_config = ApplicationConfig::default();
            self.save_config(&default_config)?;
            return Ok(default_config);
        }
        
        // Read file
        let mut file = fs::File::open(&self.config_path)
            .map_err(|e| ConfigError::IOError(format!("Failed to open config file: {}", e)))?;
            
        let mut contents = String::new();
        file.read_to_string(&mut contents)
            .map_err(|e| ConfigError::IOError(format!("Failed to read config file: {}", e)))?;
            
        // Parse JSON
        let config: ApplicationConfig = serde_json::from_str(&contents)
            .map_err(|e| ConfigError::SerializationError(format!("Failed to parse config: {}", e)))?;
            
        Ok(config)
    }
    
    fn save_config(&self, config: &ApplicationConfig) -> ConfigResult<()> {
        // Ensure parent directory exists
        self.ensure_parent_dir()
            .map_err(|e| ConfigError::IOError(format!("Failed to create config directory: {}", e)))?;
            
        // Serialize to JSON with pretty formatting
        let json = serde_json::to_string_pretty(config)
            .map_err(|e| ConfigError::SerializationError(format!("Failed to serialize config: {}", e)))?;
            
        // Write to file (create or overwrite)
        let mut file = fs::File::create(&self.config_path)
            .map_err(|e| ConfigError::IOError(format!("Failed to create config file: {}", e)))?;
            
        file.write_all(json.as_bytes())
            .map_err(|e| ConfigError::IOError(format!("Failed to write config file: {}", e)))?;
            
        debug!("Saved configuration to {:?}", self.config_path);
        Ok(())
    }
    
    fn get_config_path(&self) -> PathBuf {
        self.config_path.clone()
    }
}

/// Factory for creating JsonConfigRepository instances
pub struct JsonConfigRepositoryFactory;

impl JsonConfigRepositoryFactory {
    pub fn new() -> Self {
        Self
    }
}

impl ConfigRepositoryFactory for JsonConfigRepositoryFactory {
    fn create_repository(&self) -> Arc<dyn ConfigRepository> {
        Arc::new(JsonConfigRepository::new())
    }
}