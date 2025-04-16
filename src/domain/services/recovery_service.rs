use crate::domain::entities::recovery::{
    RecoveryError, RecoveryResult, RecoveryMethod,
    SecurityQuestion, RecoveryKey, RecoveryBackup
};
use crate::domain::entities::encryption::{
    EncryptionError, EncryptionResult, EncryptionSettings
};
use crate::domain::services::encryption_service::EncryptionService;
use crate::domain::services::error_recovery_service::ErrorRecoveryService;

use async_trait::async_trait;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::fs;
use tokio::sync::Mutex;
use tracing::{info, error, warn};
use serde_json;
use uuid::Uuid;
use chrono::Utc;

/// Service for managing key recovery and password reset
#[async_trait]
pub trait RecoveryService: Send + Sync + 'static {
    /// Setup recovery options
    async fn setup_recovery(&self, backup: &RecoveryBackup) -> RecoveryResult<()>;
    
    /// Add security questions for recovery
    async fn add_security_questions(&self, questions: Vec<SecurityQuestion>) -> RecoveryResult<()>;
    
    /// Verify security question answers
    async fn verify_security_questions(&self, question_answers: Vec<(String, String)>) -> RecoveryResult<bool>;
    
    /// Generate a recovery key
    async fn generate_recovery_key(&self, 
                                method: RecoveryMethod, 
                                password: &str,
                                expiry_days: Option<u32>) -> RecoveryResult<RecoveryKey>;
    
    /// Reset password using a recovery key
    async fn reset_password_with_key(&self, 
                                   recovery_key_id: &str,
                                   verification_code: &str,
                                   new_password: &str) -> RecoveryResult<()>;
    
    /// Reset password using security questions
    async fn reset_password_with_questions(&self,
                                         question_answers: Vec<(String, String)>,
                                         new_password: &str) -> RecoveryResult<()>;
                                         
    /// Get current recovery backup
    async fn get_recovery_backup(&self) -> RecoveryResult<RecoveryBackup>;
    
    /// Create backup key file
    async fn create_backup_key_file(&self, 
                                  password: &str,
                                  path: &PathBuf) -> RecoveryResult<PathBuf>;
    
    /// Check if recovery is possible
    async fn can_recover(&self) -> RecoveryResult<bool>;
}

pub struct RecoveryServiceImpl {
    encryption_service: Arc<dyn EncryptionService>,
    error_recovery_service: Arc<dyn ErrorRecoveryService>,
    recovery_backup: Arc<Mutex<RecoveryBackup>>,
    recovery_file_path: PathBuf,
}

impl RecoveryServiceImpl {
    pub fn new(
        encryption_service: Arc<dyn EncryptionService>,
        error_recovery_service: Arc<dyn ErrorRecoveryService>,
        data_dir: &PathBuf,
    ) -> Self {
        let recovery_file_path = data_dir.join("recovery.json");
        
        Self {
            encryption_service,
            error_recovery_service,
            recovery_backup: Arc::new(Mutex::new(RecoveryBackup::new())),
            recovery_file_path,
        }
    }
    
    // Load recovery backup from disk
    async fn load_recovery_backup(&self) -> RecoveryResult<()> {
        // Check if file exists
        if !self.recovery_file_path.exists() {
            // No backup file yet, use default empty backup
            return Ok(());
        }
        
        // Read file content
        let content = match fs::read_to_string(&self.recovery_file_path).await {
            Ok(content) => content,
            Err(e) => {
                return Err(RecoveryError::IOError(format!(
                    "Failed to read recovery backup file: {}", e
                )));
            }
        };
        
        // Parse JSON
        let backup: RecoveryBackup = match serde_json::from_str(&content) {
            Ok(backup) => backup,
            Err(e) => {
                return Err(RecoveryError::StorageError(format!(
                    "Failed to parse recovery backup: {}", e
                )));
            }
        };
        
        // Update in-memory backup
        let mut backup_lock = self.recovery_backup.lock().await;
        *backup_lock = backup;
        
        Ok(())
    }
    
