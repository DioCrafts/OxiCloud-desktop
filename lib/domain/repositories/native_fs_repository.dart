import 'dart:io';

/// Repository interface for native file system integration
abstract class NativeFileSystemRepository {
  /// Initialize the native file system integration
  /// 
  /// This sets up any required OS-specific components and
  /// returns true if successfully initialized
  Future<bool> initialize();
  
  /// Mount OxiCloud as a virtual drive in the native file system
  /// 
  /// mountPoint: The location where the virtual drive should be mounted
  /// Returns true if successfully mounted
  Future<bool> mountVirtualDrive(String mountPoint);
  
  /// Unmount the OxiCloud virtual drive
  /// 
  /// Returns true if successfully unmounted
  Future<bool> unmountVirtualDrive();
  
  /// Check if the virtual drive is currently mounted
  Future<bool> isVirtualDriveMounted();
  
  /// Get the current mount point of the virtual drive
  /// 
  /// Returns null if not mounted
  Future<String?> getVirtualDriveMountPoint();
  
  /// Set whether the virtual drive should mount automatically on startup
  Future<void> setAutoMount(bool autoMount);
  
  /// Get whether the virtual drive is configured to mount automatically on startup
  Future<bool> getAutoMount();
  
  /// Refresh a specific directory path in the virtual drive
  /// 
  /// This forces the operating system to refresh its view of the directory
  Future<void> refreshDirectory(String path);
  
  /// Open a file with the default application for its type
  Future<bool> openFileWithDefaultApp(File file);
  
  /// Reveal a file or folder in the native file explorer
  /// 
  /// This opens the file explorer and selects the specified file/folder
  Future<bool> revealInFileExplorer(String path);
  
  /// Get the platform-specific requirements for mounting a virtual drive
  /// 
  /// This may include required permissions, software, etc.
  Future<List<String>> getVirtualDriveRequirements();
  
  /// Check if all requirements for virtual drive mounting are met
  Future<bool> checkVirtualDriveRequirements();
  
  /// Get platform-specific limitations of the virtual drive implementation
  Future<Map<String, String>> getVirtualDriveLimitations();
}