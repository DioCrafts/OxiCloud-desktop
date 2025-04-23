import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/repositories/native_fs_repository.dart';

/// Base implementation for native file system adapters
abstract class NativeFileSystemAdapterBase implements NativeFileSystemRepository {
  final Logger _logger = LoggingManager.getLogger('NativeFileSystemAdapter');
  
  bool _isMounted = false;
  String? _mountPoint;
  bool _autoMount = false;
  
  @override
  Future<bool> isVirtualDriveMounted() async {
    return _isMounted;
  }
  
  @override
  Future<String?> getVirtualDriveMountPoint() async {
    return _mountPoint;
  }
  
  @override
  Future<void> setAutoMount(bool autoMount) async {
    _autoMount = autoMount;
    await persistConfiguration();
  }
  
  @override
  Future<bool> getAutoMount() async {
    return _autoMount;
  }
  
  @override
  Future<bool> openFileWithDefaultApp(File file) async {
    try {
      if (!file.existsSync()) {
        _logger.warning('File does not exist: ${file.path}');
        return false;
      }
      
      return await openFileWithDefaultAppInternal(file);
    } catch (e) {
      _logger.warning('Failed to open file with default app: ${file.path} - $e');
      return false;
    }
  }
  
  /// Internal implementation for opening a file with the default app
  Future<bool> openFileWithDefaultAppInternal(File file);
  
  /// Persist configuration to disk
  Future<void> persistConfiguration();
  
  /// Set the mounted state
  void setMountedState(bool isMounted, String? mountPoint) {
    _isMounted = isMounted;
    _mountPoint = mountPoint;
  }
  
  /// Load configuration from disk
  Future<void> loadConfiguration();
}