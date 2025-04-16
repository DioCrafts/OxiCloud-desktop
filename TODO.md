# OxiCloud Desktop Client TODO List

This document outlines the implementation plan for the OxiCloud Desktop Client built with Dioxus and Rust.

## MVP Status

The Minimum Viable Product (MVP) core components have been completed:
- [x] Authentication system with token-based auth and credential storage
- [x] File operations and UI for basic browsing
- [x] End-to-end encryption with post-quantum resistance
- [x] SQLite database for local file tracking
- [x] Bidirectional sync algorithm with conflict detection
- [x] File system monitoring with debouncing and event filtering
- [x] System integration with system tray, notifications and autostart

The remaining tasks below are for enhancing the MVP with additional features.

## Phase 1: Core Framework and UI

### Setup & Configuration
- [x] Create project structure
- [x] Setup Dioxus framework
- [x] Design basic UI layout and components
- [x] Implement theme system (light/dark mode)
- [x] Create configuration file format
- [x] Add settings persistence

### Authentication
- [x] Implement login screen
- [x] Add token-based authentication
- [x] Create secure credential storage (keyring)
- [x] Add session renewal mechanism
- [ ] Implement account management UI
- [ ] Add server connection test utilities

### Basic File Operations UI
- [x] Implement file browser component
- [x] Create folder navigation system
- [x] Add file/folder creation UI
- [x] Implement file selection mechanisms
- [ ] Add drag & drop support
- [x] Create context menus for file operations
- [ ] Implement progress indicators for operations

## Phase 2: Synchronization Engine

### Local Database
- [x] Design SQLite schema for file metadata
- [x] Implement database initialization
- [x] Create data access layer
- [ ] Add migration system for updates
- [x] Implement efficient query patterns

### File System Monitoring
- [x] Setup filesystem watcher with notify
- [x] Create event filtering system
- [x] Implement debounce mechanism for rapid changes
- [x] Add exclusion pattern support
- [x] Create change queue system

### Sync Algorithm
- [x] Implement initial sync logic
- [x] Create two-way sync algorithm
- [x] Add conflict detection
- [x] Implement conflict resolution UI
- [x] Create sync state machine
- [x] Add retry mechanism for failed operations
- [x] Implement bandwidth limiting

### API Integration
- [x] Create HTTP client with authentication
- [x] Implement file upload/download logic 
- [x] Add folder operation support
- [ ] Implement trash bin integration
- [ ] Create sharing API support
- [x] Add favorites synchronization
- [ ] Implement batch operations for efficiency

## Phase 3: Advanced Features

### Selective Sync
- [ ] Create folder selection UI
- [ ] Implement selective sync logic
- [ ] Add exclude patterns support
- [ ] Create sync status indicators
- [ ] Implement quota visualization

### Virtual Files
- [ ] Research platform-specific implementations
- [ ] Implement placeholder files
- [ ] Create on-demand download system
- [ ] Add automatic file pinning logic
- [ ] Implement status badges in file explorer

### Offline Support
- [ ] Implement offline change detection
- [ ] Create pending changes queue
- [ ] Add background sync on reconnection
- [ ] Implement offline mode indicator
- [ ] Create network status monitoring

### Performance Optimizations
- [x] Implement chunked uploads for large files
- [x] Add parallel processing for encryption/decryption
- [ ] Add delta sync for modified files
- [ ] Create background operation queue
- [ ] Implement adaptive sync intervals
- [x] Add parallel operation support

### Security Features
- [x] Implement end-to-end encryption with post-quantum resistance
- [x] Support multiple encryption algorithms (AES, ChaCha20, Kyber, Dilithium)
- [x] Create hybrid encryption mode for defense in depth
- [x] Add key management with password-based protection
- [ ] Implement secure key sharing between devices
- [ ] Add support for hardware security modules (HSMs)

## Phase 4: User Experience

### System Integration
- [x] Add system tray icon
- [x] Implement desktop notifications
- [x] Create startup options
- [ ] Add auto-update mechanism
- [ ] Implement shell integration

### Logging & Diagnostics
- [ ] Implement comprehensive logging system
- [ ] Create log viewer UI
- [ ] Add diagnostic information collection
- [ ] Implement sync issues detection
- [ ] Create troubleshooting assistant

### Polish & Refinement
- [ ] Create comprehensive error handling
- [ ] Improve accessibility support
- [ ] Add keyboard shortcuts
- [ ] Create user onboarding experience
- [ ] Add localization support
- [ ] Implement usage statistics

## Phase 5: Distribution

### Packaging
- [ ] Create Windows installer
- [ ] Build macOS .app bundle
- [ ] Package Linux AppImage/Flatpak
- [ ] Implement auto-update system
- [ ] Add installation documentation

### Testing & Quality
- [ ] Implement unit test framework
- [ ] Create integration tests
- [ ] Implement UI testing
- [ ] Add performance benchmarks
- [ ] Create security review process