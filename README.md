# OxiCloud Desktop Client

A lightweight, fast, and reliable desktop synchronization client for OxiCloud built with Rust and Dioxus.

<p align="center">
  <img src="./screenshots/app-preview.png" alt="OxiCloud Desktop Client" width="700">
</p>

## Features

- **Native Performance**: Built with Rust for exceptional speed and reliability
- **Efficient Synchronization**: Smart sync algorithm minimizes bandwidth and storage usage
- **Cross-Platform**: Works on Windows, macOS, and Linux with native look and feel
- **Selective Sync**: Choose which folders to sync to save local disk space
- **File On-Demand**: Access cloud files without consuming local storage
- **Conflict Resolution**: Smart handling of file conflicts with user-friendly resolution
- **Offline Support**: Work with files offline and sync when connection is restored
- **Advanced Security**: End-to-end encryption with post-quantum resistance, supporting multiple algorithms (AES-256-GCM, ChaCha20-Poly1305, Kyber768, Dilithium5, and hybrid modes)

## Installation

### Pre-built Packages

Download the latest release for your platform:

- [Windows Installer](https://github.com/yourusername/oxicloud-desktop/releases/latest)
- [macOS DMG](https://github.com/yourusername/oxicloud-desktop/releases/latest)
- [Linux AppImage](https://github.com/yourusername/oxicloud-desktop/releases/latest)

### Build from Source

Requirements:
- Rust 1.70 or higher
- pkg-config (on Linux)
- OpenSSL development libraries

```bash
# Clone the repository
git clone https://github.com/yourusername/oxicloud-desktop.git
cd oxicloud-desktop

# Build the application
cargo build --release

# Run the application
cargo run --release
```

## Configuration

On first run, you'll be prompted to enter your OxiCloud server details:

- Server URL: The URL of your OxiCloud server (e.g., https://oxicloud.example.com)
- Username and Password: Your OxiCloud credentials

Configuration is stored in:
- Windows: `%APPDATA%\OxiCloud\config.json`
- macOS: `~/Library/Application Support/OxiCloud/config.json`
- Linux: `~/.config/oxicloud/config.json`

You can customize application settings through the Settings page, including:
- UI theme (Light, Dark, System)
- Sync configuration (automatic, manual, or scheduled)
- Network bandwidth limits
- Performance settings
- Advanced options (logging, crash reporting, etc.)

## Technical Documentation

### Architecture

OxiCloud Desktop Client is built using a hexagonal (ports and adapters) architecture that separates core domain logic from external concerns:

```
oxicloud-desktop/
├── domain/           # Core business logic and entities
│   ├── entities/     # Domain models (File, User, Sync)
│   ├── repositories/ # Repository interfaces
│   └── services/     # Core business services
│
├── application/      # Application services and use cases
│   ├── ports/        # Input/output port interfaces
│   ├── services/     # Application-specific services
│   └── dtos/         # Data transfer objects
│
├── infrastructure/   # External implementations
│   ├── adapters/     # Adapters for external services
│   ├── repositories/ # Repository implementations
│   └── services/     # Infrastructure services
│
└── interfaces/       # User interfaces
    ├── app.rs        # Main application entry
    ├── pages/        # UI pages
    └── components/   # Reusable UI components
```

### Core Technologies

- **Rust**: Memory-safe systems language for reliable performance
- **Dioxus**: Reactive UI framework for building cross-platform interfaces
- **SQLite**: Local database for metadata and sync state
- **Tokio**: Asynchronous runtime for efficient I/O operations
- **WebDAV/HTTP**: Protocols for communication with OxiCloud server

### Building for Different Platforms

#### Windows

```bash
# Cross-compile from Linux/macOS
rustup target add x86_64-pc-windows-msvc
cargo build --release --target x86_64-pc-windows-msvc

# Build on Windows
cargo build --release

# Create installer using cargo-wix (on Windows)
cargo install cargo-wix
cargo wix
```

#### macOS

```bash
# Cross-compile from Linux/Windows
rustup target add x86_64-apple-darwin
cargo build --release --target x86_64-apple-darwin

# Build on macOS
cargo build --release

# Create DMG package (on macOS)
cargo install cargo-bundle
cargo bundle --release
```

#### Linux

```bash
# Build on Linux
cargo build --release

# Create AppImage
cargo install cargo-appimage
cargo appimage
```

### Sync Engine

The sync engine operates with these components:

1. **Change Detection**: Monitors local filesystem changes
2. **Metadata Storage**: Tracks file states and sync status
3. **File Transfer**: Handles up/downloads with chunking for large files
4. **Conflict Resolution**: Detects and manages conflicts between versions
5. **Selective Sync**: Manages exclusion rules for folders

### Security

- All authentication credentials are stored securely using the system's keychain/credential store
- Data is encrypted in transit using TLS
- Local database can be encrypted for additional security
- Tokens are refreshed automatically and stored securely
- End-to-end encryption (E2EE) with post-quantum resistance
- Support for multiple encryption algorithms (AES-256-GCM, ChaCha20-Poly1305)
- Hybrid encryption with post-quantum algorithms (Kyber768, Dilithium5)
- Secure key management with password-based key derivation
- Chunked file processing with parallel encryption/decryption for large files
- Integrity verification using authenticated encryption

For detailed information about the encryption system:
- [User Encryption Guide](docs/ENCRYPTION.md) - End-user guide to encryption features
- [Developer Encryption Documentation](docs/DEVELOPER_ENCRYPTION.md) - Technical implementation details

### Development Workflow

```bash
# Run in development mode
cargo run

# Run tests
cargo test                                 # Run all tests
cargo test encryption_tests                # Run encryption unit tests
cargo test file_encryption_tests           # Run file encryption tests
cargo test encryption_sync_integration_tests # Run integration tests

# Format code
cargo fmt

# Check for issues
cargo clippy
```

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## Roadmap

See our [TODO.md](TODO.md) file for the development plan.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Dioxus](https://dioxuslabs.com/) - for the reactive UI framework
- [Rust](https://www.rust-lang.org/) - for the incredible language
- [OxiCloud](https://github.com/yourusername/OxiCloud) - for the server implementation