    // Save recovery backup to disk
    async fn save_recovery_backup(&self) -> RecoveryResult<()> {
        // Get current backup
        let backup = self.recovery_backup.lock().await.clone();
        
        // Serialize to JSON
        let json = match serde_json::to_string_pretty(&backup) {
            Ok(json) => json,
            Err(e) => {
                return Err(RecoveryError::StorageError(format!(
                    "Failed to serialize recovery backup: {}", e
                )));
            }
        };
        
        // Create parent directory if it doesn't exist
        if let Some(parent) = self.recovery_file_path.parent() {
            if !parent.exists() {
                if let Err(e) = fs::create_dir_all(parent).await {
                    return Err(RecoveryError::IOError(format!(
                        "Failed to create recovery directory: {}", e
                    )));
                }
            }
        }
        
        // Write to file
        if let Err(e) = fs::write(&self.recovery_file_path, json).await {
            return Err(RecoveryError::IOError(format!(
                "Failed to write recovery backup file: {}", e
            )));
        }
        
        Ok(())
    }
    
    // Encrypt recovery key data
    async fn encrypt_recovery_key_data(&self, password: &str) -> RecoveryResult<String> {
        // Get current encryption settings
        let settings = match self.encryption_service.get_settings().await {
            Ok(settings) => settings,
            Err(e) => {
                return Err(RecoveryError::EncryptionError(format!(
                    "Failed to get encryption settings: {}", e
                )));
            }
        };
        
        // Create a JSON structure with master key and settings
        let recovery_data = serde_json::json!({
            "key_id": settings.key_id,
            "algorithm": settings.algorithm,
            "created_at": Utc::now().to_rfc3339(),
            "version": 1,
        });
        
        // Serialize to string
        let recovery_json = match serde_json::to_string(&recovery_data) {
            Ok(json) => json,
            Err(e) => {
                return Err(RecoveryError::StorageError(format!(
                    "Failed to serialize recovery data: {}", e
                )));
            }
        };
        
        // Encrypt the recovery data using password
        let (encrypted_data, iv, metadata) = match self.encryption_service.encrypt_string(password, &recovery_json).await {
            Ok(result) => result,
            Err(e) => {
                return Err(RecoveryError::EncryptionError(format!(
                    "Failed to encrypt recovery data: {}", e
                )));
            }
        };
        
        // Combine everything into a JSON structure
        let encrypted_recovery = serde_json::json!({
            "encrypted_data": encrypted_data,
            "iv": iv,
            "metadata": metadata,
        });
        
        // Serialize to string
        match serde_json::to_string(&encrypted_recovery) {
            Ok(json) => Ok(json),
            Err(e) => {
                Err(RecoveryError::StorageError(format!(
                    "Failed to serialize encrypted recovery data: {}", e
                )))
            }
        }
    }
    
    // Decrypt recovery key data
    async fn decrypt_recovery_key_data(&self, 
                                    encrypted_data: &str, 
                                    password: &str) -> RecoveryResult<serde_json::Value> {
        // Parse the encrypted recovery data
        let encrypted_recovery: serde_json::Value = match serde_json::from_str(encrypted_data) {
            Ok(data) => data,
            Err(e) => {
                return Err(RecoveryError::StorageError(format!(
                    "Failed to parse encrypted recovery data: {}", e
                )));
            }
        };
        
        // Extract fields
        let ciphertext = match encrypted_recovery["encrypted_data"].as_str() {
            Some(text) => text,
            None => {
                return Err(RecoveryError::InvalidRecoveryKey(
                    "Missing encrypted data in recovery key".to_string()
                ));
            }
        };
        
        let iv = match encrypted_recovery["iv"].as_str() {
            Some(iv) => iv,
            None => {
                return Err(RecoveryError::InvalidRecoveryKey(
                    "Missing IV in recovery key".to_string()
                ));
            }
        };
        
        let metadata = match encrypted_recovery["metadata"].as_str() {
            Some(metadata) => metadata,
            None => {
                return Err(RecoveryError::InvalidRecoveryKey(
                    "Missing metadata in recovery key".to_string()
                ));
            }
        };
        
        // Decrypt the data
        let decrypted_json = match self.encryption_service.decrypt_string(password, ciphertext, iv, metadata).await {
            Ok(json) => json,
            Err(e) => {
                return Err(RecoveryError::EncryptionError(format!(
                    "Failed to decrypt recovery key: {}", e
                )));
            }
        };
        
        // Parse the JSON
        match serde_json::from_str::<serde_json::Value>(&decrypted_json) {
            Ok(data) => Ok(data),
            Err(e) => {
                Err(RecoveryError::StorageError(format!(
                    "Failed to parse decrypted recovery data: {}", e
                )))
            }
        }
    }
}

