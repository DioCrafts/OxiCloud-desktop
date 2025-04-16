use serde::{Serialize, Deserialize};
use chrono::{DateTime, Utc};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum FileError {
    #[error("Invalid file name: {0}")]
    InvalidFileName(String),
    
    #[error("Validation error: {0}")]
    ValidationError(String),
    
    #[error("File operation error: {0}")]
    OperationError(String),
    
    #[error("Not found: {0}")]
    NotFoundError(String),
    
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Authentication error: {0}")]
    AuthenticationError(String),
    
    #[error("Permission error: {0}")]
    PermissionError(String),
    
    #[error("Server error: {0}")]
    ServerError(String),
    
    #[error("Format error: {0}")]
    FormatError(String),
    
    #[error("IO error: {0}")]
    IOError(String),
    
    #[error("Invalid argument: {0}")]
    InvalidArgumentError(String),
    
    #[error("Encryption error: {0}")]
    EncryptionError(String),
    
    #[error("Decryption error: {0}")]
    DecryptionError(String),
}

pub type FileResult<T> = Result<T, FileError>;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum FileType {
    File,
    Image,
    Video,
    Audio,
    Document,
    Spreadsheet,
    Presentation,
    Folder,
    Other,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncStatus {
    Synced,
    Syncing,
    PendingUpload,
    PendingDownload,
    Error,
    Conflicted,
    Ignored,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum EncryptionStatus {
    /// File is encrypted with E2EE
    Encrypted,
    /// File is being encrypted
    Encrypting,
    /// File is being decrypted
    Decrypting,
    /// File is not encrypted
    Unencrypted,
    /// There was an error with encryption/decryption
    Error,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileItem {
    pub id: String,
    pub name: String,
    pub path: String,
    pub file_type: FileType,
    pub size: u64,
    pub mime_type: Option<String>,
    pub parent_id: Option<String>,
    pub created_at: DateTime<Utc>,
    pub modified_at: DateTime<Utc>,
    pub sync_status: SyncStatus,
    pub is_favorite: bool,
    pub local_path: Option<String>,
    /// Whether file is encrypted with E2EE
    pub encryption_status: EncryptionStatus,
    /// Initialization vector for encryption (in Base64)
    pub encryption_iv: Option<String>,
    /// Public metadata about encryption (algorithm, key version, etc.)
    pub encryption_metadata: Option<String>,
}

impl FileItem {
    pub fn new_file(
        id: String,
        name: String,
        path: String,
        size: u64,
        mime_type: Option<String>,
        parent_id: Option<String>,
        local_path: Option<String>,
    ) -> Self {
        let now = Utc::now();
        Self {
            id,
            name,
            path,
            file_type: FileType::File,
            size,
            mime_type,
            parent_id,
            created_at: now,
            modified_at: now,
            sync_status: SyncStatus::Synced,
            is_favorite: false,
            local_path,
            encryption_status: EncryptionStatus::Unencrypted,
            encryption_iv: None,
            encryption_metadata: None,
        }
    }
    
    pub fn new_directory(
        id: String,
        name: String,
        path: String,
        parent_id: Option<String>,
        local_path: Option<String>,
    ) -> Self {
        let now = Utc::now();
        Self {
            id,
            name,
            path,
            file_type: FileType::Folder,
            size: 0,
            mime_type: None,
            parent_id,
            created_at: now,
            modified_at: now,
            sync_status: SyncStatus::Synced,
            is_favorite: false,
            local_path,
            encryption_status: EncryptionStatus::Unencrypted,
            encryption_iv: None,
            encryption_metadata: None,
        }
    }
    
    pub fn is_directory(&self) -> bool {
        self.file_type == FileType::Folder
    }
    
    pub fn update_sync_status(&mut self, status: SyncStatus) {
        self.sync_status = status;
    }
    
    pub fn extension(&self) -> Option<&str> {
        if self.is_directory() {
            return None;
        }
        self.name.split('.').last()
    }
    
    pub fn formatted_size(&self) -> String {
        if self.is_directory() {
            return "Directory".to_string();
        }
        
        if self.size < 1024 {
            return format!("{} B", self.size);
        } else if self.size < 1024 * 1024 {
            return format!("{:.1} KB", self.size as f64 / 1024.0);
        } else if self.size < 1024 * 1024 * 1024 {
            return format!("{:.1} MB", self.size as f64 / (1024.0 * 1024.0));
        } else {
            return format!("{:.1} GB", self.size as f64 / (1024.0 * 1024.0 * 1024.0));
        }
    }
    
    pub fn set_favorite(&mut self, is_favorite: bool) {
        self.is_favorite = is_favorite;
    }
    
    pub fn is_encrypted(&self) -> bool {
        matches!(self.encryption_status, EncryptionStatus::Encrypted)
    }
    
    pub fn set_encrypted(&mut self, iv: String, metadata: String) {
        self.encryption_status = EncryptionStatus::Encrypted;
        self.encryption_iv = Some(iv);
        self.encryption_metadata = Some(metadata);
    }
    
    pub fn set_unencrypted(&mut self) {
        self.encryption_status = EncryptionStatus::Unencrypted;
        self.encryption_iv = None;
        self.encryption_metadata = None;
    }
}