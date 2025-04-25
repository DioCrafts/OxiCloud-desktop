# OxiCloud Desktop Client

A cross-platform desktop client for OxiCloud, built with Rust and egui.

## Features

- Seamless synchronization with OxiCloud server
- Browse, upload, and download files
- File and folder operations (create, move, rename, delete)
- Offline access to cached files
- Background synchronization
- Secure authentication
- Cross-platform support (Windows, macOS, Linux)

## Development Setup

### Prerequisites

- Rust 1.70.0 or newer
- Cargo package manager
- Git

### Build Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/oxicloud-desktop-client.git
   cd oxicloud-desktop-client
   ```

2. Install dependencies:
   ```bash
   cargo build
   ```

3. Run the application:
   ```bash
   cargo run
   ```

### Development Workflow

- `cargo run` - Run the application in debug mode
- `cargo build --release` - Build the application in release mode
- `cargo test` - Run all tests
- `cargo fmt` - Format code according to Rust style guidelines
- `cargo clippy` - Run linter

## Architecture

This application follows a hexagonal architecture pattern:

- **Domain Layer**: Core business entities and repository interfaces
- **Application Layer**: Services implementing use cases
- **Infrastructure Layer**: Concrete implementations of repositories
- **UI Layer**: User interface components using egui

For more details, see the [Architecture Documentation](ARCHITECTURE.md).

## Dependencies

- [egui](https://github.com/emilk/egui) - Immediate mode GUI library
- [eframe](https://github.com/emilk/egui/tree/master/eframe) - egui framework
- [tokio](https://tokio.rs/) - Asynchronous runtime
- [reqwest](https://github.com/seanmonstar/reqwest) - HTTP client
- [rusqlite](https://github.com/rusqlite/rusqlite) - SQLite bindings

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the same license as the OxiCloud server.

## Documentation

- [Technical Guide](TECHNICAL_GUIDE.md) - Technical implementation details
- [TODO List](TODO.md) - Development roadmap