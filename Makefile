# ============================================================================
# OxiCloud Desktop — Build & Development Commands
# ============================================================================

.PHONY: help setup clean build-linux build-windows build-macos build-android build-ios \
        run-linux run-android test analyze fmt lint all

# Default target
help:
	@echo "OxiCloud Desktop — Available commands:"
	@echo ""
	@echo "  Setup:"
	@echo "    make setup            Install all dependencies"
	@echo "    make clean            Clean build artifacts"
	@echo ""
	@echo "  Build:"
	@echo "    make build-linux      Build Linux release"
	@echo "    make build-windows    Build Windows release"
	@echo "    make build-macos      Build macOS release"
	@echo "    make build-android    Build Android APK + AAB"
	@echo "    make build-ios        Build iOS (no codesign)"
	@echo "    make all              Build all platforms"
	@echo ""
	@echo "  Run:"
	@echo "    make run-linux        Run on Linux (debug)"
	@echo "    make run-android      Run on Android (debug)"
	@echo ""
	@echo "  Quality:"
	@echo "    make test             Run all tests"
	@echo "    make analyze          Flutter analyze + Rust clippy"
	@echo "    make fmt              Format Dart + Rust code"
	@echo "    make lint             Run all linters"
	@echo ""
	@echo "  Package:"
	@echo "    make deb              Create .deb package (Linux)"
	@echo "    make appimage         Create AppImage (Linux)"

# ── Setup ──────────────────────────────────────────────────────────────────

setup:
	flutter pub get
	cd rust && cargo build

clean:
	flutter clean
	cd rust && cargo clean
	rm -rf build/

# ── Build ──────────────────────────────────────────────────────────────────

build-linux:
	flutter build linux --release

build-windows:
	flutter build windows --release

build-macos:
	flutter build macos --release

build-android: build-android-apk build-android-aab

build-android-apk:
	flutter build apk --release

build-android-apk-split:
	flutter build apk --split-per-abi --release

build-android-aab:
	flutter build appbundle --release

build-ios:
	flutter build ios --release --no-codesign

all: build-linux build-android

# ── Run ────────────────────────────────────────────────────────────────────

run-linux:
	flutter run -d linux

run-android:
	flutter run -d android

run-web:
	flutter run -d chrome

# ── Quality ────────────────────────────────────────────────────────────────

test:
	flutter test
	cd rust && cargo test

analyze:
	flutter analyze --no-fatal-infos
	cd rust && cargo clippy --all-targets

fmt:
	dart format lib/ test/
	cd rust && cargo fmt

lint: analyze fmt

# ── Package (Linux) ───────────────────────────────────────────────────────

VERSION ?= $(shell grep 'version:' pubspec.yaml | head -1 | awk '{print $$2}' | cut -d'+' -f1)

deb: build-linux
	@echo "Creating .deb package v$(VERSION)..."
	@mkdir -p dist/deb/DEBIAN
	@mkdir -p dist/deb/usr/bin
	@mkdir -p dist/deb/usr/lib/oxicloud
	@mkdir -p dist/deb/usr/share/applications
	@cp -r build/linux/x64/release/bundle/* dist/deb/usr/lib/oxicloud/
	@echo '#!/bin/bash\nexec /usr/lib/oxicloud/oxicloud_app "$$@"' > dist/deb/usr/bin/oxicloud
	@chmod +x dist/deb/usr/bin/oxicloud
	@printf '[Desktop Entry]\nType=Application\nName=OxiCloud\nComment=Cloud storage sync client\nExec=oxicloud\nIcon=oxicloud\nTerminal=false\nCategories=Network;FileTransfer;Utility;\n' > dist/deb/usr/share/applications/oxicloud.desktop
	@printf 'Package: oxicloud\nVersion: $(VERSION)\nSection: net\nPriority: optional\nArchitecture: amd64\nMaintainer: DioCrafts <info@diocrafts.com>\nDescription: OxiCloud Desktop Client\n Fast, secure cloud storage synchronization client.\n' > dist/deb/DEBIAN/control
	@dpkg-deb --build dist/deb dist/OxiCloud-$(VERSION)-amd64.deb
	@echo "Created: dist/OxiCloud-$(VERSION)-amd64.deb"

appimage: build-linux
	@echo "Creating AppImage..."
	@mkdir -p dist/AppDir/usr/bin
	@cp -r build/linux/x64/release/bundle/* dist/AppDir/usr/bin/
	@printf '#!/bin/bash\nAPPDIR="$$(dirname "$$(readlink -f "$$0")")"\nexec "$$APPDIR/usr/bin/oxicloud_app" "$$@"\n' > dist/AppDir/AppRun
	@chmod +x dist/AppDir/AppRun
	@printf '[Desktop Entry]\nType=Application\nName=OxiCloud\nExec=oxicloud_app\nIcon=oxicloud\nCategories=Network;FileTransfer;Utility;\n' > dist/AppDir/oxicloud.desktop
	@touch dist/AppDir/oxicloud.png
	@echo "AppDir created at dist/AppDir/ — run appimagetool to create .AppImage"
