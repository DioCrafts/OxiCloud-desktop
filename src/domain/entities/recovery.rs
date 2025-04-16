use serde::{Serialize, Deserialize};
use thiserror::Error;
use uuid::Uuid;
use chrono::{DateTime, Utc};
use std::path::PathBuf;

/// Errors that can occur during recovery operations
#[derive(Debug, Error)]
pub enum RecoveryError {
    #[error("Invalid recovery key: {0}")]
    InvalidRecoveryKey(String),
    
    #[error("Recovery key expired: {0}")]
    ExpiredRecoveryKey(String),
    
    #[error("Security question error: {0}")]
    SecurityQuestionError(String),
    
    #[error("Recovery storage error: {0}")]
    StorageError(String),
    
    #[error("Recovery encryption error: {0}")]
    EncryptionError(String),
    
    #[error("Recovery IO error: {0}")]
    IOError(String),
    
    #[error("Recovery operation canceled: {0}")]
    CanceledError(String),
    
    #[error("Recovery verification failed: {0}")]
    VerificationError(String),
}

pub type RecoveryResult<T> = Result<T, RecoveryError>;

/// Types of backup/recovery methods available
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum RecoveryMethod {
    /// Recovery using a backup key file
    BackupKeyFile,
    
    /// Recovery using security questions
    SecurityQuestions,
    
    /// Recovery using a trusted device
    TrustedDevice,
    
    /// Recovery using a printed recovery code
    PrintedRecoveryCode,
}

/// Security question for password recovery
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SecurityQuestion {
    pub id: String,
    pub question: String,
    pub answer_hash: String, // Securely hashed answer
    pub hint: Option<String>,
}

impl SecurityQuestion {
    pub fn new(question: String, answer: &str, hint: Option<String>) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            question,
            answer_hash: Self::hash_answer(answer),
            hint,
        }
    }
    
    /// Hash the answer to securely store it
    fn hash_answer(answer: &str) -> String {
        // In a real implementation, this would use a proper password hashing algorithm
        // with salt (e.g., bcrypt, Argon2, PBKDF2)
        // For this MVP, we'll use a simple placeholder
        format!("hashed:{}", answer.to_lowercase().trim())
    }
    
    /// Verify if the given answer matches the stored hash
    pub fn verify_answer(&self, answer: &str) -> bool {
        let hashed = Self::hash_answer(answer);
        self.answer_hash == hashed
    }
}

/// Recovery key used to reset encryption password
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecoveryKey {
    pub id: String,
    pub created_at: DateTime<Utc>,
    pub expires_at: Option<DateTime<Utc>>,
    pub method: RecoveryMethod,
    pub key_data: String, // Encrypted key data
    pub verification_code: String, // Code to verify the recovery key
    pub used: bool,
}

impl RecoveryKey {
    pub fn new(method: RecoveryMethod, key_data: String, expiry_days: Option<u32>) -> Self {
        let now = Utc::now();
        let expires_at = expiry_days.map(|days| {
            now + chrono::Duration::days(days as i64)
        });
        
        Self {
            id: Uuid::new_v4().to_string(),
            created_at: now,
            expires_at,
            method,
            key_data,
            verification_code: Self::generate_verification_code(),
            used: false,
        }
    }
    
    /// Generate a human-readable verification code
    fn generate_verification_code() -> String {
        // Generate a code like "ABCD-1234-EFGH-5678"
        // In practice, this would be more sophisticated
        let uuid = Uuid::new_v4();
        let uuid_str = uuid.to_string().replace("-", "");
        
        let parts: Vec<String> = uuid_str
            .chars()
            .enumerate()
            .filter(|(i, _)| i % 4 == 0)
            .map(|(i, _)| uuid_str[i..i+4].to_uppercase())
            .take(4)
            .collect();
            
        parts.join("-")
    }
    
    /// Check if the recovery key is expired
    pub fn is_expired(&self) -> bool {
        if let Some(expiry) = self.expires_at {
            Utc::now() > expiry
        } else {
            false
        }
    }
    
    /// Mark the recovery key as used
    pub fn mark_as_used(&mut self) {
        self.used = true;
    }
}

/// Recovery backup - contains all recovery options configured by the user
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecoveryBackup {
    pub id: String,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub security_questions: Vec<SecurityQuestion>,
    pub recovery_keys: Vec<RecoveryKey>,
    pub trusted_devices: Vec<String>,
    pub backup_file_path: Option<PathBuf>,
}

impl RecoveryBackup {
    pub fn new() -> Self {
        let now = Utc::now();
        Self {
            id: Uuid::new_v4().to_string(),
            created_at: now,
            updated_at: now,
            security_questions: Vec::new(),
            recovery_keys: Vec::new(),
            trusted_devices: Vec::new(),
            backup_file_path: None,
        }
    }
    
    /// Add a security question
    pub fn add_security_question(&mut self, question: SecurityQuestion) {
        self.security_questions.push(question);
        self.updated_at = Utc::now();
    }
    
    /// Add a recovery key
    pub fn add_recovery_key(&mut self, key: RecoveryKey) {
        self.recovery_keys.push(key);
        self.updated_at = Utc::now();
    }
    
    /// Add a trusted device
    pub fn add_trusted_device(&mut self, device_id: String) {
        self.trusted_devices.push(device_id);
        self.updated_at = Utc::now();
    }
    
    /// Set backup file path
    pub fn set_backup_file_path(&mut self, path: PathBuf) {
        self.backup_file_path = Some(path);
        self.updated_at = Utc::now();
    }
    
    /// Check if there are any valid recovery methods available
    pub fn has_valid_recovery_methods(&self) -> bool {
        // Check if there are any security questions
        let has_questions = !self.security_questions.is_empty();
        
        // Check if there are any non-expired, unused recovery keys
        let has_valid_keys = self.recovery_keys.iter()
            .any(|key| !key.used && !key.is_expired());
            
        // Check if there are any trusted devices
        let has_trusted_devices = !self.trusted_devices.is_empty();
        
        // Check if backup file exists
        let has_backup_file = self.backup_file_path
            .as_ref()
            .map_or(false, |path| path.exists());
            
        has_questions || has_valid_keys || has_trusted_devices || has_backup_file
    }
}