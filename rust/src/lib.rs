//! # OxiCloud Core
//!
//! Cross-platform sync engine for OxiCloud, providing:
//! - WebDAV client for server communication
//! - File system watching for local changes
//! - SQLite database for sync state
//! - Conflict detection and resolution
//!
//! This crate is designed to be used via FFI from Flutter/Dart.

pub mod api;
pub mod domain;
pub mod application;
pub mod infrastructure;

// Re-export main API for FFI
pub use api::*;

// Re-export commonly used types
pub use domain::entities::{SyncItem, SyncStatus, SyncDirection, ConflictResolution};
pub use domain::ports::{SyncPort, StoragePort, AuthPort, FileWatcherPort};
pub use application::sync_service::SyncService;
pub use application::auth_service::AuthService;

/// Initialize the core library
/// Call this once at app startup
pub fn init() {
    // Initialize tracing for logging
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::INFO.into())
        )
        .init();
    
    tracing::info!("OxiCloud Core initialized");
}
