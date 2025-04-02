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
- **Advanced Security**: Secure authentication and local data encryption

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

## Comparison with Nextcloud Client

Unlike the Nextcloud client which is built with C++ and Qt, OxiCloud Desktop Client leverages modern Rust with Dioxus for several advantages:

| Feature | OxiCloud Desktop | Nextcloud Client |
|---------|------------------|------------------|
| **Technology** | Rust + Dioxus | C++ + Qt |
| **Memory Safety** | Guaranteed at compile time | Manual management |
| **Binary Size** | ~10MB | ~100MB |
| **Resource Usage** | Low | Moderate |
| **UI Responsiveness** | High | Good |
| **Concurrency Model** | Async/Await | Thread-based |
| **Maintenance** | Modern codebase | Legacy components |

## Development

The project is organized using a clean architecture pattern:

```
oxicloud-desktop/
├── src/
│   ├── components/     # UI components
│   ├── models/         # Data structures
│   ├── services/       # Business logic
│   ├── utils/          # Helper functions
│   └── main.rs         # Application entry
```

### Key commands:

```bash
# Run in development mode
cargo run

# Run tests
cargo test

# Check code quality
cargo clippy

# Format code
cargo fmt
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