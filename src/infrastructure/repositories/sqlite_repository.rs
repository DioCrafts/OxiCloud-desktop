use r2d2::Pool;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite::{Connection, Result as SqliteResult};
use std::fs;
use std::path::Path;

/// Type alias for a SQLite connection pool
pub type ConnectionPool = Pool<SqliteConnectionManager>;

/// Creates a SQLite connection pool
pub fn create_connection_pool(db_name: &str) -> Result<Pool<SqliteConnectionManager>, r2d2::Error> {
    // Get the application data directory
    let app_data_dir = dirs::data_dir()
        .unwrap_or_else(|| Path::new(".").to_path_buf())
        .join("OxiCloud");
    
    // Create the application data directory if it doesn't exist
    if !app_data_dir.exists() {
        fs::create_dir_all(&app_data_dir).expect("Failed to create application data directory");
    }
    
    // Create the database path
    let db_path = app_data_dir.join(db_name);
    
    // Create the connection manager
    let manager = SqliteConnectionManager::file(db_path);
    
    // Create the connection pool
    let pool = r2d2::Pool::builder()
        .max_size(10)
        .build(manager)?;
    
    // Initialize the database schema
    initialize_database(&pool)?;
    
    Ok(pool)
}

/// Initialize the database schema
fn initialize_database(pool: &Pool<SqliteConnectionManager>) -> SqliteResult<()> {
    let conn = pool.get().expect("Failed to get database connection");
    
    // Enable foreign keys
    conn.execute("PRAGMA foreign_keys = ON", [])?;
    
    // Create the files table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS files (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            file_type TEXT NOT NULL,
            size INTEGER NOT NULL,
            mime_type TEXT,
            parent_id TEXT,
            created_at TEXT NOT NULL,
            modified_at TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            is_favorite INTEGER NOT NULL,
            local_path TEXT,
            encryption_status TEXT NOT NULL,
            encryption_iv TEXT,
            encryption_metadata TEXT,
            
            FOREIGN KEY (parent_id) REFERENCES files(id) ON DELETE CASCADE
        )",
        [],
    )?;
    
    // Create the sync_status table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sync_status (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            state TEXT NOT NULL,
            last_sync TEXT,
            current_operation TEXT,
            current_file TEXT,
            total_files INTEGER NOT NULL,
            processed_files INTEGER NOT NULL,
            total_bytes INTEGER NOT NULL,
            processed_bytes INTEGER NOT NULL,
            error_message TEXT
        )",
        [],
    )?;
    
    // Create the sync_events table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sync_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_type TEXT NOT NULL,
            file_id TEXT,
            message TEXT,
            timestamp TEXT NOT NULL
        )",
        [],
    )?;
    
    // Create the sync_config table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS sync_config (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            enabled INTEGER NOT NULL,
            sync_interval_secs INTEGER NOT NULL,
            sync_on_startup INTEGER NOT NULL,
            sync_on_file_change INTEGER NOT NULL,
            sync_direction TEXT NOT NULL,
            max_concurrent_transfers INTEGER NOT NULL,
            bandwidth_limit_kbps INTEGER,
            sync_hidden_files INTEGER NOT NULL,
            auto_resolve_conflicts INTEGER NOT NULL
        )",
        [],
    )?;
    
    // Create the excluded_paths table
    conn.execute(
        "CREATE TABLE IF NOT EXISTS excluded_paths (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL UNIQUE
        )",
        [],
    )?;
    
    // Create index for file paths
    conn.execute("CREATE INDEX IF NOT EXISTS idx_files_path ON files(path)", [])?;
    
    // Create index for file parents
    conn.execute("CREATE INDEX IF NOT EXISTS idx_files_parent ON files(parent_id)", [])?;
    
    // Insert default sync config if it doesn't exist
    let config_count: i64 = conn.query_row(
        "SELECT COUNT(*) FROM sync_config",
        [],
        |row| row.get(0),
    )?;
    
    if config_count == 0 {
        conn.execute(
            "INSERT INTO sync_config (
                enabled, sync_interval_secs, sync_on_startup, sync_on_file_change,
                sync_direction, max_concurrent_transfers, bandwidth_limit_kbps,
                sync_hidden_files, auto_resolve_conflicts
            ) VALUES (
                1, 300, 1, 1, 'Bidirectional', 3, NULL, 0, 0
            )",
            [],
        )?;
    }
    
    // Insert default sync status if it doesn't exist
    let status_count: i64 = conn.query_row(
        "SELECT COUNT(*) FROM sync_status",
        [],
        |row| row.get(0),
    )?;
    
    if status_count == 0 {
        conn.execute(
            "INSERT INTO sync_status (
                state, total_files, processed_files, total_bytes, processed_bytes
            ) VALUES (
                'Idle', 0, 0, 0, 0
            )",
            [],
        )?;
    }
    
    Ok(())
}