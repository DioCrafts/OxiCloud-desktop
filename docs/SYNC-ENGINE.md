# OxiCloud Sync Engine

This document describes the synchronization engine implemented in Rust.

## Overview

The sync engine is responsible for:
- **Bidirectional synchronization** between local filesystem and remote OxiCloud server
- **Conflict detection and resolution**
- **Delta sync** for efficient bandwidth usage
- **Real-time file watching** for instant sync
- **Offline support** with automatic reconnection

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     SYNC SERVICE                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                  SyncOrchestrator                     │    │
│  │  - Coordinates all sync operations                    │    │
│  │  - Manages sync queue                                 │    │
│  │  - Handles errors and retries                         │    │
│  └───────────────┬─────────────────┬─────────────────────┘    │
│                  │                 │                          │
│    ┌─────────────┴──────┐  ┌──────┴─────────────┐           │
│    │   LocalScanner     │  │   RemoteScanner    │           │
│    │                    │  │                    │           │
│    │ - Scans local      │  │ - Lists remote     │           │
│    │   filesystem       │  │   directory        │           │
│    │ - Computes hashes  │  │ - Gets metadata    │           │
│    │ - Detects changes  │  │ - Detects changes  │           │
│    └────────────────────┘  └────────────────────┘           │
│                                                              │
│    ┌─────────────────────────────────────────────────────┐  │
│    │                 ChangeDetector                       │  │
│    │  - Compares local vs remote state                   │  │
│    │  - Identifies: new, modified, deleted, moved        │  │
│    │  - Detects conflicts                                │  │
│    └─────────────────────────────────────────────────────┘  │
│                                                              │
│    ┌─────────────────────────────────────────────────────┐  │
│    │                  SyncExecutor                        │  │
│    │  - Uploads local changes                            │  │
│    │  - Downloads remote changes                         │  │
│    │  - Handles chunked transfers                        │  │
│    │  - Implements delta sync                            │  │
│    └─────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Sync Algorithm

### Full Sync Cycle

```
1. SCAN LOCAL
   ├─ Walk filesystem recursively
   ├─ Read file metadata (size, mtime)
   ├─ Compute content hash for modified files
   └─ Store in local state DB

2. SCAN REMOTE
   ├─ WebDAV PROPFIND request
   ├─ Parse remote file list
   ├─ Extract metadata (etag, size, mtime)
   └─ Store in local state DB

3. DETECT CHANGES
   ├─ Compare local_state vs remote_state
   ├─ Identify: NEW, MODIFIED, DELETED, MOVED
   ├─ Detect CONFLICTS (both modified)
   └─ Generate sync actions queue

4. EXECUTE ACTIONS
   ├─ Process conflicts (user resolution)
   ├─ Upload local changes
   ├─ Download remote changes
   ├─ Apply deletions
   └─ Update state DB

5. CLEANUP
   ├─ Remove orphaned entries
   ├─ Update last_sync timestamp
   └─ Schedule next sync
```

### Change Detection

| Local State | Remote State | Action |
|-------------|--------------|--------|
| New | Not exists | Upload |
| Not exists | New | Download |
| Modified | Unchanged | Upload |
| Unchanged | Modified | Download |
| Modified | Modified | CONFLICT |
| Deleted | Unchanged | Delete remote |
| Unchanged | Deleted | Delete local |
| Deleted | Modified | CONFLICT |
| Modified | Deleted | CONFLICT |

### Conflict Resolution

Conflicts are detected when both local and remote have been modified since last sync.

Resolution strategies:
- **Keep Local**: Upload local version, overwrite remote
- **Keep Remote**: Download remote version, overwrite local
- **Keep Both**: Rename one file with conflict suffix
- **Manual**: Ask user to decide

```rust
pub enum ConflictResolution {
    KeepLocal,
    KeepRemote,
    KeepBoth,
    Manual,
}
```

## Delta Sync

For large files, delta sync minimizes bandwidth by:

1. Computing file signature (rolling checksum blocks)
2. Sending signature to server
3. Server computes diff
4. Only changed blocks are transferred

```rust
pub struct DeltaSync {
    block_size: usize,       // typically 4KB
    strong_hash: Algorithm,  // SHA256
    weak_hash: Algorithm,    // Rolling checksum
}
```

Supported when:
- Server reports `supportsDeltaSync: true`
- File size > threshold (e.g., 1MB)
- Previous version exists on both sides

## File Watching

Real-time sync using filesystem events:

```rust
pub trait FileWatcherPort: Send + Sync {
    fn watch(&self, path: &Path) -> Result<()>;
    fn unwatch(&self, path: &Path) -> Result<()>;
    fn events(&self) -> impl Stream<Item = FileChangeEvent>;
}

pub struct FileChangeEvent {
    pub path: PathBuf,
    pub kind: ChangeKind,
    pub timestamp: SystemTime,
}

pub enum ChangeKind {
    Created,
    Modified,
    Deleted,
    Renamed { from: PathBuf },
}
```

Events are debounced (300ms default) to batch rapid changes.

## State Storage

