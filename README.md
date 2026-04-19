<h1 align="center">OxiCloud Desktop Client</h1>

<h3 align="center">Native desktop-first client for OxiCloud - fast files, adaptive UI, and offline-aware local caching.</h3>

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?style=for-the-badge&logo=dart)](https://dart.dev/)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20%7C%20Linux%20%7C%20Windows%20%7C%20iOS%20%7C%20Android-0F172A?style=for-the-badge)](#platform-support)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-111827?style=for-the-badge)](#architecture)
[![Server](https://img.shields.io/badge/Backend-OxiCloud%20Server-EA580C?style=for-the-badge)](https://github.com/DioCrafts/OxiCloud)

[**OxiCloud Server**](https://github.com/DioCrafts/OxiCloud)  
[**Server Documentation**](https://diocrafts.github.io/OxiCloud/)

</div>

OxiCloud Desktop Client is the native Flutter application for OxiCloud, the self-hosted cloud platform written in Rust. It is built for desktop workflows first: drag-and-drop uploads, real file pickers, local downloads, secure token storage, and a desktop shell that feels like an application instead of a browser tab.

The same codebase also targets iOS and Android, but this repository focuses on the native desktop experience for macOS, Linux, and Windows.

## Why a native client?

| Capability | Desktop Client | Browser UI |
|------------|----------------|------------|
| Native drag-and-drop uploads | ✅ | Limited by browser |
| Secure token storage | ✅ | Browser-managed |
| Real open/save dialogs | ✅ | Limited |
| Offline-aware local cache | ✅ | Limited |
| Desktop shell with sidebar and toolbar | ✅ | Not native |
| Long-running session without tabs | ✅ | Depends on browser |

## Features

### Files and productivity
- Upload, download, rename, move, and delete files and folders
- Grid and list views with breadcrumbs and desktop toolbar
- Favorites, recent items, and trash management
- Private shares and public share access
- Batch file and folder operations
- Native file save and local download flows

### Search and media
- Instant search suggestions and advanced search
- Photo timeline with thumbnail loading
- Music playlists and track management
- Public shared file viewer and download flow

### Authentication and administration
- Login, registration, and first-run admin setup
- JWT sessions with refresh tokens
- OIDC provider discovery and login flow
- Device authorization flow for secondary devices
- App passwords and device management
- Admin dashboard and user management

### Native platform integration
- Secure storage for server URL and auth tokens
- Native file picker and save dialogs
- Desktop drag-and-drop uploads
- Offline-aware SQLite cache via Drift
- Queue-based sync bootstrap
- Adaptive shell for desktop and mobile layouts

## Feature status

| Feature | Status | Notes |
|---------|--------|-------|
| Desktop shell | ✅ Working | Sidebar, toolbar, breadcrumbs, drag and drop |
| Mobile shell | ✅ Working | Adaptive layout with bottom navigation |
| Local authentication | ✅ Working | Login, register, password change, logout |
| OIDC and device auth | ✅ Working | Provider discovery, auth flow, device verification |
| File browser | ✅ Working | Upload, download, move, rename, delete, favorites |
| Search | ✅ Working | Suggestions and advanced filtering |
| Shares and public links | ✅ Working | Create, manage, verify, download |
| Photos | ✅ Working | Timeline view with thumbnails |
| Trash | ✅ Working | Restore and permanent delete |
| Playlists | ✅ Working | Create playlists and manage tracks |
| Admin panel | ✅ Working | Dashboard, users, storage and auth settings |
| Offline cache | ✅ Working | Local cache for files and folders |
| Web target | ❌ Not targeted | This repository is native desktop and mobile only |

## Platform support

| Platform | Status | Packaging |
|----------|--------|-----------|
| macOS | ✅ | CI release zip |
| Linux | ✅ | CI release tar.gz |
| Windows | ✅ | CI release zip |
| Android | ✅ | CI release APK and AAB |
| iOS | ✅ | CI build available, unsigned artifact |

## Quick start

### Run against an existing OxiCloud server

1. Start an OxiCloud server. With the default server setup, it listens on `http://localhost:8086`.
2. Launch the client on your desktop platform.
3. Enter your server URL on first start.
4. Sign in, or finish initial admin setup if the server is fresh.

The client persists the server URL and auth tokens in secure storage. There is no runtime `.env` configuration required for normal use.

### Build from source

Requirements:

- Flutter 3.41.0+
- Dart 3.11.4+
- Platform toolchains for the targets you want to build
- A running OxiCloud server for real end-to-end usage

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos
```

If you prefer the bundled project commands:

```bash
make get
make gen
make run-macos
```

### Other run targets

```bash
make run-linux
make run-windows
make run-ios
make run-android
```

## Building releases

```bash
make build-macos
make build-linux
make build-windows
make build-apk
make build-ios
```

Notes:

- iOS release builds still require signing outside CI.
- Web is not configured for this repository.
- HTTPS is recommended in production, even though local `http://` development is supported.

## Architecture

Clean Architecture with a feature-first presentation layer:

```text
┌───────────────────────────────────────────────────────────────┐
│ Presentation   │ Adaptive shell, routes, feature pages, UI   │
├───────────────────────────────────────────────────────────────┤
│ Domain         │ Entities and repository contracts            │
├───────────────────────────────────────────────────────────────┤
│ Data           │ Datasources, DTOs, mappers, repo impls       │
├───────────────────────────────────────────────────────────────┤
│ Core           │ Network, storage, database, sync, theming    │
└───────────────────────────────────────────────────────────────┘
```

### Main building blocks

- **Riverpod** for state management and dependency injection
- **GoRouter** for guarded routing and navigation
- **Dio** with auth, retry, and refresh-token interceptors
- **Drift + SQLite** for local persistence and offline-aware caching
- **Adaptive shell** for desktop and mobile layouts from one codebase

### Project structure

```text
lib/
├── core/           # Config, network, database, theme, sync
├── domain/         # Entities and repository contracts
├── data/           # DTOs, remote datasources, mappers, repositories
├── presentation/
│   ├── widgets/    # Shared UI components
│   ├── shell/      # Desktop and mobile shell
│   └── features/   # admin, auth, favorites, files, photos, search, ...
├── providers.dart  # Riverpod wiring
├── app_router.dart # Navigation and auth guards
├── app.dart        # MaterialApp.router
└── main.dart       # Bootstrap
```

## Implemented modules

Current feature modules in the client:

- `admin`
- `auth`
- `favorites`
- `file_browser`
- `photos`
- `playlists`
- `public_share`
- `recent`
- `search`
- `settings`
- `shares`
- `trash`

## CI and release workflow

The repository includes three GitHub Actions workflows:

- **CI**: formatting, static analysis, and tests on pushes and pull requests
- **Build All Platforms**: release-mode artifacts for Android, iOS, macOS, Linux, and Windows
- **Release**: tag-driven packaging and GitHub release publishing

This gives the client a repeatable pipeline for desktop and mobile artifact generation.

## Development

```bash
make get       # flutter pub get
make gen       # one-shot code generation
make watch     # build_runner watch mode
make analyze   # flutter analyze
make test      # flutter test
make clean     # flutter clean + pub get
```

## Notes and limitations

- This repository targets native desktop and mobile apps. Web is not part of the supported matrix.
- The client requires a running OxiCloud server; it is not a standalone storage product.
- CI builds iOS artifacts without code signing.
- The server URL is configured in-app and stored securely, not through a runtime environment file.

## Documentation

Protocol, deployment, and server-side documentation live in the main OxiCloud project:

- [OxiCloud documentation portal](https://diocrafts.github.io/OxiCloud/)
- [Server repository](https://github.com/DioCrafts/OxiCloud)
- [OIDC / SSO setup](https://diocrafts.github.io/OxiCloud/config/oidc)
- [Deployment guide](https://diocrafts.github.io/OxiCloud/guide/installation)

## License

This client is part of the OxiCloud project. For licensing details, see the main server repository: [OxiCloud LICENSE](https://github.com/DioCrafts/OxiCloud/blob/main/LICENSE).
