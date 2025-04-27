cmake_minimum_required(VERSION 3.10)
project(oxicloud_desktop_client LANGUAGES CXX)

set(BINARY_NAME "oxicloud_desktop_client")
set(APPLICATION_ID "com.oxicloud.desktop")

# Define build configuration options.
option(ENABLE_UNIT_TESTS "Enable unit tests" ON)
option(ENABLE_PLUGIN_TESTS "Enable plugin tests" ON)

# Configure the build.
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Set Flutter path
set(FLUTTER_ROOT "/home/torrefacto/flutter")

# Find required packages.
find_package(Flutter REQUIRED)
find_package(GTK3 REQUIRED)
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED gtk+-3.0)

# Define the application target. This creates the "flutter_app" executable.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the Flutter tooling, which sets up the application bundle.
apply_plugin_bundles(${BINARY_NAME} PLUGIN_BUNDLES)
apply_standard_settings(${BINARY_NAME})
set_target_properties(${BINARY_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN 1
)

# Add dependency libraries.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Run the Flutter tooling to download dependencies and generate files.
flutter_configure_executable(${BINARY_NAME})

# Create an install target.
install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}/bin")

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Application build
add_subdirectory("runner") 