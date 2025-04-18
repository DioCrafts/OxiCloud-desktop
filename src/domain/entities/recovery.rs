use std::fmt;
use thiserror::Error;

#[derive(Debug, Clone, PartialEq)]
pub enum RecoveryMethod {
    SecurityQuestions,
    BackupKeyFile,
    PrintedRecoveryCode,
    TrustedDevice,
}

impl fmt::Display for RecoveryMethod {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            RecoveryMethod::SecurityQuestions => write!(f, "Security Questions"),
            RecoveryMethod::BackupKeyFile => write!(f, "Backup Key File"),
            RecoveryMethod::PrintedRecoveryCode => write!(f, "Printed Recovery Code"),
            RecoveryMethod::TrustedDevice => write!(f, "Trusted Device"),
        }
    }
}

#[derive(Debug, Clone)]
pub struct SecurityQuestion {
    pub id: String,
    pub question: String,
    pub answer: Option<String>,
}

#[derive(Debug, Error)]
pub enum RecoveryError {
    #[error("Recovery initialization failed: {0}")]
    InitializationError(String),
    
    #[error("Recovery verification failed: {0}")]
    VerificationError(String),
    
    #[error("Recovery key generation failed: {0}")]
    KeyGenerationError(String),
    
    #[error("Invalid recovery data: {0}")]
    InvalidDataError(String),
    
    #[error("Recovery method not supported: {0}")]
    UnsupportedMethodError(String),
    
    #[error("Internal recovery error: {0}")]
    InternalError(String),
}

pub type RecoveryResult<T> = std::result::Result<T, RecoveryError>;