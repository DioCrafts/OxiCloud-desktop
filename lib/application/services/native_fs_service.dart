import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/repositories/native_fs_repository.dart';

/// Application service for native file system integration
class NativeFileSystemService {
  final NativeFileSystemRepository _nativeFileSystemRepository;
  final Logger _logger = LoggingManager.getLogger('NativeFileSystemService');
  
  /// Create a NativeFileSystemService
  NativeFileSystemService(this._nativeFileSystemRepository);
  
  /// Initialize the native file system integration
  Future<bool> initialize() async {
    try {
      return await _nativeFileSystemRepository.initialize();
    } catch (e) {
      _logger.severe('Failed to initialize native file system service: $e');
      return false;
    }
  }
  
  /// Mount the virtual drive
  Future<bool> mountVirtualDrive(String mountPoint) async {
    try {
      return await _nativeFileSystemRepository.mountVirtualDrive(mountPoint);
    } catch (e) {
      _logger.warning('Failed to mount virtual drive: $e');
      return false;
    }
  }
  
  /// Unmount the virtual drive
  Future<bool> unmountVirtualDrive() async {
    try {
      return await _nativeFileSystemRepository.unmountVirtualDrive();
    } catch (e) {
      _logger.warning('Failed to unmount virtual drive: $e');
      return false;
    }
  }
  
  /// Check if the virtual drive is currently mounted
  Future<bool> isVirtualDriveMounted() async {
    try {
      return await _nativeFileSystemRepository.isVirtualDriveMounted();
    } catch (e) {
      _logger.warning('Failed to check if virtual drive is mounted: $e');
      return false;
    }
  }
  
  /// Get the current mount point of the virtual drive
  Future<String?> getVirtualDriveMountPoint() async {
    try {
      return await _nativeFileSystemRepository.getVirtualDriveMountPoint();
    } catch (e) {
      _logger.warning('Failed to get virtual drive mount point: $e');
      return null;
    }
  }
  
  /// Set whether the virtual drive should mount automatically on startup
  Future<void> setAutoMount(bool autoMount) async {
    try {
      await _nativeFileSystemRepository.setAutoMount(autoMount);
    } catch (e) {
      _logger.warning('Failed to set auto mount: $e');
    }
  }
  
  /// Get whether the virtual drive is configured to mount automatically on startup
  Future<bool> getAutoMount() async {
    try {
      return await _nativeFileSystemRepository.getAutoMount();
    } catch (e) {
      _logger.warning('Failed to get auto mount setting: $e');
      return false;
    }
  }
  
  /// Refresh a specific directory path in the virtual drive
  Future<void> refreshDirectory(String path) async {
    try {
      await _nativeFileSystemRepository.refreshDirectory(path);
    } catch (e) {
      _logger.warning('Failed to refresh directory: $path - $e');
    }
  }
  
  /// Open a file with the default application for its type
  Future<bool> openFileWithDefaultApp(File file) async {
    try {
      return await _nativeFileSystemRepository.openFileWithDefaultApp(file);
    } catch (e) {
      _logger.warning('Failed to open file with default app: ${file.path} - $e');
      return false;
    }
  }
  
  /// Reveal a file or folder in the native file explorer
  Future<bool> revealInFileExplorer(String path) async {
    try {
      return await _nativeFileSystemRepository.revealInFileExplorer(path);
    } catch (e) {
      _logger.warning('Failed to reveal in file explorer: $path - $e');
      return false;
    }
  }
  
  /// Get the platform-specific requirements for mounting a virtual drive
  Future<List<String>> getVirtualDriveRequirements() async {
    try {
      return await _nativeFileSystemRepository.getVirtualDriveRequirements();
    } catch (e) {
      _logger.warning('Failed to get virtual drive requirements: $e');
      return [];
    }
  }
  
  /// Check if all requirements for virtual drive mounting are met
  Future<bool> checkVirtualDriveRequirements() async {
    try {
      return await _nativeFileSystemRepository.checkVirtualDriveRequirements();
    } catch (e) {
      _logger.warning('Failed to check virtual drive requirements: $e');
      return false;
    }
  }
  
  /// Get platform-specific limitations of the virtual drive implementation
  Future<Map<String, String>> getVirtualDriveLimitations() async {
    try {
      return await _nativeFileSystemRepository.getVirtualDriveLimitations();
    } catch (e) {
      _logger.warning('Failed to get virtual drive limitations: $e');
      return {};
    }
  }
  
  /// Check if the platform supports native file system integration
  bool isPlatformSupported() {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}