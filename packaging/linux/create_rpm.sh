#!/bin/bash
# Script to create a RPM package for OxiCloud Desktop Client

set -e

# Configuration
APP_NAME="oxicloud-desktop"
APP_VERSION="1.0.0"
RELEASE="1"
ARCHITECTURE="x86_64"
SUMMARY="OxiCloud Desktop Client for file synchronization"
LICENSE="MIT"
VENDOR="OxiCloud Team"
GROUP="Applications/Internet"
SOURCE_DIR="../../build/linux/x64/release/bundle"
BUILD_DIR="build"
SPEC_FILE="$BUILD_DIR/$APP_NAME.spec"
RPM_BUILD_DIR="$BUILD_DIR/rpmbuild"

# Create build directories
mkdir -p "$BUILD_DIR"
mkdir -p "$RPM_BUILD_DIR"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create tarball of the application
echo "Creating source tarball..."
mkdir -p "$BUILD_DIR/source/$APP_NAME-$APP_VERSION"
cp -r "$SOURCE_DIR"/* "$BUILD_DIR/source/$APP_NAME-$APP_VERSION/"
cp "../../assets/icons/linux/icon.png" "$BUILD_DIR/source/$APP_NAME-$APP_VERSION/"
cd "$BUILD_DIR/source"
tar -czf "$RPM_BUILD_DIR/SOURCES/$APP_NAME-$APP_VERSION.tar.gz" "$APP_NAME-$APP_VERSION"
cd -

# Create desktop entry file in SOURCES
mkdir -p "$RPM_BUILD_DIR/SOURCES"
cat > "$RPM_BUILD_DIR/SOURCES/$APP_NAME.desktop" << EOF
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

# Create metainfo file in SOURCES
cat > "$RPM_BUILD_DIR/SOURCES/$APP_NAME.metainfo.xml" << EOF
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

# Create spec file
cat > "$RPM_BUILD_DIR/SPECS/$APP_NAME.spec" << EOF
Name:           $APP_NAME
Version:        $APP_VERSION
Release:        $RELEASE%{?dist}
Summary:        $SUMMARY
License:        $LICENSE
URL:            https://oxicloud.example.com
Group:          $GROUP
Vendor:         $VENDOR
Source0:        %{name}-%{version}.tar.gz
Source1:        %{name}.desktop
Source2:        %{name}.metainfo.xml
BuildRequires:  desktop-file-utils
Requires:       fuse >= 2.9.0, gtk3

%description
OxiCloud Desktop Client provides seamless synchronization with OxiCloud server.
It offers efficient file operations, offline access, and native filesystem integration.

Features include:
* Efficient file synchronization
* Offline access to files
* Resource-aware operation (battery, network, storage)
* Native filesystem integration
* Trash bin functionality

%prep
%setup -q

%build
# Nothing to build, we're just packaging the pre-built app

%install
# Create directories
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_datadir}/icons/hicolor/512x512/apps
mkdir -p %{buildroot}%{_metainfodir}

# Install application files
cp -r * %{buildroot}%{_bindir}/

# Install desktop file
install -m 644 %{SOURCE1} %{buildroot}%{_datadir}/applications/

# Install icon
install -m 644 icon.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/oxicloud.png

# Install metainfo
install -m 644 %{SOURCE2} %{buildroot}%{_metainfodir}/%{name}.metainfo.xml

%post
# Update desktop database
update-desktop-database -q || :
# Update icon cache
touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :
gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor &> /dev/null || :

echo "Note: To use the virtual filesystem feature, you may need to add your user to the 'fuse' group"
echo "You can do this with: sudo usermod -a -G fuse \\\$(whoami)"
echo "Then log out and log back in for changes to take effect."

%postun
if [ \$1 -eq 0 ] ; then
  update-desktop-database -q || :
  touch --no-create %{_datadir}/icons/hicolor &> /dev/null || :
  gtk-update-icon-cache -q -t -f %{_datadir}/icons/hicolor &> /dev/null || :
fi

%files
%{_bindir}/*
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/512x512/apps/oxicloud.png
%{_metainfodir}/%{name}.metainfo.xml

%changelog
* Tue Apr 23 2025 OxiCloud Team <support@oxicloud.example.com> - 1.0.0-1
- Initial release
EOF

# Build RPM package
echo "Building RPM package..."
rpmbuild --define "_topdir $(realpath $RPM_BUILD_DIR)" -ba "$RPM_BUILD_DIR/SPECS/$APP_NAME.spec"

# Copy the resulting RPM to build directory
cp "$RPM_BUILD_DIR/RPMS/$ARCHITECTURE/$APP_NAME-$APP_VERSION-$RELEASE"*.rpm "$BUILD_DIR/"

echo "Package created: $BUILD_DIR/$APP_NAME-$APP_VERSION-$RELEASE.$ARCHITECTURE.rpm"