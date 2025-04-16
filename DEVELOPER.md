# OxiCloud Desktop Client - Developer Documentation

This document provides detailed technical information for developers contributing to the OxiCloud Desktop Client project.

## Architecture Overview

The application follows a hexagonal (ports and adapters) architecture to ensure separation of concerns and testability:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────┐      ┌─────────────────────────────┐   │
│  │    Domain       │      │        Application          │   │
│  │                 │      │                             │   │
│  │ ┌─────────────┐ │      │ ┌─────────────┐            │   │
│  │ │  Entities   │ │      │ │    Ports    │            │   │
│  │ └─────────────┘ │      │ └─────────────┘            │   │
│  │                 │      │                             │   │
│  │ ┌─────────────┐ │      │ ┌─────────────┐            │   │
│  │ │  Services   │◄┼──────┼─┤   Services  │            │   │
│  │ └─────────────┘ │      │ └─────────────┘            │   │
│  │                 │      │                             │   │
│  │ ┌─────────────┐ │      │ ┌─────────────┐            │   │
│  │ │ Repository  │ │      │ │    DTOs     │            │   │
│  │ │ Interfaces  │ │      │ └─────────────┘            │   │
│  │ └─────────────┘ │      │                             │   │
│  └────────┬────────┘      └─────────────┬───────────────┘   │
│           │                             │                   │
│           │                             │                   │
│  ┌────────▼─────────────────────────────▼───────────────┐   │
│  │                Infrastructure                         │   │
│  │                                                       │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │  Adapters   │  │Repositories │  │  Services   │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  │                                                       │   │
│  └───────────────────────────┬───────────────────────────┘   │
│                              │                               │
│                              │                               │
│  ┌───────────────────────────▼───────────────────────────┐   │
│  │                    Interfaces                          │   │
│  │                                                        │   │
│  │   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │   │    Pages    │  │ Components  │  │     UI      │   │   │
│  │   └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  │                                                        │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

### Core Layers

1. **Domain Layer**: Contains business logic entities, repository interfaces, and core services
2. **Application Layer**: Contains use cases, DTOs, and application-specific services
3. **Infrastructure Layer**: Contains implementations of repositories and external service adapters
4. **Interface Layer**: Contains UI components and pages

## Development Environment Setup

### Prerequisites

- **Rust**: Version 1.70.0 or higher
- **Dioxus CLI**: For hot reloading during development
- **SQLite**: Development libraries for database access
- **OpenSSL**: Development libraries for secure connections

### Setup Commands

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Dioxus CLI
cargo install dioxus-cli

# Install additional build dependencies (Ubuntu/Debian)
sudo apt-get install pkg-config libssl-dev libsqlite3-dev

# Clone repository
git clone https://github.com/yourusername/oxicloud-desktop.git
cd oxicloud-desktop

# Set up Git hooks
cp hooks/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

## Development Workflow

### Building and Running

```bash
# Development build with hot reloading
dx serve

# Development build (standard)
cargo run

# Release build
cargo build --release
```

### Testing

```bash
# Run all tests
cargo test

# Run specific test
cargo test <test_name>

# Run tests in a specific module
cargo test domain::entities::file

# Run tests with logging
RUST_LOG=debug cargo test
```

### Code Quality

```bash
# Format code
cargo fmt

# Run linter
cargo clippy

# Check for issues
cargo check
```

## Project Structure Details

### Domain Layer

- **Entities**: Core business objects (User, File, SyncStatus)
- **Repositories**: Interfaces defining data access
- **Services**: Business logic services

Example entity:
```rust
// src/domain/entities/file.rs
pub struct FileItem {
    pub id: String,
    pub name: String,
    pub path: String,
    pub file_type: FileType,
    pub size: u64,
    pub sync_status: SyncStatus,
    // ...
}
```

### Application Layer

- **Ports**: Input/output interfaces for application use cases
- **DTOs**: Data transfer objects for external communication
- **Services**: Application-specific service implementations

Example port:
```rust
// src/application/ports/file_port.rs
#[async_trait]
pub trait FilePort: Send + Sync + 'static {
    async fn get_file(&self, file_id: &str) -> FileResult<FileDto>;
    async fn list_files(&self, folder_id: Option<&str>) -> FileResult<Vec<FileDto>>;
    // ...
}
```

### Infrastructure Layer

- **Adapters**: Implementations for external services (API, WebDAV)
- **Repositories**: Concrete implementations of repository interfaces
- **Services**: Infrastructure-specific services

Example implementation:
```rust
// src/infrastructure/adapters/file_adapter.rs
pub struct FileApiAdapter {
    client: Client,
    auth_repository: Arc<dyn AuthRepository>,
}

#[async_trait]
impl FileRepository for FileApiAdapter {
    async fn get_file_by_id(&self, file_id: &str) -> FileResult<FileItem> {
        // Implementation using HTTP API
        let server_url = self.get_server_url().await?;
        let token = self.get_auth_token().await?;
        
        let api_url = format!("{}/api/files/{}", server_url.trim_end_matches('/'), file_id);
        
        let response = self.client
            .get(&api_url)
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .await
            .map_err(|e| FileError::NetworkError(e.to_string()))?;

        // Process response...
        
        Ok(file_item)
    }
    // ...
}
```

