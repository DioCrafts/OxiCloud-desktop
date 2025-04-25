# OxiCloud Desktop Client - Technical Guide

This document provides technical details for implementing the OxiCloud Desktop Client with egui and Rust.

## Project Setup

### Initial Setup

```bash
# Create project
cargo new --bin oxicloud-desktop-client
cd oxicloud-desktop-client

# Add dependencies to Cargo.toml
```

### Core Dependencies

```toml
[dependencies]
# UI Framework
egui = "0.23.0"
eframe = "0.23.0"
egui_extras = "0.23.0"

# Async/HTTP
tokio = { version = "1.28.0", features = ["full"] }
reqwest = { version = "0.11.20", features = ["json", "rustls-tls"] }

# WebDAV
http = "0.2.9"
bytes = "1.4.0"
quick-xml = "0.30.0"
base64 = "0.21.2"

# Database
rusqlite = { version = "0.29.0", features = ["bundled"] }
tokio-rusqlite = "0.4.0"

# Serialization
serde = { version = "1.0.183", features = ["derive"] }
serde_json = "1.0.104"

# Utilities
chrono = { version = "0.4.26", features = ["serde"] }
dirs = "5.0.1"
uuid = { version = "1.4.1", features = ["v4", "serde"] }
mime_guess = "2.0.4"
image = { version = "0.24.7", features = ["jpeg", "png", "webp"] }

# Security
rsa = "0.9.2"
sha2 = "0.10.7"
rand = "0.8.5"
keyring = "2.0.5"

# Error handling
anyhow = "1.0.72"
thiserror = "1.0.44"

# Logging
log = "0.4.19"
env_logger = "0.10.0"
```

## Project Structure

```
src/
├── main.rs                    # Application entry point
├── app.rs                     # Main egui application
├── domain/                    # Domain layer
│   ├── models/                # Domain entities
│   │   ├── file.rs
│   │   ├── folder.rs
│   │   ├── user.rs
│   │   └── ...
│   └── repositories/          # Repository interfaces
│       ├── file_repository.rs
│       ├── auth_repository.rs
│       └── ...
├── application/               # Application layer
│   ├── services/              # Business logic services
│   │   ├── auth_service.rs
│   │   ├── file_service.rs
│   │   ├── sync_service.rs
│   │   └── ...
│   └── dtos/                  # Data transfer objects
│       ├── file_dto.rs
│       ├── user_dto.rs
│       └── ...
├── infrastructure/            # Infrastructure layer
│   ├── adapters/              # Repository implementations
│   │   ├── webdav_adapter.rs
│   │   ├── http_client.rs
│   │   ├── sqlite_repository.rs
│   │   └── ...
│   └── services/              # Infrastructure services
│       ├── credential_manager.rs
│       ├── connection_manager.rs
│       └── ...
└── ui/                        # User interface
    ├── app_state.rs           # Application state
    ├── components/            # UI components
    │   ├── login_panel.rs
    │   ├── file_browser.rs
    │   ├── settings_panel.rs
    │   └── ...
    └── views/                 # Main application views
        ├── main_view.rs
        ├── login_view.rs
        └── ...
```

## WebDAV Integration

The OxiCloud server provides WebDAV compatibility, which we'll use for file operations. Key considerations:

### Authentication

WebDAV requests need to include the authentication token:

```rust
// Example WebDAV request with token
let client = reqwest::Client::new();
let response = client
    .request(Method::PROPFIND, url)
    .header("Authorization", format!("Bearer {}", token))
    .header("Depth", "1")
    .body(propfind_xml)
    .send()
    .await?;
```

### Core WebDAV Operations

1. **PROPFIND**: List directories and get file metadata
2. **GET**: Download files
3. **PUT**: Upload files
4. **DELETE**: Remove files
5. **MKCOL**: Create directories
6. **MOVE**: Move or rename files/folders
7. **COPY**: Copy files/folders

### WebDAV XML Format

WebDAV relies on XML for requests and responses:

```rust
// Example PROPFIND request
fn build_propfind_xml() -> String {
    r#"<?xml version="1.0" encoding="utf-8" ?>
    <D:propfind xmlns:D="DAV:">
        <D:prop>
            <D:resourcetype/>
            <D:getcontentlength/>
            <D:getlastmodified/>
            <D:displayname/>
            <D:getetag/>
        </D:prop>
    </D:propfind>"#.to_string()
}
```

## SQLite Database Design

The client will use SQLite for local metadata storage:

```sql
-- Files and folders table
CREATE TABLE items (
    id TEXT PRIMARY KEY,
    parent_id TEXT,
    name TEXT NOT NULL,
    path TEXT NOT NULL UNIQUE,
    size INTEGER,
    modified_at TEXT,
    etag TEXT,
    is_folder BOOLEAN NOT NULL,
    mime_type TEXT,
    local_path TEXT,
    sync_status TEXT NOT NULL,
    FOREIGN KEY (parent_id) REFERENCES items(id)
);

-- Sync state table
CREATE TABLE sync_state (
    path TEXT PRIMARY KEY,
    local_modified_at TEXT,
    remote_modified_at TEXT,
    local_etag TEXT,
    remote_etag TEXT,
    sync_status TEXT NOT NULL,
    last_synced_at TEXT
);

-- User settings table
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
```

