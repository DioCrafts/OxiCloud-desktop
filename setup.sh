#!/bin/bash
# OxiCloud Desktop - Build Script
# This script sets up and builds the OxiCloud desktop application

set -e

echo "🚀 OxiCloud Desktop Build Script"
echo "================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check Rust
    if ! command -v cargo &> /dev/null; then
        echo -e "${RED}❌ Rust/Cargo not found. Install from https://rustup.rs${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Rust $(cargo --version)${NC}"
    
    # Check Flutter
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter not found. Install from https://flutter.dev${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Flutter $(flutter --version | head -1)${NC}"
    
    # Check flutter_rust_bridge_codegen
    if ! command -v flutter_rust_bridge_codegen &> /dev/null; then
        echo -e "${YELLOW}⚠ flutter_rust_bridge_codegen not found. Installing...${NC}"
        cargo install flutter_rust_bridge_codegen
    fi
    echo -e "${GREEN}✓ flutter_rust_bridge_codegen installed${NC}"
}

# Generate FFI bindings
generate_bindings() {
    echo -e "${YELLOW}Generating Flutter-Rust bindings...${NC}"
    flutter_rust_bridge_codegen generate
    echo -e "${GREEN}✓ Bindings generated in lib/src/rust/${NC}"
}

# Build Rust library
build_rust() {
    echo -e "${YELLOW}Building Rust library...${NC}"
    cd rust
    cargo build --release
    cd ..
    echo -e "${GREEN}✓ Rust library built${NC}"
}

# Get Flutter dependencies
flutter_deps() {
    echo -e "${YELLOW}Getting Flutter dependencies...${NC}"
    flutter pub get
    echo -e "${GREEN}✓ Flutter dependencies installed${NC}"
}

# Generate Dart code (Freezed, etc.)
generate_dart() {
    echo -e "${YELLOW}Generating Dart code...${NC}"
    dart run build_runner build --delete-conflicting-outputs
    echo -e "${GREEN}✓ Dart code generated${NC}"
}

# Build for specific platform
build_platform() {
    local platform=$1
    echo -e "${YELLOW}Building for $platform...${NC}"
    
    case $platform in
        linux)
            flutter build linux --release
            echo -e "${GREEN}✓ Linux build complete: build/linux/x64/release/bundle/${NC}"
            ;;
        windows)
            flutter build windows --release
            echo -e "${GREEN}✓ Windows build complete: build/windows/x64/runner/Release/${NC}"
            ;;
        macos)
            flutter build macos --release
            echo -e "${GREEN}✓ macOS build complete: build/macos/Build/Products/Release/${NC}"
            ;;
        android)
            flutter build apk --release
            echo -e "${GREEN}✓ Android build complete: build/app/outputs/flutter-apk/${NC}"
            ;;
        ios)
            flutter build ios --release --no-codesign
            echo -e "${GREEN}✓ iOS build complete: build/ios/iphoneos/${NC}"
            ;;
        *)
            echo -e "${RED}Unknown platform: $platform${NC}"
            exit 1
            ;;
    esac
}

# Run tests
run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"
    
    # Rust tests
    echo "Running Rust tests..."
    cd rust && cargo test && cd ..
    
    # Flutter tests
    echo "Running Flutter tests..."
    flutter test
    
    echo -e "${GREEN}✓ All tests passed${NC}"
}

# Main
main() {
    local command=${1:-"build"}
    local platform=${2:-"linux"}
    
    case $command in
        setup)
            check_prerequisites
            flutter_deps
            generate_bindings
            build_rust
            generate_dart
            echo -e "${GREEN}✓ Setup complete!${NC}"
            echo -e "Run './setup.sh build <platform>' to build"
            ;;
        bindings)
            generate_bindings
            ;;
        build)
            check_prerequisites
            flutter_deps
            generate_bindings
            build_rust
            build_platform $platform
            ;;
        test)
            run_tests
            ;;
        clean)
            echo "Cleaning..."
            flutter clean
            cd rust && cargo clean && cd ..
            rm -rf lib/src/rust/*.dart
            echo -e "${GREEN}✓ Clean complete${NC}"
            ;;
        *)
            echo "Usage: $0 {setup|bindings|build|test|clean} [platform]"
            echo ""
            echo "Commands:"
            echo "  setup    - Install all dependencies and generate code"
            echo "  bindings - Generate Flutter-Rust bridge only"
            echo "  build    - Build for specified platform (default: linux)"
            echo "  test     - Run all tests"
            echo "  clean    - Clean all build artifacts"
            echo ""
            echo "Platforms: linux, windows, macos, android, ios"
            exit 1
            ;;
    esac
}

main "$@"