#[async_trait]
impl RecoveryService for RecoveryServiceImpl {
    async fn setup_recovery(&self, backup: &RecoveryBackup) -> RecoveryResult<()> {
        // Replace current backup with the provided one
        let mut current_backup = self.recovery_backup.lock().await;
        *current_backup = backup.clone();
        drop(current_backup);
        
        // Save to disk
        self.save_recovery_backup().await?;
        
        info!("Recovery options setup completed");
        Ok(())
    }
    
    async fn add_security_questions(&self, questions: Vec<SecurityQuestion>) -> RecoveryResult<()> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Add questions to current backup
        let mut backup = self.recovery_backup.lock().await;
        for question in questions {
            backup.add_security_question(question);
        }
        drop(backup);
        
        // Save to disk
        self.save_recovery_backup().await?;
        
        info!("Added {} security questions for recovery", questions.len());
        Ok(())
    }
    
    async fn verify_security_questions(&self, question_answers: Vec<(String, String)>) -> RecoveryResult<bool> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Get security questions
        let backup = self.recovery_backup.lock().await;
        let stored_questions = backup.security_questions.clone();
        drop(backup);
        
        // Need at least 2 correct answers or all of them if less than 2
        let min_correct = if stored_questions.len() <= 2 {
            stored_questions.len()
        } else {
            2
        };
        
        // Check each answer
        let mut correct_count = 0;
        for (question_id, answer) in question_answers {
            // Find matching question
            if let Some(question) = stored_questions.iter().find(|q| q.id == question_id) {
                if question.verify_answer(&answer) {
                    correct_count += 1;
                }
            }
        }
        
        let result = correct_count >= min_correct;
        info!("Security question verification result: {}", result);
        
        Ok(result)
    }
    
    async fn generate_recovery_key(&self, 
                               method: RecoveryMethod, 
                               password: &str,
                               expiry_days: Option<u32>) -> RecoveryResult<RecoveryKey> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Encrypt recovery key data
        let encrypted_data = self.encrypt_recovery_key_data(password).await?;
        
        // Create recovery key
        let recovery_key = RecoveryKey::new(method, encrypted_data, expiry_days);
        
        // Add to backup
        let mut backup = self.recovery_backup.lock().await;
        backup.add_recovery_key(recovery_key.clone());
        drop(backup);
        
        // Save to disk
        self.save_recovery_backup().await?;
        
        info!("Generated new recovery key: {}", recovery_key.id);
        Ok(recovery_key)
    }
    
    async fn reset_password_with_key(&self, 
                                  recovery_key_id: &str,
                                  verification_code: &str,
                                  new_password: &str) -> RecoveryResult<()> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Find recovery key
        let mut backup = self.recovery_backup.lock().await;
        let key_index = backup.recovery_keys.iter().position(|k| k.id == recovery_key_id)
            .ok_or_else(|| RecoveryError::InvalidRecoveryKey(
                format!("Recovery key not found: {}", recovery_key_id)
            ))?;
        
        let recovery_key = backup.recovery_keys[key_index].clone();
        
        // Check if key is used or expired
        if recovery_key.used {
            return Err(RecoveryError::InvalidRecoveryKey(
                "Recovery key has already been used".to_string()
            ));
        }
        
        if recovery_key.is_expired() {
            return Err(RecoveryError::ExpiredRecoveryKey(
                "Recovery key has expired".to_string()
            ));
        }
        
        // Verify code
        if recovery_key.verification_code != verification_code {
            return Err(RecoveryError::VerificationError(
                "Invalid verification code".to_string()
            ));
        }
        
        // At this point, the recovery key is valid
        // We need to decrypt it to get the original key data
        
        // Mark the key as used and save
        backup.recovery_keys[key_index].mark_as_used();
        drop(backup);
        
        self.save_recovery_backup().await?;
        
        // For password reset, we use the backup key file
        let backup_file_path = self.recovery_backup.lock().await.backup_file_path.clone();
        
        if let Some(path) = backup_file_path {
            if path.exists() {
                match self.error_recovery_service.restore_from_backup(&path, new_password).await {
                    Ok(_) => {
                        info!("Password reset successful using recovery key");
                        Ok(())
                    },
                    Err(e) => {
                        error!("Failed to reset password from backup: {}", e);
                        Err(RecoveryError::EncryptionError(format!(
                            "Failed to reset password from backup: {}", e
                        )))
                    }
                }
            } else {
                Err(RecoveryError::StorageError(
                    "Backup key file not found".to_string()
                ))
            }
        } else {
            Err(RecoveryError::StorageError(
                "No backup key file configured".to_string()
            ))
        }
    }
    
    async fn reset_password_with_questions(&self,
                                        question_answers: Vec<(String, String)>,
                                        new_password: &str) -> RecoveryResult<()> {
        // Verify security questions
        let verified = self.verify_security_questions(question_answers).await?;
        if !verified {
            return Err(RecoveryError::SecurityQuestionError(
                "Failed to verify security questions".to_string()
            ));
        }
        
        // If verified, use backup key file for password reset
        let backup_file_path = self.recovery_backup.lock().await.backup_file_path.clone();
        
        if let Some(path) = backup_file_path {
            if path.exists() {
                match self.error_recovery_service.restore_from_backup(&path, new_password).await {
                    Ok(_) => {
                        info!("Password reset successful using security questions");
                        Ok(())
                    },
                    Err(e) => {
                        error!("Failed to reset password from backup: {}", e);
                        Err(RecoveryError::EncryptionError(format!(
                            "Failed to reset password from backup: {}", e
                        )))
                    }
                }
            } else {
                Err(RecoveryError::StorageError(
                    "Backup key file not found".to_string()
                ))
            }
        } else {
            Err(RecoveryError::StorageError(
                "No backup key file configured".to_string()
            ))
        }
    }
    
    async fn get_recovery_backup(&self) -> RecoveryResult<RecoveryBackup> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Return a clone of the current backup
        let backup = self.recovery_backup.lock().await.clone();
        Ok(backup)
    }
    
    async fn create_backup_key_file(&self, 
                                 password: &str,
                                 path: &PathBuf) -> RecoveryResult<PathBuf> {
        // Create backup key
        match self.error_recovery_service.create_emergency_backup(password, path).await {
            Ok(_) => {
                // Update backup with file path
                let mut backup = self.recovery_backup.lock().await;
                backup.set_backup_file_path(path.clone());
                drop(backup);
                
                self.save_recovery_backup().await?;
                
                info!("Created backup key file at {:?}", path);
                Ok(path.clone())
            },
            Err(e) => {
                Err(RecoveryError::EncryptionError(format!(
                    "Failed to create backup key file: {}", e
                )))
            }
        }
    }
    
    async fn can_recover(&self) -> RecoveryResult<bool> {
        // Load backup if not already loaded
        self.load_recovery_backup().await?;
        
        // Check if there are any valid recovery methods
        let backup = self.recovery_backup.lock().await;
        let result = backup.has_valid_recovery_methods();
        
        Ok(result)
    }
}