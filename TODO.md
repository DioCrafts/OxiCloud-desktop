# OxiCloud Desktop Client - TODO List

## Phase 1: Project Setup and Basic Structure
- [x] Create project directory
- [ ] Initialize Rust project with Cargo
- [ ] Set up egui and eframe dependencies
- [ ] Create basic application window
- [ ] Design module structure following hexagonal architecture
- [ ] Define core domain models matching server entities
- [ ] Setup logging and error handling

## Phase 2: Authentication and API Connection
- [ ] Implement HTTP client for REST API
- [ ] Create authentication service (login, token management)
- [ ] Implement token refresh mechanism
- [ ] Add secure credential storage
- [ ] Create login UI with egui
- [ ] Test connection to OxiCloud server

## Phase 3: File System Navigation
- [ ] Implement WebDAV client for file operations
- [ ] Create file browser UI component
- [ ] Implement folder navigation
- [ ] Add file/folder context menus
- [ ] Display file metadata (size, modification date)
- [ ] Implement file icons based on MIME type

## Phase 4: File Operations
- [ ] Implement file upload functionality
- [ ] Implement file download
- [ ] Add file deletion (move to trash)
- [ ] Implement file renaming
- [ ] Create folder creation interface
- [ ] Add drag-and-drop support
- [ ] Implement progress indicators for operations

## Phase 5: Synchronization Engine
- [ ] Design local database for metadata storage
- [ ] Implement file change detection
- [ ] Create bidirectional sync mechanism
- [ ] Handle sync conflicts
- [ ] Add offline mode support
- [ ] Implement background sync service

## Phase 6: Advanced Features
- [ ] Add file sharing functionality
- [ ] Implement trash management
- [ ] Add favorites/bookmarks
- [ ] Create settings panel (sync frequency, cache size)
- [ ] Implement search functionality
- [ ] Add file preview for common formats

## Phase 7: Polish and Performance
- [ ] Optimize memory usage for large directories
- [ ] Improve UI responsiveness
- [ ] Add keyboard shortcuts
- [ ] Create system tray integration
- [ ] Implement notifications for sync events
- [ ] Add dark/light theme support
- [ ] Create proper error handling and user feedback

## Phase 8: Packaging and Distribution
- [ ] Create build pipeline for different platforms
- [ ] Add auto-update mechanism
- [ ] Create installers for Windows/macOS/Linux
- [ ] Write user documentation
- [ ] Test on different operating systems