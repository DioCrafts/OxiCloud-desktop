use crate::domain::entities::recovery::{RecoveryResult, RecoveryError, RecoveryMethod};
use crate::domain::entities::encryption::EncryptionSettings;
use async_trait::async_trait;
use std::path::PathBuf;

#[async_trait]
pub trait RecoveryService: Send + Sync + 'static {
    /// Initialize recovery options for encryption
    async fn initialize_recovery(&self, 
                               encryption_settings: &EncryptionSettings) -> RecoveryResult<()>;
    
    /// Recover encryption key using security questions
    async fn recover_with_questions(&self, 
                                 question_answers: &[(String, String)]) -> RecoveryResult<String>;
    
    /// Recover encryption key using recovery key
    async fn recover_with_key(&self, 
                           recovery_key: &str) -> RecoveryResult<String>;
    
    /// Generate a new recovery key
    async fn generate_recovery_key(&self) -> RecoveryResult<String>;
    
    /// Get supported recovery methods
    async fn get_recovery_methods(&self) -> RecoveryResult<Vec<RecoveryMethod>>;
    
    /// Recover file metadata from partially corrupted file
    async fn recover_file_metadata(&self, file_path: &PathBuf) -> RecoveryResult<Option<serde_json::Value>>;
}