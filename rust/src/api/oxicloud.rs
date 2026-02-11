//! # OxiCloud API Module
//!
//! Public API exposed to Flutter via flutter_rust_bridge FFI.
//! All types used here are auto-exported to Dart by FRB codegen.

use std::sync::Arc;
use tokio::sync::RwLock;
use flutter_rust_bridge::frb;

use crate::domain::entities::{
    SyncItem, SyncStatus, SyncDirection, SyncConfig, AuthCredentials, ServerInfo,
    ConflictType, ConflictResolution, ConflictInfo,
};
use crate::application::sync_service::SyncService;
use crate::application::auth_service::AuthService;
use crate::infrastructure::webdav_client::WebDavClient;
use crate::infrastructure::sqlite_storage::SqliteStorage;
use crate::infrastructure::file_watcher::NotifyFileWatcher;

/// Global state for the sync engine
static SYNC_ENGINE: RwLock<Option<Arc<SyncEngine>>> = RwLock::const_new(None);

/// Main sync engine that coordinates all operations
struct SyncEngine {
    sync_service: Arc<SyncService>,
    auth_service: Arc<AuthService>,
    config: SyncConfig,
}

// ============================================================================
// INITIALIZATION
// ============================================================================

/// Initialize the sync engine with configuration.
/// Must be called before any other operation.
pub async fn initialize(config: SyncConfig) -> Result<(), String> {
    tracing::info!("Initializing sync engine");

    let storage = Arc::new(
        SqliteStorage::new(&config.database_path)
            .await
            .map_err(|e| format!("Failed to initialize storage: {}", e))?
    );

    let webdav = Arc::new(WebDavClient::new());

    let watcher = Arc::new(
        NotifyFileWatcher::new()
            .map_err(|e| format!("Failed to initialize file watcher: {}", e))?
    );

    let auth_service = Arc::new(AuthService::new(storage.clone()));
    let sync_service = Arc::new(SyncService::new(
        storage.clone(),
        webdav.clone(),
        watcher.clone(),
        config.clone(),
    ));

    let engine = Arc::new(SyncEngine {
        sync_service,
        auth_service,
        config,
    });

    let mut global = SYNC_ENGINE.write().await;
    *global = Some(engine);

    tracing::info!("Sync engine initialized successfully");
    Ok(())
}

/// Shutdown the sync engine gracefully
pub async fn shutdown() -> Result<(), String> {
    let mut global = SYNC_ENGINE.write().await;
    if let Some(engine) = global.take() {
        engine.sync_service.stop().await;
    }
    Ok(())
}

// ============================================================================
// AUTHENTICATION
// ============================================================================

/// Login to OxiCloud server
pub async fn login(
    server_url: String,
    username: String,
    password: String,
) -> Result<AuthResult, String> {
    let engine = get_engine().await?;
    let credentials = AuthCredentials {
        server_url,
        username,
        password,
    };
    engine.auth_service
        .login(credentials)
        .await
        .map_err(|e| format!("Login failed: {}", e))
}

/// Logout and clear credentials
pub async fn logout() -> Result<(), String> {
    let engine = get_engine().await?;
    engine.auth_service.logout().await;
    Ok(())
}

/// Check if user is logged in
pub async fn is_logged_in() -> Result<bool, String> {
    let engine = get_engine().await?;
    Ok(engine.auth_service.is_logged_in().await)
}

/// Get current server info
pub async fn get_server_info() -> Result<Option<ServerInfo>, String> {
    let engine = get_engine().await?;
    Ok(engine.auth_service.get_server_info().await)
}

// ============================================================================
// SYNCHRONIZATION
// ============================================================================

/// Start automatic synchronization
pub async fn start_sync() -> Result<(), String> {
    let engine = get_engine().await?;
    engine.sync_service.start().await
        .map_err(|e| format!("Failed to start sync: {}", e))
}

/// Stop automatic synchronization
pub async fn stop_sync() -> Result<(), String> {
    let engine = get_engine().await?;
    engine.sync_service.stop().await;
    Ok(())
}

/// Trigger immediate sync
pub async fn sync_now() -> Result<SyncResult, String> {
    let engine = get_engine().await?;
    engine.sync_service.sync_now().await
        .map_err(|e| format!("Sync failed: {}", e))
}

/// Get current sync status
pub async fn get_sync_status() -> Result<SyncStatusInfo, String> {
    let engine = get_engine().await?;
    Ok(engine.sync_service.get_status().await)
}

/// Get list of items pending sync
pub async fn get_pending_items() -> Result<Vec<SyncItem>, String> {
    let engine = get_engine().await?;
    engine.sync_service.get_pending_items().await
        .map_err(|e| format!("Failed to get pending items: {}", e))
}

