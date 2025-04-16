use serde::{Serialize, Deserialize};
use thiserror::Error;
use std::path::PathBuf;

/// Errors that can occur during encryption/decryption operations
#[derive(Debug, Error)]
pub enum EncryptionError {
    #[error("Key derivation error: {0}")]
    KeyDerivationError(String),
    
    #[error("Encryption error: {0}")]
    EncryptionError(String),
    
    #[error("Decryption error: {0}")]
    DecryptionError(String),
    
    #[error("Invalid key: {0}")]
    InvalidKeyError(String),
    
    #[error("IO error: {0}")]
    IOError(String),
    
    #[error("Serialization error: {0}")]
    SerializationError(String),
    
    #[error("Storage error: {0}")]
    StorageError(String),
    
    #[error("Metadata error: {0}")]
    MetadataError(String),
}

pub type EncryptionResult<T> = Result<T, EncryptionError>;

/// Supported encryption algorithms
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum EncryptionAlgorithm {
    /// AES-256-GCM (not quantum resistant but widely supported)
    Aes256Gcm,
    
    /// KYBER768 - Post-Quantum Key Encapsulation Mechanism (KEM)
    Kyber768,
    
    /// DILITHIUM5 - Post-Quantum Digital Signatures
    Dilithium5,
    
    /// ChaCha20-Poly1305 (not quantum resistant but good alternative to AES)
    Chacha20Poly1305,
    
    /// Hybrid approach: Classical + Post-Quantum
    HybridAesKyber,
}

impl Default for EncryptionAlgorithm {
    fn default() -> Self {
        Self::HybridAesKyber
    }
}

/// Key storage options
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum KeyStorageMethod {
    /// Password-based (derived from user password)
    Password,
    
    /// File-based (key stored in a file)
    KeyFile(PathBuf),
    
    /// System keychain
    SystemKeychain,
    
    /// Hardware token
    HardwareToken,
}

impl Default for KeyStorageMethod {
    fn default() -> Self {
        Self::Password
    }
}

/// Encryption settings for the application
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptionSettings {
    /// Whether E2EE is enabled
    pub enabled: bool,
    
    /// Which algorithm to use
    pub algorithm: EncryptionAlgorithm,
    
    /// How to store/derive the keys
    pub key_storage: KeyStorageMethod,
    
    /// Whether to encrypt file names (not just content)
    pub encrypt_filenames: bool,
    
    /// Whether to encrypt file metadata
    pub encrypt_metadata: bool,
    
    /// Salt for key derivation (in Base64)
    pub kdf_salt: Option<String>,
    
    /// Public key for encryption (in Base64)
    pub public_key: Option<String>,
    
    /// Key ID/version
    pub key_id: Option<String>,
}

impl Default for EncryptionSettings {
    fn default() -> Self {
        Self {
            enabled: false,
            algorithm: EncryptionAlgorithm::default(),
            key_storage: KeyStorageMethod::default(),
            encrypt_filenames: true,
            encrypt_metadata: true,
            kdf_salt: None,
            public_key: None,
            key_id: None,
        }
    }
}

/// Metadata stored with each encrypted file
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EncryptionMetadata {
    /// Algorithm used for encryption
    pub algorithm: EncryptionAlgorithm,
    
    /// Key ID/version used for encryption
    pub key_id: String,
    
    /// Whether the filename is encrypted
    pub filename_encrypted: bool,
    
    /// Original file size before encryption
    pub original_size: u64,
    
    /// Original file mime type
    pub original_mime_type: Option<String>,
    
    /// File extension
    pub extension: Option<String>,
}

/// Interface for encrypting/decrypting files
pub trait EncryptionService: Send + Sync + 'static {
    /// Initialize encryption (generate keys, etc.)
    fn initialize(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<EncryptionSettings>;
    
    /// Change password
    fn change_password(&self, old_password: &str, new_password: &str) -> EncryptionResult<()>;
    
    /// Encrypt file content
    fn encrypt_data(&self, password: &str, data: &[u8]) -> EncryptionResult<(Vec<u8>, String, String)>;
    
    /// Decrypt file content
    fn decrypt_data(&self, password: &str, data: &[u8], iv: &str, metadata: &str) -> EncryptionResult<Vec<u8>>;
    
    /// Encrypt string (for filenames, etc.)
    fn encrypt_string(&self, password: &str, text: &str) -> EncryptionResult<(String, String, String)>;
    
    /// Decrypt string
    fn decrypt_string(&self, password: &str, text: &str, iv: &str, metadata: &str) -> EncryptionResult<String>;
    
    /// Get current encryption settings
    fn get_settings(&self) -> EncryptionResult<EncryptionSettings>;
    
    /// Update encryption settings
    fn update_settings(&self, password: &str, settings: &EncryptionSettings) -> EncryptionResult<()>;
    
    /// Export encryption key (for backup)
    fn export_key(&self, password: &str, output_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Import encryption key
    fn import_key(&self, password: &str, input_path: &PathBuf) -> EncryptionResult<()>;
    
    /// Verify password
    fn verify_password(&self, password: &str) -> EncryptionResult<bool>;
}