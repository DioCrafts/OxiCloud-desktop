use crate::domain::entities::encryption::{
    EncryptionResult, EncryptionSettings, EncryptionError
};
use std::path::PathBuf;
use async_trait::async_trait;

/// Application port for encryption operations
#[async_trait]
pub trait EncryptionPort: Send + Sync + 'static {
    /// Initialize encryption with the given settings
    async fn initialize_encryption(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings>;
    
    /// Change the encryption password
    async fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()>;
    
    /// Encrypt file data
    async fn encrypt_file(&self, password: &str, file_path: &PathBuf) -> EncryptionResult<PathBuf>;
    
    /// Decrypt file data
    async fn decrypt_file(&self, password: &str, file_path: &PathBuf) -> EncryptionResult<PathBuf>;
    
    /// Get current encryption settings
    async fn get_encryption_settings(&self) -> EncryptionResult<EncryptionSettings>;
    
    /// Update encryption settings
    async fn update_encryption_settings(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<()>;
    
    /// Export encryption key to a file
    async fn export_encryption_key(&self, password: &str, output_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Import encryption key from a file
    async fn import_encryption_key(&self, password: &str, input_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Verify if the password is correct
    async fn verify_password(&self, password: &str) -> EncryptionResult<bool>;
}