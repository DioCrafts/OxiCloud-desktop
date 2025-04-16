use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionSettings,
    EncryptionMetadata, EncryptionService as EncryptionServiceTrait
};
use async_trait::async_trait;
use std::path::PathBuf;

/// Domain service for encryption operations
#[async_trait]
pub trait EncryptionService: Send + Sync + 'static {
    /// Initialize the encryption system with the given settings
    async fn initialize(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings>;
    
    /// Change the encryption password
    async fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()>;
    
    /// Encrypt file data
    async fn encrypt_data(&self, password: &str, data: &[u8]) -> EncryptionResult<(Vec<u8>, String, String)>;
    
    /// Decrypt file data
    async fn decrypt_data(&self, password: &str, data: &[u8], iv: &str, metadata: &str) -> EncryptionResult<Vec<u8>>;
    
    /// Encrypt a string (filename or metadata)
    async fn encrypt_string(&self, password: &str, text: &str) -> EncryptionResult<(String, String, String)>;
    
    /// Decrypt a string
    async fn decrypt_string(&self, password: &str, text: &str, iv: &str, metadata: &str) -> EncryptionResult<String>;
    
    /// Get current encryption settings
    async fn get_settings(&self) -> EncryptionResult<EncryptionSettings>;
    
    /// Update encryption settings
    async fn update_settings(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<()>;
    
    /// Export encryption key to a file
    async fn export_key(&self, password: &str, output_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Import encryption key from a file
    async fn import_key(&self, password: &str, input_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Verify if the password is correct
    async fn verify_password(&self, password: &str) -> EncryptionResult<bool>;
}