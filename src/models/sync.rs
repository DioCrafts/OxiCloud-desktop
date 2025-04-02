use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConfig {
    pub enabled: bool,
    pub interval_seconds: u64,
    pub sync_on_startup: bool,
    pub sync_hidden_files: bool,
    pub bandwidth_limit_kbps: Option<u32>,
    pub sync_folders: Vec<SyncFolder>,
    pub excluded_patterns: Vec<String>,
    pub max_sync_retries: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncFolder {
    pub remote_path: String,
    pub local_path: PathBuf,
    pub enabled: bool,
    pub sync_mode: SyncMode,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SyncMode {
    TwoWay,        // Cambios locales y remotos se sincronizan en ambas direcciones
    UploadOnly,    // Solo subir cambios locales al servidor
    DownloadOnly,  // Solo descargar cambios del servidor
    VirtualFiles,  // Archivos virtuales, solo metadatos hasta que se accede
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncLog {
    pub id: String,
    pub timestamp: DateTime<Utc>,
    pub status: SyncLogStatus,
    pub message: String,
    pub items_processed: usize,
    pub items_succeeded: usize,
    pub items_failed: usize,
    pub duration_seconds: u64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum SyncLogStatus {
    Success,
    PartialSuccess,
    Failure,
    Cancelled,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncConflict {
    pub id: String,
    pub file_name: String,
    pub remote_path: String,
    pub local_path: PathBuf,
    pub detected_at: DateTime<Utc>,
    pub resolved: bool,
    pub resolution_type: Option<ConflictResolutionType>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub enum ConflictResolutionType {
    KeepLocal,
    KeepRemote,
    KeepBoth,
    Manual,
}