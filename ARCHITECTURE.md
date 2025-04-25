# OxiCloud Desktop Client - Architecture

This document outlines the architecture for the OxiCloud Desktop Client built with egui and Rust.

## Architectural Overview

The application follows the hexagonal (ports and adapters) architecture pattern, similar to the server implementation:

```
┌────────────────────────────────────────────────────────────────┐
│                        UI Layer (egui)                         │
└───────────────────────────────┬────────────────────────────────┘
                                │
┌───────────────────────────────▼────────────────────────────────┐
│                      Application Layer                         │
│                                                                │
│  ┌─────────────────┐    ┌─────────────────┐    ┌────────────┐  │
│  │  File Service   │    │  Auth Service   │    │  Sync Svc  │  │
│  └────────┬────────┘    └────────┬────────┘    └─────┬──────┘  │
└───────────┼─────────────────────┼────────────────────┼─────────┘
            │                     │                    │
┌───────────▼─────────────────────▼────────────────────▼─────────┐
│                        Domain Layer                             │
│                                                                │
│  ┌─────────────────┐    ┌─────────────────┐    ┌────────────┐  │
│  │      File       │    │      User       │    │   Folder   │  │
│  └─────────────────┘    └─────────────────┘    └────────────┘  │
└───────────┬─────────────────────┬────────────────────┬─────────┘
            │                     │                    │
┌───────────▼─────────────────────▼────────────────────▼─────────┐
│                     Infrastructure Layer                        │
│                                                                │
│  ┌─────────────────┐    ┌─────────────────┐    ┌────────────┐  │
│  │  WebDAV Client  │    │   HTTP Client   │    │ Local DB   │  │
│  └─────────────────┘    └─────────────────┘    └────────────┘  │
└────────────────────────────────────────────────────────────────┘
```

## Layers In Detail

### Domain Layer

Contains the core business logic and entities that are independent of implementation details:

- **Entities**:
  - `File`: Represents a file with metadata
  - `Folder`: Represents a directory with children
  - `User`: Represents user information
  - `Share`: Represents shared resources
  - `TrashedItem`: Represents items in trash

- **Repository Interfaces**:
  - `FileRepository`: Interface for file operations
  - `FolderRepository`: Interface for folder operations
  - `AuthRepository`: Interface for authentication
  - `SyncRepository`: Interface for sync operations

### Application Layer

Orchestrates the flow of data between domain and infrastructure:

- **Services**:
  - `FileService`: Manages file operations
  - `FolderService`: Manages folder operations
  - `AuthService`: Handles authentication flow
  - `SyncService`: Coordinates file synchronization
  - `TrashService`: Manages trash items

- **DTOs**:
  - Data transfer objects matching server API formats

### Infrastructure Layer

Contains concrete implementations of repositories:

- **Adapters**:
  - `WebDavAdapter`: Implements file operations via WebDAV
  - `HttpApiClient`: REST API client for metadata
  - `LocalStorageAdapter`: Local file cache management
  - `SqliteRepository`: Local database for metadata

- **Services**:
  - `ConnectionManager`: Handles network connectivity
  - `CredentialManager`: Securely stores user credentials
  - `BackgroundSyncService`: Handles periodic synchronization

### UI Layer

Implements the user interface using egui:

- **Components**:
  - `FileBrowser`: Main file/folder navigation view
  - `LoginPanel`: Authentication UI
  - `FileOperationsPanel`: UI for file actions
  - `SyncStatusDisplay`: Shows synchronization status
  - `SettingsPanel`: Application configuration

- **App State**:
  - `AppState`: Central egui application state
  - `UIState`: Manages UI transitions and views

## Communication Flow

1. **User Interaction**: User interacts with UI components
2. **Application Services**: UI calls application services
3. **Repository Interfaces**: Services use domain repository interfaces
4. **Infrastructure Adapters**: Concrete implementations handle actual I/O
5. **Server Communication**: WebDAV/HTTP clients talk to the OxiCloud server

## Key Concepts

### Authentication

1. User logs in via UI
2. `AuthService` obtains JWT tokens via `HttpApiClient`
3. Tokens stored securely via `CredentialManager`
4. `ConnectionManager` adds tokens to subsequent requests
5. Token refresh handled automatically by `AuthService`

### File Synchronization

1. `SyncService` orchestrates bidirectional sync
2. Local changes tracked in SQLite database
3. Remote changes detected via WebDAV properties
4. Conflict resolution based on timestamps and strategies
5. Background sync runs periodically using `BackgroundSyncService`

### Offline Support

1. Metadata cached in local SQLite database
2. Files cached on disk using `LocalStorageAdapter`
3. Changes during offline mode tracked for later sync
4. UI indicates sync status and pending changes

## Data Storage

1. **File Content**: Cached locally in user-configurable location
2. **Metadata**: Stored in SQLite database:
   - File/folder structure
   - Sync state and timestamps
   - User preferences
3. **Credentials**: Stored securely using OS-specific mechanisms

## Technology Stack

- **UI Framework**: egui + eframe
- **HTTP Client**: reqwest
- **WebDAV Client**: Custom implementation (or existing crate like dav-client)
- **Database**: rusqlite or sqlx for SQLite
- **Async Runtime**: tokio
- **Serialization**: serde + serde_json
- **Logging**: log + env_logger
- **Error Handling**: anyhow + thiserror