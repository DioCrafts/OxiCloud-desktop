use crate::application::ports::encryption_port::EncryptionPort;
use crate::domain::entities::encryption::{
    EncryptionResult, EncryptionSettings, EncryptionError, EncryptionMetadata
};
use crate::domain::services::encryption_service::EncryptionService;

use std::path::PathBuf;
use std::sync::Arc;
use std::fs;
use std::io::{Read, Write};
use async_trait::async_trait;
use tracing::{info, error, debug};

pub struct EncryptionApplicationService {
    encryption_service: Arc<dyn EncryptionService>,
}

impl EncryptionApplicationService {
    pub fn new(encryption_service: Arc<dyn EncryptionService>) -> Self {
        Self {
            encryption_service,
        }
    }
}

#[async_trait]
impl EncryptionPort for EncryptionApplicationService {
    async fn initialize_encryption(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings> {
        info!("Initializing encryption with settings: {:?}", settings);
        self.encryption_service.initialize(password, settings).await
    }
    
    async fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()> {
        info!("Changing encryption password");
        self.encryption_service.change_password(old_password, new_password).await
    }
    
    async fn encrypt_file(&self, password: &str, file_path: &PathBuf) -> EncryptionResult<PathBuf> {
        info!("Encrypting file: {:?}", file_path);
        
        // Check if file exists
        if !file_path.exists() {
            return Err(EncryptionError::IOError(format!("File not found: {:?}", file_path)));
        }
        
        // Read file content
        let mut file = fs::File::open(file_path)
            .map_err(|e| EncryptionError::IOError(format!("Failed to open file: {}", e)))?;
        
        let mut buffer = Vec::new();
        file.read_to_end(&mut buffer)
            .map_err(|e| EncryptionError::IOError(format!("Failed to read file: {}", e)))?;
        
        // Encrypt the data
        let (encrypted_data, iv, metadata) = self.encryption_service.encrypt_data(password, &buffer).await?;
        
        // Create encrypted file path
        let mut encrypted_path = file_path.to_path_buf();
        let file_name = encrypted_path.file_name()
            .ok_or_else(|| EncryptionError::IOError("Invalid file name".to_string()))?
            .to_string_lossy()
            .to_string();
        
        let encrypted_file_name = format!("{}.encrypted", file_name);
        encrypted_path.set_file_name(encrypted_file_name);
        
        // Create a wrapper structure for the encrypted data
        let wrapper = serde_json::json!({
            "version": 1,
            "iv": iv,
            "metadata": metadata,
            "encrypted_data": base64::Engine as _::encode(&encrypted_data),
        });
        
        // Write encrypted data to file
        let encrypted_json = serde_json::to_string(&wrapper)
            .map_err(|e| EncryptionError::SerializationError(format!("Failed to serialize encrypted data: {}", e)))?;
        
        fs::write(&encrypted_path, encrypted_json)
            .map_err(|e| EncryptionError::IOError(format!("Failed to write encrypted file: {}", e)))?;
        
        Ok(encrypted_path)
    }
    
    async fn decrypt_file(&self, password: &str, file_path: &PathBuf) -> EncryptionResult<PathBuf> {
        info!("Decrypting file: {:?}", file_path);
        
        // Check if file exists
        if !file_path.exists() {
            return Err(EncryptionError::IOError(format!("File not found: {:?}", file_path)));
        }
        
        // Read encrypted file
        let encrypted_json = fs::read_to_string(file_path)
            .map_err(|e| EncryptionError::IOError(format!("Failed to read encrypted file: {}", e)))?;
        
        // Parse wrapper structure
        let wrapper: serde_json::Value = serde_json::from_str(&encrypted_json)
            .map_err(|e| EncryptionError::SerializationError(format!("Invalid encrypted file format: {}", e)))?;
        
        // Extract fields
        let version = wrapper["version"].as_i64()
            .ok_or_else(|| EncryptionError::SerializationError("Missing version in encrypted file".to_string()))?;
        
        if version != 1 {
            return Err(EncryptionError::SerializationError(format!("Unsupported encrypted file version: {}", version)));
        }
        
        let iv = wrapper["iv"].as_str()
            .ok_or_else(|| EncryptionError::SerializationError("Missing IV in encrypted file".to_string()))?;
        
        let metadata = wrapper["metadata"].as_str()
            .ok_or_else(|| EncryptionError::SerializationError("Missing metadata in encrypted file".to_string()))?;
        
        let encrypted_data_base64 = wrapper["encrypted_data"].as_str()
            .ok_or_else(|| EncryptionError::SerializationError("Missing encrypted data in encrypted file".to_string()))?;
        
        // Decode base64
        let encrypted_data = base64::Engine::decode(&base64::engine::general_purpose::STANDARD, encrypted_data_base64)
            .map_err(|e| EncryptionError::SerializationError(format!("Invalid base64 data: {}", e)))?;
        
        // Decrypt the data
        let decrypted_data = self.encryption_service.decrypt_data(password, &encrypted_data, iv, metadata).await?;
        
        // Create decrypted file path
        let mut decrypted_path = file_path.to_path_buf();
        let file_name = decrypted_path.file_name()
            .ok_or_else(|| EncryptionError::IOError("Invalid file name".to_string()))?
            .to_string_lossy()
            .to_string();
        
        // Remove .encrypted extension if present
        let decrypted_file_name = if file_name.ends_with(".encrypted") {
            file_name[..file_name.len() - 10].to_string()
        } else {
            format!("decrypted_{}", file_name)
        };
        
        decrypted_path.set_file_name(decrypted_file_name);
        
        // Write decrypted data to file
        fs::write(&decrypted_path, decrypted_data)
            .map_err(|e| EncryptionError::IOError(format!("Failed to write decrypted file: {}", e)))?;
        
        Ok(decrypted_path)
    }
    
    async fn get_encryption_settings(&self) -> EncryptionResult<EncryptionSettings> {
        self.encryption_service.get_settings().await
    }
    
    async fn update_encryption_settings(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<()> {
        info!("Updating encryption settings: {:?}", settings);
        self.encryption_service.update_settings(password, settings).await
    }
    
    async fn export_encryption_key(&self, password: &str, output_path: &PathBuf) -> EncryptionResult<()> {
        info!("Exporting encryption key to: {:?}", output_path);
        self.encryption_service.export_key(password, output_path).await
    }
    
    async fn import_encryption_key(&self, password: &str, input_path: &PathBuf) -> EncryptionResult<()> {
        info!("Importing encryption key from: {:?}", input_path);
        self.encryption_service.import_key(password, input_path).await
    }
    
    async fn verify_password(&self, password: &str) -> EncryptionResult<bool> {
        self.encryption_service.verify_password(password).await
    }
}