/// Get sync history
pub async fn get_sync_history(limit: u32) -> Result<Vec<SyncHistoryEntry>, String> {
    let engine = get_engine().await?;
    engine.sync_service.get_history(limit).await
        .map_err(|e| format!("Failed to get history: {}", e))
}

// ============================================================================
// SELECTIVE SYNC
// ============================================================================

/// Get list of remote folders for selective sync
pub async fn get_remote_folders() -> Result<Vec<RemoteFolder>, String> {
    let engine = get_engine().await?;
    engine.sync_service.get_remote_folders().await
        .map_err(|e| format!("Failed to get remote folders: {}", e))
}

/// Set folders to sync (selective sync)
pub async fn set_sync_folders(folder_ids: Vec<String>) -> Result<(), String> {
    let engine = get_engine().await?;
    engine.sync_service.set_sync_folders(folder_ids).await
        .map_err(|e| format!("Failed to set sync folders: {}", e))
}

/// Get currently selected sync folders
pub async fn get_sync_folders() -> Result<Vec<String>, String> {
    let engine = get_engine().await?;
    Ok(engine.sync_service.get_sync_folders().await)
}

// ============================================================================
// CONFLICT RESOLUTION
// ============================================================================

/// Get list of conflicts
pub async fn get_conflicts() -> Result<Vec<SyncConflict>, String> {
    let engine = get_engine().await?;
    engine.sync_service.get_conflicts().await
        .map_err(|e| format!("Failed to get conflicts: {}", e))
}

/// Resolve a conflict
pub async fn resolve_conflict(
    conflict_id: String,
    resolution: ConflictResolution,
) -> Result<(), String> {
    let engine = get_engine().await?;
    engine.sync_service.resolve_conflict(&conflict_id, resolution).await
        .map_err(|e| format!("Failed to resolve conflict: {}", e))
}

// ============================================================================
// SETTINGS
// ============================================================================

/// Update sync configuration
pub async fn update_config(config: SyncConfig) -> Result<(), String> {
    let engine = get_engine().await?;
    engine.sync_service.update_config(config).await
        .map_err(|e| format!("Failed to update config: {}", e))
}

/// Get current sync configuration
pub async fn get_config() -> Result<SyncConfig, String> {
    let engine = get_engine().await?;
    Ok(engine.config.clone())
}

// ============================================================================
// API-SPECIFIC TYPES (types not in domain but needed for the API contract)
// ============================================================================

/// Authentication result
#[frb]
#[derive(Debug, Clone)]
pub struct AuthResult {
    pub success: bool,
    pub user_id: String,
    pub username: String,
    pub server_info: ServerInfo,
    pub access_token: String,
}

/// Sync operation result
#[frb]
#[derive(Debug, Clone)]
pub struct SyncResult {
    pub success: bool,
    pub items_uploaded: u32,
    pub items_downloaded: u32,
    pub items_deleted: u32,
    pub conflicts: u32,
    pub errors: Vec<String>,
    pub duration_ms: u64,
}

/// Current sync status info
#[frb]
#[derive(Debug, Clone)]
pub struct SyncStatusInfo {
    pub is_syncing: bool,
    pub current_operation: Option<String>,
    pub progress_percent: f32,
    pub items_synced: u32,
    pub items_total: u32,
    pub last_sync_time: Option<i64>,
    pub next_sync_time: Option<i64>,
}

/// Sync history entry
#[frb]
#[derive(Debug, Clone)]
pub struct SyncHistoryEntry {
    pub id: String,
    pub timestamp: i64,
    pub operation: String,
    pub item_path: String,
    pub direction: String,
    pub status: String,
    pub error_message: Option<String>,
}

/// Remote folder info for selective sync
#[frb]
#[derive(Debug, Clone)]
pub struct RemoteFolder {
    pub id: String,
    pub name: String,
    pub path: String,
    pub size_bytes: u64,
    pub item_count: u32,
    pub is_selected: bool,
}

/// Sync conflict info (API view)
#[frb]
#[derive(Debug, Clone)]
pub struct SyncConflict {
    pub id: String,
    pub item_path: String,
    pub local_modified: i64,
    pub remote_modified: i64,
    pub local_size: u64,
    pub remote_size: u64,
    pub conflict_type: ConflictType,
}

// ============================================================================
// HELPERS
// ============================================================================

/// Get the global engine
async fn get_engine() -> Result<Arc<SyncEngine>, String> {
    let global = SYNC_ENGINE.read().await;
    global.clone().ok_or_else(|| "Sync engine not initialized. Call initialize() first.".to_string())
}
