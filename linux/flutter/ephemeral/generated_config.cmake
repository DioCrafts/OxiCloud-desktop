# Generated code do not commit.
file(TO_CMAKE_PATH "/home/torrefacto/flutter" FLUTTER_ROOT)
file(TO_CMAKE_PATH "/home/torrefacto/OxiCloud/oxicloud_desktop_client" PROJECT_DIR)

set(FLUTTER_VERSION "1.0.0+1" PARENT_SCOPE)
set(FLUTTER_VERSION_MAJOR 1 PARENT_SCOPE)
set(FLUTTER_VERSION_MINOR 0 PARENT_SCOPE)
set(FLUTTER_VERSION_PATCH 0 PARENT_SCOPE)
set(FLUTTER_VERSION_BUILD 1 PARENT_SCOPE)

# Environment variables to pass to tool_backend.sh
list(APPEND FLUTTER_TOOL_ENVIRONMENT
  "FLUTTER_ROOT=/home/torrefacto/flutter"
  "PROJECT_DIR=/home/torrefacto/OxiCloud/oxicloud_desktop_client"
  "DART_OBFUSCATION=false"
  "TRACK_WIDGET_CREATION=true"
  "TREE_SHAKE_ICONS=true"
  "PACKAGE_CONFIG=/home/torrefacto/OxiCloud/oxicloud_desktop_client/.dart_tool/package_config.json"
  "FLUTTER_TARGET=lib/main.dart"
)
