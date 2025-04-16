use serde::{Serialize, Deserialize};
use std::time::Duration;
use thiserror::Error;
use chrono::{DateTime, Utc};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncEventType {
    SyncRequested,
    FileChanged(String),
    ConflictResolved {
        file_id: String,
        direction: SyncDirection,
    },
    StateChanged,
    Error(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncEvent {
    pub event_type: SyncEventType,
    pub file_id: Option<String>,
    pub message: Option<String>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Error)]
pub enum SyncError {
    #[error("Network error: {0}")]
    NetworkError(String),
    
    #[error("Authentication error: {0}")]
    AuthError(String),
    
    #[error("File system error: {0}")]
    FileSystemError(String),
    
    #[error("Conflicting changes: {0}")]
    ConflictError(String),
    
    #[error("Synchronization error: {0}")]
    SyncError(String),
    
    #[error("File error: {0}")]
    FileError(#[from] crate::domain::entities::file::FileError),
    
    #[error("Synchronization already in progress")]
    AlreadySyncing,
    
    #[error("Synchronization service not started")]
    NotStarted,
    
    #[error("File not in conflict state")]
    NotInConflict,
    
    #[error("Operation error: {0}")]
    OperationError(String),
    
    #[error("Encryption error: {0}")]
    EncryptionError(String),
    
    #[error("IO error: {0}")]
    IOError(String),
}

pub type SyncResult<T> = Result<T, SyncError>;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncState {
    Idle,
    Syncing,
    Paused,
    Error(String),
    Stopped,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum SyncDirection {
    Upload,
    Download,
    Bidirectional,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncStatus {
    pub state: SyncState,
    pub last_sync: Option<DateTime<Utc>>,
    pub current_operation: Option<String>,
    pub current_file: Option<String>,
    pub total_files: u32,
    pub processed_files: u32,
    pub total_bytes: u64,
    pub processed_bytes: u64,
    pub error_message: Option<String>,
}

impl Default for SyncStatus {
    fn default() -> Self {
        Self {
            state: SyncState::Idle,
            last_sync: None,
            current_operation: None,
            current_file: None,
            total_files: 0,
            processed_files: 0,
            total_bytes: 0,
            processed_bytes: 0,
            error_message: None,
        }
    }
}

impl SyncStatus {
    pub fn progress_percentage(&self) -> f32 {
        if self.total_files == 0 {
            return 0.0;
        }
        
        (self.processed_files as f32 / self.total_files as f32) * 100.0
    }
    
    pub fn reset(&mut self) {
        self.state = SyncState::Idle;
        self.current_operation = None;
        self.current_file = None;
        self.total_files = 0;
        self.processed_files = 0;
        self.total_bytes = 0;
        self.processed_bytes = 0;
        self.error_message = None;
    }
    
    pub fn start_sync(&mut self, total_files: u32, total_bytes: u64) {
        self.state = SyncState::Syncing;
        self.current_operation = Some("Preparing synchronization".to_string());
        self.total_files = total_files;
        self.processed_files = 0;
        self.total_bytes = total_bytes;
        self.processed_bytes = 0;
        self.error_message = None;
    }
    
    pub fn update_progress(&mut self, file_name: String, operation: String, processed_files: u32, processed_bytes: u64) {
        self.current_file = Some(file_name);
        self.current_operation = Some(operation);
        self.processed_files = processed_files;
        self.processed_bytes = processed_bytes;
    }
    
    pub fn complete_sync(&mut self) {
        self.state = SyncState::Idle;
        self.last_sync = Some(Utc::now());
        self.current_operation = None;
        self.current_file = None;
    }
    
    pub fn set_error(&mut self, error_message: String) {
        self.state = SyncState::Error;
        self.error_message = Some(error_message);
    }
    
    pub fn pause(&mut self) {
        self.state = SyncState::Paused;
    }
    
    pub fn resume(&mut self) {
        self.state = SyncState::Syncing;
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConfig {
    pub enabled: bool,
    pub sync_interval: Duration,
    pub sync_on_startup: bool,
    pub sync_on_file_change: bool,
    pub sync_direction: SyncDirection,
    pub excluded_paths: Vec<String>,
    pub max_concurrent_transfers: u32,
    pub bandwidth_limit_kbps: Option<u32>,
    pub sync_hidden_files: bool,
    pub auto_resolve_conflicts: bool,
}

impl Default for SyncConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            sync_interval: Duration::from_secs(300),  // 5 minutes
            sync_on_startup: true,
            sync_on_file_change: true,
            sync_direction: SyncDirection::Bidirectional,
            excluded_paths: vec![
                ".git".to_string(),
                ".DS_Store".to_string(),
                "Thumbs.db".to_string(),
                "desktop.ini".to_string(),
            ],
            max_concurrent_transfers: 3,
            bandwidth_limit_kbps: None,
            sync_hidden_files: false,
            auto_resolve_conflicts: false,
        }
    }
}