Sync state is persisted in SQLite:

```sql
-- Items table
CREATE TABLE sync_items (
    id TEXT PRIMARY KEY,
    local_path TEXT,
    remote_path TEXT,
    item_type TEXT,           -- 'file' or 'folder'
    local_mtime INTEGER,
    remote_mtime INTEGER,
    local_size INTEGER,
    remote_size INTEGER,
    local_hash TEXT,
    remote_etag TEXT,
    sync_state TEXT,          -- 'synced', 'pending_upload', 'pending_download', 'conflict'
    last_synced_at INTEGER,
    error_message TEXT
);

-- Conflicts table
CREATE TABLE conflicts (
    id TEXT PRIMARY KEY,
    item_id TEXT REFERENCES sync_items(id),
    local_modified INTEGER,
    remote_modified INTEGER,
    local_size INTEGER,
    remote_size INTEGER,
    conflict_type TEXT,
    created_at INTEGER,
    resolved_at INTEGER,
    resolution TEXT
);
```

## WebDAV Implementation

### Supported Operations

| Operation | WebDAV Method | Description |
|-----------|---------------|-------------|
| List | PROPFIND | List directory contents |
| Upload | PUT | Upload file |
| Download | GET | Download file |
| Delete | DELETE | Delete file/folder |
| Mkdir | MKCOL | Create directory |
| Move | MOVE | Move/rename item |
| Copy | COPY | Copy item |

### Chunked Upload

Large files are uploaded in chunks:

```rust
pub struct ChunkedUpload {
    chunk_size: usize,        // 10MB default
    max_retries: u32,         // 3 default
    retry_delay: Duration,    // exponential backoff
}
```

Upload flow:
1. Initiate upload session
2. Upload chunks with Content-Range header
3. Finalize upload
4. Verify checksum

### Authentication

Supported methods:
- Basic Auth (username/password)
- Bearer Token (OAuth/OIDC)
- App Passwords

## Configuration

```rust
pub struct SyncConfig {
    // Sync behavior
    pub sync_folder: PathBuf,
    pub sync_interval_seconds: u32,
    pub watch_filesystem: bool,
    
    // Bandwidth
    pub max_upload_speed_kbps: u32,    // 0 = unlimited
    pub max_download_speed_kbps: u32,
    
    // Delta sync
    pub delta_sync_enabled: bool,
    pub delta_min_file_size: u64,
    
    // Network
    pub pause_on_metered: bool,
    pub wifi_only: bool,
    
    // Ignore patterns
    pub ignore_patterns: Vec<String>,
}
```

## Selective Sync

Users can choose which folders to sync:

```rust
pub struct SelectiveSync {
    /// Root folders available on server
    pub available_folders: Vec<RemoteFolder>,
    
    /// Currently selected folder IDs
    pub selected_folder_ids: HashSet<String>,
}

impl SelectiveSync {
    pub fn is_included(&self, path: &Path) -> bool {
        // Check if path is within selected folders
    }
    
    pub fn update_selection(&mut self, folder_ids: Vec<String>) {
        // Remove unselected folders from local
        // Download newly selected folders
    }
}
```

## Error Handling & Retry

```rust
pub enum SyncError {
    // Network errors - retryable
    NetworkError(String),
    ServerError(u16, String),
    Timeout,
    
    // Auth errors - require re-auth
    Unauthorized,
    SessionExpired,
    
    // Permanent errors
    NotFound,
    PermissionDenied,
    QuotaExceeded,
    InvalidPath,
    
    // Local errors
    IoError(std::io::Error),
    DatabaseError(String),
}

impl SyncError {
    pub fn is_retryable(&self) -> bool {
        matches!(self, 
            Self::NetworkError(_) | 
            Self::ServerError(5xx, _) | 
            Self::Timeout
        )
    }
}
```

Retry strategy:
- Max 3 retries
- Exponential backoff: 1s, 2s, 4s
- Skip after permanent errors

## Performance Optimizations

1. **Parallel operations**: Multiple files synced concurrently
2. **Streaming uploads**: Large files streamed, not loaded to memory
3. **Hash caching**: File hashes cached based on mtime
4. **Batch API calls**: Group small operations
5. **Connection pooling**: Reuse HTTP connections

```rust
pub struct SyncLimits {
    pub max_concurrent_uploads: usize,    // 4
    pub max_concurrent_downloads: usize,  // 4
    pub max_file_size: u64,               // 50GB
    pub max_files_per_batch: usize,       // 100
}
```

## Monitoring & Logging

```rust
pub struct SyncMetrics {
    pub items_uploaded: u64,
    pub items_downloaded: u64,
    pub bytes_uploaded: u64,
    pub bytes_downloaded: u64,
    pub conflicts_detected: u64,
    pub errors: u64,
    pub duration_ms: u64,
}
```

Log levels:
- **ERROR**: Sync failures, data loss prevention
- **WARN**: Conflicts, retries, degraded operation
- **INFO**: Sync start/complete, major operations
- **DEBUG**: Detailed sync decisions
- **TRACE**: Every file operation
