# OxiCloud Rust Core

This is the native Rust core for OxiCloud sync client, providing high-performance file synchronization.

## Structure

```
src/
├── lib.rs                 # Library entry point
├── api.rs                 # FFI API for Flutter (flutter_rust_bridge)
├── domain/
│   ├── mod.rs
│   ├── entities/          # Core business entities
│   │   ├── sync_item.rs
│   │   ├── sync_status.rs
│   │   ├── config.rs
│   │   └── auth.rs
│   └── ports/             # Trait definitions (interfaces)
│       ├── sync_port.rs
│       ├── storage_port.rs
│       ├── auth_port.rs
│       └── file_watcher_port.rs
├── application/           # Business logic services
│   ├── mod.rs
│   ├── sync_service.rs
│   ├── auth_service.rs
│   └── file_watcher_service.rs
└── infrastructure/        # Concrete implementations
    ├── mod.rs
    ├── webdav_client.rs
    ├── sqlite_storage.rs
    └── file_watcher.rs
```

## Building

### Prerequisites

- Rust 1.75+ (with `cargo`)
- For cross-compilation: platform-specific toolchains

### Development

```bash
# Check compilation
cargo check

# Run tests
cargo test

# Build release
cargo build --release
```

### Cross-Compilation

For building on different platforms, you'll need the appropriate targets:

```bash
# Add targets
rustup target add x86_64-pc-windows-gnu
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
rustup target add x86_64-unknown-linux-gnu
rustup target add aarch64-linux-android
rustup target add aarch64-apple-ios

# Build for specific target
cargo build --target x86_64-pc-windows-gnu --release
```

## FFI Generation

Bindings are generated using `flutter_rust_bridge`:

```bash
# From Flutter project root
flutter_rust_bridge_codegen generate
```

This generates:
- `src/frb_generated.rs` - Rust FFI glue
- `lib/src/rust/` - Dart bindings

## Key Components

### API (`api.rs`)

Public functions exposed to Flutter:

```rust
// Authentication
pub fn login(server_url: String, username: String, password: String) -> Result<AuthSession>;
pub fn logout() -> Result<()>;
pub fn is_logged_in() -> bool;

// Sync
pub fn start_sync() -> Result<()>;
pub fn stop_sync() -> Result<()>;
pub fn sync_now() -> Result<SyncResult>;
pub fn get_sync_status() -> SyncStatus;

// Config
pub fn update_config(config: SyncConfig) -> Result<()>;
pub fn get_config() -> SyncConfig;
```

### WebDAV Client

Implements OxiCloud/NextCloud WebDAV protocol:
- PROPFIND for listing
- GET/PUT for transfer
- MKCOL for directories
- DELETE, MOVE, COPY
- Chunked uploads for large files

### SQLite Storage

Persists sync state locally:
- File metadata (path, size, mtime, etag)
- Sync status (synced, pending, conflict)
- Conflict history
- Auth tokens (encrypted)

### File Watcher

Real-time filesystem monitoring using `notify` crate:
- Cross-platform (inotify/FSEvents/ReadDirectoryChanges)
- Debounced events
- Recursive watching

## Testing

```bash
# Unit tests
cargo test --lib

# Integration tests (requires mock server)
cargo test --test integration

# With logging
RUST_LOG=debug cargo test
```

## Performance

The Rust core is optimized for:
- **Memory efficiency**: Streaming file transfers
- **CPU efficiency**: Parallel hash computation
- **Network efficiency**: Connection pooling, delta sync
- **Battery efficiency**: Intelligent scheduling on mobile

## Dependencies

Key dependencies:
- `reqwest` - HTTP client
- `rusqlite` - SQLite database
- `notify` - Filesystem events
- `tokio` - Async runtime
- `serde` - Serialization
- `flutter_rust_bridge` - Flutter FFI
