#!/bin/bash

# Build script for Linux without libsecret dependency
# This script builds the OxiCloud desktop client for Linux without requiring the libsecret-1 system package

set -e

# Move to project root
cd "$(dirname "$0")/../.."

# Clean any previous build artifacts
echo "Cleaning previous build..."
flutter clean || true

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build the Linux version
echo "Building for Linux..."
flutter build linux --release

# If successful, create a tar.gz distribution
if [ $? -eq 0 ]; then
  echo "Build successful, creating distribution package..."
  
  # Create dist directory if it doesn't exist
  mkdir -p dist
  
  # Create tar.gz
  VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | tr -d '\r')
  OUTPUT_FILE="dist/oxicloud-desktop-linux-$VERSION.tar.gz"
  
  # Package the build
  tar -czf "$OUTPUT_FILE" -C build/linux/x64/release/bundle .
  
  echo "Package created: $OUTPUT_FILE"
  exit 0
else
  echo "Build failed."
  exit 1
fi