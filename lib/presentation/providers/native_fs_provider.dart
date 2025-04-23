import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/native_fs_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';

/// Provider for native file system auto-mount setting
final nativeFsProvider = StateNotifierProvider<NativeFsNotifier, AsyncValue<bool>>(
  (ref) => NativeFsNotifier(),
);

/// Provider for native file system mounted status
final nativeFsMountedProvider = FutureProvider<bool>((ref) async {
  await getIt.isReady<NativeFileSystemService>();
  return getIt<NativeFileSystemService>().isVirtualDriveMounted();
});

/// Provider for native file system requirements check
final nativeFsRequirementsProvider = FutureProvider<bool>((ref) async {
  await getIt.isReady<NativeFileSystemService>();
  return getIt<NativeFileSystemService>().checkVirtualDriveRequirements();
});

/// Provider for native file system mount point
final nativeFsMountPointProvider = FutureProvider<String?>((ref) async {
  await getIt.isReady<NativeFileSystemService>();
  return getIt<NativeFileSystemService>().getVirtualDriveMountPoint();
});

/// Notifier for native file system settings
class NativeFsNotifier extends StateNotifier<AsyncValue<bool>> {
  final Logger _logger = LoggingManager.getLogger('NativeFsNotifier');
  
  /// Create a NativeFsNotifier
  NativeFsNotifier() : super(const AsyncValue.loading()) {
    _loadAutoMount();
  }
  
  /// Load auto-mount setting
  Future<void> _loadAutoMount() async {
    try {
      await getIt.isReady<NativeFileSystemService>();
      final autoMount = await getIt<NativeFileSystemService>().getAutoMount();
      state = AsyncValue.data(autoMount);
    } catch (e) {
      _logger.warning('Failed to load auto-mount setting: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Set auto-mount setting
  Future<void> setAutoMount(bool autoMount) async {
    try {
      state = const AsyncValue.loading();
      await getIt<NativeFileSystemService>().setAutoMount(autoMount);
      state = AsyncValue.data(autoMount);
    } catch (e) {
      _logger.warning('Failed to set auto-mount setting: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  /// Mount the virtual drive
  Future<bool> mountVirtualDrive(String mountPoint) async {
    try {
      return await getIt<NativeFileSystemService>().mountVirtualDrive(mountPoint);
    } catch (e) {
      _logger.warning('Failed to mount virtual drive: $e');
      return false;
    }
  }
  
  /// Unmount the virtual drive
  Future<bool> unmountVirtualDrive() async {
    try {
      return await getIt<NativeFileSystemService>().unmountVirtualDrive();
    } catch (e) {
      _logger.warning('Failed to unmount virtual drive: $e');
      return false;
    }
  }
}