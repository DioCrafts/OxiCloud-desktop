cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# main CMakeLists.txt, not the value here, or `flutter run` will no longer work.
add_executable(${BINARY_NAME} "main.cc" "my_application.cc")

# Apply the Flutter tooling, which configure the application to use the
# Flutter framework.
apply_plugins(${BINARY_NAME})

# Add dependency libraries.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

# Run the Flutter tooling to download any required dependencies.
flutter_download_dependencies(${BINARY_NAME})

# Install the binary.
install(TARGETS ${BINARY_NAME} DESTINATION "${INSTALL_BUNDLE_DATA_DIR}/bin")

# Add additional dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED gtk+-3.0)
pkg_check_modules(GIO REQUIRED gio-2.0)
pkg_check_modules(GLIB REQUIRED glib-2.0)

# Link additional libraries
target_link_libraries(${BINARY_NAME} PRIVATE ${GTK_LIBRARIES})
target_link_libraries(${BINARY_NAME} PRIVATE ${GIO_LIBRARIES})
target_link_libraries(${BINARY_NAME} PRIVATE ${GLIB_LIBRARIES})

# Add include directories
target_include_directories(${BINARY_NAME} PRIVATE ${GTK_INCLUDE_DIRS})
target_include_directories(${BINARY_NAME} PRIVATE ${GIO_INCLUDE_DIRS})
target_include_directories(${BINARY_NAME} PRIVATE ${GLIB_INCLUDE_DIRS})

# Set compiler flags
set_target_properties(${BINARY_NAME} PROPERTIES
    CXX_STANDARD 14
    CXX_STANDARD_REQUIRED ON
    POSITION_INDEPENDENT_CODE ON
)

# Add definitions
target_compile_definitions(${BINARY_NAME} PRIVATE
    GTK_DISABLE_DEPRECATED
    GDK_DISABLE_DEPRECATED
    GSEAL_ENABLE
) 