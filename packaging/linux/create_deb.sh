#!/bin/bash
# Script to create a .deb package for OxiCloud Desktop Client

set -e

# Configuration
APP_NAME="oxicloud-desktop"
APP_VERSION="1.0.0"
ARCHITECTURE="amd64"
MAINTAINER="OxiCloud Team <support@oxicloud.example.com>"
DESCRIPTION="OxiCloud Desktop Client for file synchronization"
HOMEPAGE="https://oxicloud.example.com"
LICENSE="MIT"

# Create build directory
BUILD_DIR="build"
DEB_DIR="$BUILD_DIR/$APP_NAME-$APP_VERSION-$ARCHITECTURE"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/applications"
mkdir -p "$DEB_DIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$DEB_DIR/usr/share/metainfo"

# Copy application files
echo "Copying application files..."
cp -r ../../build/linux/x64/release/bundle/* "$DEB_DIR/usr/bin/"

# Create desktop entry
cat > "$DEB_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Type=Application
Name=OxiCloud
Comment=OxiCloud Desktop Client for file synchronization
Exec=oxicloud-desktop
Icon=oxicloud
Terminal=false
Categories=Network;FileTransfer;
Keywords=sync;cloud;
StartupWMClass=oxicloud-desktop
EOF

# Copy icon
cp ../../assets/icons/linux/icon.png "$DEB_DIR/usr/share/icons/hicolor/512x512/apps/oxicloud.png"

# Create AppStream metadata
cat > "$DEB_DIR/usr/share/metainfo/$APP_NAME.appdata.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>com.example.oxicloud.desktop</id>
  <name>OxiCloud</name>
  <summary>OxiCloud Desktop Client for file synchronization</summary>
  <description>
    <p>
      OxiCloud Desktop Client allows you to sync your files with OxiCloud server,
      providing an efficient file management solution.
    </p>
    <p>Features:</p>
    <ul>
      <li>Efficient file synchronization</li>
      <li>Offline access to files</li>
      <li>Resource-aware operation</li>
      <li>Native filesystem integration</li>
      <li>Trash bin functionality</li>
    </ul>
  </description>
  <launchable type="desktop-id">oxicloud-desktop.desktop</launchable>
  <url type="homepage">https://oxicloud.example.com</url>
  <screenshots>
    <screenshot type="default">
      <image>https://oxicloud.example.com/screenshots/main.png</image>
      <caption>The main window showing file browser</caption>
    </screenshot>
  </screenshots>
  <provides>
    <binary>oxicloud-desktop</binary>
  </provides>
  <releases>
    <release version="1.0.0" date="2025-04-23">
      <description>
        <p>Initial release</p>
      </description>
    </release>
  </releases>
  <content_rating type="oars-1.1" />
  <developer_name>OxiCloud Team</developer_name>
  <project_license>MIT</project_license>
  <metadata_license>CC0-1.0</metadata_license>
</component>
EOF

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: $APP_NAME
Version: $APP_VERSION
Architecture: $ARCHITECTURE
Maintainer: $MAINTAINER
Depends: libfuse2 (>= 2.9.0), fuse, libgtk-3-0, libx11-6, libxcursor1, libxinerama1, libxrandr2
Section: net
Priority: optional
Homepage: $HOMEPAGE
Description: $DESCRIPTION
 OxiCloud Desktop Client provides seamless synchronization with OxiCloud server.
 It offers efficient file operations, offline access, and native filesystem integration.
 .
 Features include:
  * Efficient file synchronization
  * Offline access to files
  * Resource-aware operation (battery, network, storage)
  * Native filesystem integration
  * Trash bin functionality
EOF

# Create postinst script
cat > "$DEB_DIR/DEBIAN/postinst" << EOF
#!/bin/sh
set -e

# Update desktop database
if [ -x "$(command -v update-desktop-database)" ]; then
  update-desktop-database -q
fi

# Update icon cache
if [ -x "$(command -v gtk-update-icon-cache)" ]; then
  gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor
fi

# Set permissions for FUSE
if ! grep -q "^fuse:.*\$(id -u)" /etc/group; then
  echo "Note: To use the virtual filesystem feature, you may need to add your user to the 'fuse' group"
  echo "You can do this with: sudo usermod -a -G fuse \$(whoami)"
  echo "Then log out and log back in for changes to take effect."
fi

exit 0
EOF

# Make scripts executable
chmod 755 "$DEB_DIR/DEBIAN/postinst"

# Create deb package
echo "Creating .deb package..."
dpkg-deb --build "$DEB_DIR" "$BUILD_DIR/$APP_NAME-$APP_VERSION-$ARCHITECTURE.deb"

echo "Package created: $BUILD_DIR/$APP_NAME-$APP_VERSION-$ARCHITECTURE.deb"