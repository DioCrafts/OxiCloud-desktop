use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionSettings,
    EncryptionMetadata
};
use async_trait::async_trait;
use std::path::PathBuf;

/// Repository interface for encryption-related storage operations
#[async_trait]
pub trait EncryptionRepository: Send + Sync + 'static {
    /// Store encryption settings
    async fn store_settings(&self, settings: &EncryptionSettings) -> EncryptionResult<()>;
    
    /// Retrieve encryption settings
    async fn get_settings(&self) -> EncryptionResult<EncryptionSettings>;
    
    /// Store encrypted master key
    async fn store_master_key(&self, encrypted_key: &[u8], salt: &str, key_id: &str) -> EncryptionResult<()>;
    
    /// Retrieve encrypted master key
    async fn get_master_key(&self, key_id: &str) -> EncryptionResult<(Vec<u8>, String)>;
    
    /// List all key versions
    async fn list_keys(&self) -> EncryptionResult<Vec<String>>;
    
    /// Delete a key version
    async fn delete_key(&self, key_id: &str) -> EncryptionResult<()>;
}