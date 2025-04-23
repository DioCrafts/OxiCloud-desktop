import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/repositories/native_fs_repository.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_linux.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_macos.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_windows.dart';

/// Factory for creating platform-specific NativeFileSystemRepository implementations
class NativeFileSystemAdapterFactory {
  final Logger _logger = LoggingManager.getLogger('NativeFileSystemAdapterFactory');
  
  /// Create a platform-specific NativeFileSystemRepository implementation
  NativeFileSystemRepository create(SecureStorage secureStorage, String localSyncFolder) {
    if (Platform.isWindows) {
      _logger.info('Creating Windows native file system adapter');
      return WindowsNativeFileSystemAdapter(secureStorage, localSyncFolder);
    } else if (Platform.isMacOS) {
      _logger.info('Creating macOS native file system adapter');
      return MacOSNativeFileSystemAdapter(secureStorage, localSyncFolder);
    } else if (Platform.isLinux) {
      _logger.info('Creating Linux native file system adapter');
      return LinuxNativeFileSystemAdapter(secureStorage, localSyncFolder);
    } else {
      _logger.warning('Unsupported platform for native file system integration: ${Platform.operatingSystem}');
      throw UnsupportedError('Native file system integration is not supported on ${Platform.operatingSystem}');
    }
  }
}