#!/bin/bash
# Script to create an AppImage for OxiCloud Desktop Client

set -e

# Configuration
APP_NAME="OxiCloud"
APP_VERSION="1.0.0"
SOURCE_DIR="../../build/linux/x64/release/bundle"
BUILD_DIR="build"
APPDIR="$BUILD_DIR/$APP_NAME.AppDir"

# Create AppDir structure
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$APPDIR/usr/share/metainfo"

# Copy application files
echo "Copying application files..."
cp -r "$SOURCE_DIR"/* "$APPDIR/usr/bin/"

# Create .desktop file
cat > "$APPDIR/usr/share/applications/oxicloud-desktop.desktop" << EOF
[Desktop Entry]
Type=Application
Name=OxiCloud
Comment=OxiCloud Desktop Client for file synchronization
Exec=oxicloud-desktop
Icon=oxicloud
Terminal=false
Categories=Network;FileTransfer;
Keywords=sync;cloud;
EOF

# Also create desktop file in root for AppImage
cp "$APPDIR/usr/share/applications/oxicloud-desktop.desktop" "$APPDIR/oxicloud-desktop.desktop"

# Copy icon
cp "../../assets/icons/linux/icon.png" "$APPDIR/usr/share/icons/hicolor/512x512/apps/oxicloud.png"
cp "../../assets/icons/linux/icon.png" "$APPDIR/oxicloud.png"

# Create AppRun script
cat > "$APPDIR/AppRun" << 'EOF'
#!/bin/bash
# Get the directory where this AppImage is located
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"

# Check if FUSE is available for native filesystem integration
if [ -e /dev/fuse ] && [ -e /etc/fuse.conf ]; then
  export OXICLOUD_FUSE_ENABLED=1
else
  export OXICLOUD_FUSE_ENABLED=0
  echo "Warning: FUSE is not available. Native filesystem integration will be disabled."
  echo "To enable this feature, install FUSE on your system."
fi

# Launch the application
exec "${HERE}/usr/bin/oxicloud-desktop" "$@"
EOF

# Make AppRun executable
chmod +x "$APPDIR/AppRun"

# Download dependencies
if [ ! -f "linuxdeploy-x86_64.AppImage" ]; then
  echo "Downloading linuxdeploy..."
  wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
  chmod +x linuxdeploy-x86_64.AppImage
fi

if [ ! -f "linuxdeploy-plugin-appimage-x86_64.AppImage" ]; then
  echo "Downloading linuxdeploy-plugin-appimage..."
  wget https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/continuous/linuxdeploy-plugin-appimage-x86_64.AppImage
  chmod +x linuxdeploy-plugin-appimage-x86_64.AppImage
fi

# Create AppImage
echo "Creating AppImage..."
export OUTPUT="$BUILD_DIR/$APP_NAME-$APP_VERSION-x86_64.AppImage"
export APPIMAGE_EXTRACT_AND_RUN=1
export VERSION=$APP_VERSION
./linuxdeploy-x86_64.AppImage --appdir="$APPDIR" --desktop-file="$APPDIR/usr/share/applications/oxicloud-desktop.desktop" --icon-file="$APPDIR/usr/share/icons/hicolor/512x512/apps/oxicloud.png" --plugin appimage

echo "AppImage created: $OUTPUT"