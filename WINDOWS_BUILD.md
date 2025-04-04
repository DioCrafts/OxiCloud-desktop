# Building and Running OxiCloud Desktop Client on Windows

This guide provides detailed instructions for building, testing, and distributing OxiCloud Desktop Client on Windows platforms.

## Development Environment Setup

### Prerequisites

1. **Install Rust**
   - Download and run the [Rust installer](https://www.rust-lang.org/tools/install)
   - Follow the prompts and select the default installation options
   - After installation, open a new command prompt and verify installation with `rustc --version`

2. **Install Visual Studio Build Tools**
   - Download [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
   - Install with the "C++ build tools" workload selected
   - Ensure the Windows 10/11 SDK is installed

3. **Install OpenSSL**
   - Option 1: Using vcpkg
     ```powershell
     git clone https://github.com/Microsoft/vcpkg.git
     cd vcpkg
     .\bootstrap-vcpkg.bat
     .\vcpkg.exe install openssl:x64-windows
     .\vcpkg.exe integrate install
     ```
   - Option 2: Using pre-built binaries from [https://slproweb.com/products/Win32OpenSSL.html](https://slproweb.com/products/Win32OpenSSL.html)

4. **Install Git**
   - Download and install from [https://git-scm.com/download/win](https://git-scm.com/download/win)

### Clone and Configure the Repository

```powershell
# Clone repository
git clone https://github.com/yourusername/oxicloud-desktop.git
cd oxicloud-desktop

# Create necessary directories if they don't exist
mkdir -p .git/hooks
```

## Building the Application

### Development Build

```powershell
# Run in development mode
cargo run

# With logging enabled
$env:RUST_LOG="debug"; cargo run
```

### Release Build

```powershell
# Build release version
cargo build --release

# The executable will be at target\release\oxicloud-desktop.exe
```

### Running Tests

```powershell
# Run all tests
cargo test

# Run specific tests
cargo test file_sync_tests

# With verbose output
cargo test -- --nocapture
```

## Creating Windows Installer

### Using cargo-wix (Recommended)

1. **Install cargo-wix**

```powershell
cargo install cargo-wix
```

2. **Generate Installer**

```powershell
# Initialize WiX configuration (first time only)
cargo wix init

# Edit wix\main.wxs if needed

# Build MSI installer
cargo wix
```

3. **The MSI installer will be created in `target\wix\oxicloud-desktop-[version]-x86_64.msi`**

### Using Advanced Installer (Alternative)

1. Download and install [Advanced Installer](https://www.advancedinstaller.com/)
2. Create a new project using the application executable
3. Configure application details, shortcuts, and registry entries
4. Build the installer

## Windows-Specific Features

### System Integration

The application integrates with Windows in the following ways:

1. **Shell Extensions**
   - Overlay icons in Windows Explorer showing sync status
   - Context menu items for common operations

2. **Startup Registration**
   - Automatically starts with Windows
   - Configurable through the application settings

3. **Notifications**
   - Uses Windows notification system
   - Displays sync status and error notifications

### Registry Settings

The application stores the following registry entries:

```
HKEY_CURRENT_USER\Software\OxiCloud\DesktopClient
└── InstallPath
└── Version
└── StartWithWindows
└── Language
```

## Troubleshooting Windows-Specific Issues

### Build Errors

1. **Linker errors**
   - Ensure Visual Studio Build Tools are properly installed
   - Check that your PATH includes MSVC compiler binaries

2. **OpenSSL issues**
   - Set environment variables:
     ```powershell
     $env:OPENSSL_DIR="C:\path\to\openssl"
     ```

3. **SQLite errors**
   - Try using the bundled SQLite feature:
     ```powershell
     cargo build --release --features bundled-sqlite
     ```

### Runtime Issues

1. **Application won't start**
   - Check Event Viewer for application errors
   - Verify all dependencies are installed
   - Try running from command line to see console output

2. **Installation problems**
   - Run installer with logging:
     ```powershell
     msiexec /i OxiCloud-Desktop.msi /l*v install_log.txt
     ```

3. **File sync issues**
   - Check Windows Defender or antivirus exclusions
   - Verify permissions on the sync folder
   - Check Windows file locking with Process Explorer

## Deployment Checklist

- [ ] Build release version
- [ ] Run all tests
- [ ] Create and test installer
- [ ] Test installation on clean Windows system
- [ ] Verify startup behavior
- [ ] Test sync functionality
- [ ] Check Windows integration features
- [ ] Verify uninstallation process

## Performance Considerations

1. **File System Operations**
   - Use Windows I/O Completion Ports for async operations
   - Respect Windows path length limitations
   - Handle file locks appropriately

2. **System Resources**
   - Limit memory usage based on available system memory
   - Implement process priority adjustments for background operations
   - Optimize SQLite database with Windows-specific settings

## Distribution

### Release Process

1. Update version in Cargo.toml
2. Generate changelog
3. Build release version
4. Create installer
5. Sign application and installer with a code signing certificate
6. Upload to release servers
7. Update update manifest

### Auto-Updates

To implement auto-update functionality:

1. Create a JSON manifest format:
   ```json
   {
     "version": "1.2.0",
     "url": "https://example.com/releases/oxicloud-desktop-1.2.0.msi",
     "notes": "Release notes for version 1.2.0",
     "sha256": "hash_of_installer_file"
   }
   ```

2. Implement update checking in the application
3. Use Windows Task Scheduler for background update checks

### Side-by-Side Installation

Multiple versions can be installed by:

1. Using different installation directories
2. Using different product GUIDs in the installer
3. Implementing profile migration between versions