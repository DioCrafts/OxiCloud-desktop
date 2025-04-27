cmake_minimum_required(VERSION 3.10)
project(oxicloud_desktop_client LANGUAGES CXX)

set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Define the application target.
add_subdirectory(flutter)
add_subdirectory(runner)

# Application-specific configuration.
add_definitions(-DAPPLICATION_ID="com.example.oxicloud_desktop_client") 