### Interface Layer

- **Components**: Reusable UI components
- **Pages**: Application screens
- **Hooks**: Custom React-like hooks for Dioxus

Example page:
```rust
// src/interfaces/pages/files.rs
#[component]
pub fn FilesPage(cx: Scope) -> Element {
    let files = use_state(cx, || vec![/* ... */]);
    
    cx.render(rsx! {
        div { class: "app-container",
            Sidebar {}
            
            div { class: "main-content",
                FileList {
                    files: files.get().clone(),
                    on_file_click: handle_file_click,
                    // ...
                }
            }
        }
    })
}
```

## Sync Engine Details

The synchronization engine is the core feature of the application:

### Components

1. **File Watcher**: Monitors local filesystem changes using `notify` crate
2. **Metadata Database**: SQLite database tracking file state
3. **Transfer Engine**: Handles efficient file transfers (chunking, delta sync)
4. **Change Processor**: Processes local and remote changes
5. **Conflict Resolver**: Detects and manages conflicting changes
6. **Selective Sync Manager**: Handles exclusion patterns
7. **Scheduler**: Manages periodic sync and reconnection attempts

### Sync Process Flow

```
  ┌───────────────┐              ┌───────────────┐
  │   Local FS    │              │  OxiCloud     │
  │   Changes     │              │   Server      │
  └───────┬───────┘              └───────┬───────┘
          │                              │
          │                              │
  ┌───────▼───────┐              ┌───────▼───────┐
  │  File Watcher │              │  API Client   │
  └───────┬───────┘              └───────┬───────┘
          │                              │
          │                              │
  ┌───────▼───────────────────────▼──────┐
  │                                      │
  │        Change Detector               │
  │                                      │
  └──────────────┬──────────────────────┬┘
                 │                      │
    ┌────────────▼─────┐     ┌──────────▼─────────┐
    │                  │     │                    │
    │  Local Changes   │     │  Remote Changes    │
    │                  │     │                    │
    └────────┬─────────┘     └─────────┬──────────┘
             │                         │
             │                         │
    ┌────────▼─────────────────────────▼──────────┐
    │                                             │
    │              Change Processor               │
    │                                             │
    └────┬──────────────────────────┬────────────┬┘
         │                          │            │
┌────────▼─────────┐      ┌─────────▼──────┐    │
│                  │      │                │    │
│  Conflict        │      │  Transfer      │    │
│  Resolver        │      │  Engine        │    │
│                  │      │                │    │
└─────────┬────────┘      └────────┬───────┘    │
          │                        │            │
          │                        │            │
┌─────────▼────────────────────────▼────────────▼───┐
│                                                   │
│                  Metadata Database                │
│                                                   │
└───────────────────────────────────────────────────┘
```

## Cross-Platform Considerations

### Windows-specific

- Uses native Windows notifications
- Supports Windows Explorer integration
- Handles long paths gracefully
- Uses system keychain for credentials

### macOS-specific

- Supports macOS Finder integration
- Uses system keychain for credentials
- Respects macOS application bundle structure

### Linux-specific

- Supports multiple desktop environments
- Uses D-Bus for notifications
- Respects XDG specifications for file locations

## Packaging and Distribution

### Windows

- Uses WiX Toolset for MSI creation
- Supports silent installation
- Manages application registry entries

### macOS

- Bundle structure follows Apple guidelines
- Code signing for Gatekeeper compatibility
- Creates .app package and DMG installer

### Linux

- Creates AppImage for distribution across distributions
- Provides .deb and .rpm packages for specific distributions
- Follows Freedesktop standards

## Common Issues and Solutions

### Build Problems

- **Windows**: Ensure you have the MSVC build tools installed
- **macOS**: Make sure XCode command line tools are installed
- **Linux**: Install all required development libraries

### Runtime Issues

- **SQLite Locking**: Use proper connection pooling
- **File System Monitoring**: Handle events debouncing
- **Large File Transfer**: Implement chunking and resumable uploads

## API Integration

The client communicates with OxiCloud server using:

1. **REST API**: For file metadata and user operations
2. **WebDAV**: For file upload/download operations

API requests include:
- Authorization headers with tokens
- Content-Type specifications
- ETag handling for change detection

## Performance Optimization

Key optimizations include:

1. **File Chunking**: Splits large files into manageable pieces
2. **Parallelization**: Uses Tokio for parallel processing
3. **Delta Sync**: Only transmits changed portions of files
4. **Database Indexing**: Optimizes metadata queries
5. **Caching**: Implements in-memory cache for frequent operations

## Security Considerations

Security measures implemented:

1. **Credential Storage**: Uses system keychain
2. **TLS**: Enforces secure connections
3. **Token Refresh**: Implements OAuth token refresh flow
4. **Encryption**: Option for local database encryption
5. **Certificate Pinning**: Validates server certificates