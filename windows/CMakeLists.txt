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

# Find Flutter
if(NOT DEFINED FLUTTER_ROOT)
    set(FLUTTER_ROOT $ENV{FLUTTER_ROOT})
endif()

if(NOT DEFINED FLUTTER_ENGINE)
    set(FLUTTER_ENGINE $ENV{FLUTTER_ENGINE})
endif()

if(NOT DEFINED FLUTTER_CMAKE_DIR)
    set(FLUTTER_CMAKE_DIR "${FLUTTER_ROOT}/packages/flutter_tools/bin")
endif()

if(NOT DEFINED FLUTTER_ENGINE_SRC)
    set(FLUTTER_ENGINE_SRC $ENV{FLUTTER_ENGINE_SRC})
endif()

if(NOT DEFINED FLUTTER_ENGINE_OUT)
    set(FLUTTER_ENGINE_OUT $ENV{FLUTTER_ENGINE_OUT})
endif()

# Add Flutter's CMake modules to the module path
list(APPEND CMAKE_MODULE_PATH "${FLUTTER_CMAKE_DIR}")
list(APPEND CMAKE_PREFIX_PATH "${FLUTTER_ROOT}/bin/cache/artifacts/engine/windows-x64")

# Find Flutter package
find_package(Flutter REQUIRED)

# Configure build options.
option(BUILD_BUNDLE "Build a bundle instead of an executable" OFF)
option(ENABLE_ASSERTS "Enable assertions" OFF)

# Use bundles of the Flutter libraries.
set(BUILD_BUNDLE ${BUILD_BUNDLE})
set(ENABLE_ASSERTS ${ENABLE_ASSERTS})

# Root files directory for absolute paths for the project.
set(PROJECT_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/..")

# Define the application target. This creates the executable.
add_executable(${BINARY_NAME}
  "main.cc"
  "flutter_window.cpp"
  "win32_window.cpp"
  "utils.cpp"
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