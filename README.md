# OxiCloud App

Cross-platform desktop and mobile application for OxiCloud, built with **Flutter** (UI) and **Rust** (core sync engine).

## 🎯 Features

- **Automatic file synchronization** with OxiCloud server
- **Selective sync** - choose which folders to sync
- **Conflict detection and resolution**
- **System tray integration** (desktop)
- **Background sync** (mobile)
- **Offline support** with local SQLite database
- **Bandwidth throttling** controls

## 🏗️ Architecture

This project follows **Clean Architecture** with **Hexagonal Architecture** principles:

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                             │
│              (Flutter UI - Pages, Widgets, BLoCs)               │
├─────────────────────────────────────────────────────────────────┤
│                          DOMAIN                                 │
│           (Entities, Use Cases, Repository Interfaces)          │
├─────────────────────────────────────────────────────────────────┤
│                           DATA                                  │
│              (Repository Impl, Data Sources, Models)            │
├─────────────────────────────────────────────────────────────────┤
│                      RUST CORE (FFI)                            │
│         (Sync Engine, WebDAV Client, File Watcher)              │
└─────────────────────────────────────────────────────────────────┘
```

### Why Rust + Flutter?

| Component | Technology | Reason |
|-----------|------------|--------|
| **UI** | Flutter/Dart | Single codebase for 5 platforms |
| **Sync Engine** | Rust | Performance, memory safety, shared with server |
| **Storage** | SQLite (Rust) | Fast local database |
| **Protocol** | WebDAV | Standard, compatible with OxiCloud server |

## 📁 Project Structure

```
oxicloud-app/
├── rust/                           # 🦀 RUST CORE (Native)
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs                  # FFI exports
│       ├── api.rs                  # Public API for Flutter
│       ├── domain/                 # Domain layer
│       │   ├── entities/           # Core entities
│       │   └── ports/              # Port interfaces
│       ├── application/            # Use cases & services
│       └── infrastructure/         # Adapters (WebDAV, SQLite, etc.)
│
├── lib/                            # 🎨 FLUTTER UI (Dart)
│   ├── main.dart                   # Entry point
│   ├── core/                       # Domain layer (Dart)
│   │   ├── entities/               # Business entities
│   │   ├── repositories/           # Repository interfaces
│   │   └── usecases/               # Application use cases
│   ├── data/                       # Data layer
│   │   ├── datasources/            # Data sources (Rust bridge)
│   │   ├── models/                 # Data models
│   │   └── repositories/           # Repository implementations
│   └── presentation/               # Presentation layer
│       ├── blocs/                  # State management (BLoC)
│       ├── pages/                  # Screen pages
│       └── widgets/                # Reusable widgets
│
├── pubspec.yaml                    # Flutter dependencies
├── analysis_options.yaml           # Dart linter rules
└── README.md                       # This file
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Rust 1.70+
- Android Studio / Xcode (for mobile)
- Visual Studio Build Tools (for Windows)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/diocrafts/oxicloud.git
   cd oxicloud/oxicloud-app
   ```

2. **Install Rust dependencies**
   ```bash
   cd rust
   cargo build --release
   cd ..
   ```

3. **Generate Rust-Flutter bindings**
   ```bash
   flutter pub get
   flutter_rust_bridge_codegen generate
   ```

4. **Run the app**
   ```bash
   # Desktop (Linux/macOS/Windows)
   flutter run -d linux
   flutter run -d macos
   flutter run -d windows

   # Mobile
   flutter run -d android
   flutter run -d ios
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

## 🔧 Configuration

Create a `.env` file or configure through the app settings:

```env
OXICLOUD_SERVER_URL=https://your-oxicloud-server.com
SYNC_INTERVAL_SECONDS=300
MAX_UPLOAD_SPEED_KBPS=0        # 0 = unlimited
MAX_DOWNLOAD_SPEED_KBPS=0      # 0 = unlimited
```

## 📱 Supported Platforms

| Platform | Status | Notes |
|----------|--------|-------|
| Android | ✅ | API 21+ (Android 5.0+) |
| iOS | ✅ | iOS 12+ |
| Linux | ✅ | x64, arm64 |
| macOS | ✅ | 10.14+, Intel & Apple Silicon |
| Windows | ✅ | Windows 10+ |

## 🧪 Testing

```bash
# Run Flutter tests
flutter test

# Run Rust tests
cd rust && cargo test

# Run integration tests
flutter test integration_test/
```

## 📖 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Sync Engine Documentation](docs/SYNC-ENGINE.md)
- [Contributing Guide](../CONTRIBUTING.md)

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](../CONTRIBUTING.md) and [Code of Conduct](../CODE_OF_CONDUCT.md).

## 📄 License

MIT License - see [LICENSE](../LICENSE)