## File Cache Management

For efficient offline access, implement a local file cache:

```rust
// Example cache strategy
struct FileCache {
    cache_dir: PathBuf,
    max_size_bytes: u64,
}

impl FileCache {
    // Check if file is in cache
    fn is_cached(&self, file_id: &str) -> bool { /* ... */ }
    
    // Get file from cache
    fn get_file(&self, file_id: &str) -> Result<PathBuf> { /* ... */ }
    
    // Store file in cache
    fn store_file(&self, file_id: &str, data: &[u8]) -> Result<()> { /* ... */ }
    
    // Evict files to maintain size limit
    fn evict_oldest_files(&self) -> Result<()> { /* ... */ }
}
```

## Synchronization Engine

Design a robust sync algorithm that:

1. Tracks local and remote changes
2. Resolves conflicts (newest wins or user prompt)
3. Handles errors and retries
4. Works incrementally for large directories

```rust
// Example sync algorithm flow
async fn sync_directory(&self, path: &str) -> Result<()> {
    // 1. Get remote state
    let remote_items = self.webdav.list_directory(path).await?;
    
    // 2. Get local state
    let local_items = self.db.get_items_in_directory(path)?;
    
    // 3. Compare and determine changes
    let (to_download, to_upload, conflicts) = self.diff_items(local_items, remote_items);
    
    // 4. Handle conflicts
    self.resolve_conflicts(conflicts).await?;
    
    // 5. Apply changes
    self.download_items(to_download).await?;
    self.upload_items(to_upload).await?;
    
    // 6. Update sync state
    self.db.update_sync_state(path)?;
    
    Ok(())
}
```

## egui UI Implementation

Structure the UI for optimal user experience:

```rust
// Main application structure
struct OxiCloudApp {
    state: AppState,
    auth_service: Arc<AuthService>,
    file_service: Arc<FileService>,
    sync_service: Arc<SyncService>,
    ui_state: UiState,
}

// Example implementation
impl eframe::App for OxiCloudApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        // Check authentication status
        if !self.state.is_authenticated {
            self.render_login_view(ctx);
            return;
        }
        
        // Layout main UI
        egui::TopBottomPanel::top("top_panel").show(ctx, |ui| {
            // Top navigation bar
            self.render_top_bar(ui);
        });
        
        egui::SidePanel::left("file_tree").show(ctx, |ui| {
            // Folder tree view
            self.render_folder_tree(ui);
        });
        
        egui::CentralPanel::default().show(ctx, |ui| {
            // Main file browser
            self.render_file_browser(ui);
        });
        
        // Handle background tasks
        self.process_background_tasks(ctx);
    }
}
```

## Security Considerations

1. **Token Storage**: Use system keychain for secure storage
2. **File Encryption**: Consider encrypting cached files
3. **HTTPS**: Ensure all connections use TLS
4. **Token Refresh**: Implement proper token refresh logic

## Error Handling

Create a centralized error handling strategy:

```rust
// Define application errors
#[derive(thiserror::Error, Debug)]
enum AppError {
    #[error("Authentication failed: {0}")]
    AuthError(String),
    
    #[error("Network error: {0}")]
    NetworkError(#[from] reqwest::Error),
    
    #[error("Database error: {0}")]
    DbError(#[from] rusqlite::Error),
    
    #[error("File system error: {0}")]
    FsError(#[from] std::io::Error),
    
    #[error("WebDAV error: {0}")]
    WebDavError(String),
    
    #[error("Synchronization error: {0}")]
    SyncError(String),
}

// Use Result type with this error
type Result<T> = std::result::Result<T, AppError>;
```

## Performance Optimizations

1. **Lazy Loading**: Only load visible directory contents
2. **Pagination**: Support paging for large directories
3. **Thumbnails**: Generate and cache thumbnails for images
4. **Background Processing**: Handle long operations asynchronously
5. **Incremental Sync**: Only sync changed files

## Testing Strategy

1. **Unit Tests**: Test individual components in isolation
2. **Integration Tests**: Test interactions between components
3. **Mock Server**: Create a mock WebDAV server for testing
4. **UI Tests**: Test UI components with mock data

```rust
// Example test
#[cfg(test)]
mod tests {
    use super::*;
    
    #[tokio::test]
    async fn test_file_download() {
        // Setup test environment
        let mock_webdav = MockWebDavAdapter::new();
        let mock_db = MockSqliteRepository::new();
        let file_service = FileService::new(mock_webdav, mock_db);
        
        // Test file download
        let result = file_service.download_file("test_file.txt").await;
        assert!(result.is_ok());
        
        // Verify correct behavior
        assert!(mock_webdav.verify_download_called("test_file.txt"));
        assert!(mock_db.verify_update_called("test_file.txt"));
    }
}
```