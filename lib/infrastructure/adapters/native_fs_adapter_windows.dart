import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_base.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:win32_registry/win32_registry.dart';

/// Windows implementation for native file system integration
class WindowsNativeFileSystemAdapter extends NativeFileSystemAdapterBase {
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('WindowsNativeFileSystemAdapter');
  
  // Windows-specific configuration keys
  static const String _configKeyAutoMount = 'win_native_fs_auto_mount';
  static const String _configKeyMountPoint = 'win_native_fs_mount_point';
  
  /// Drive letter for the virtual drive (default: X:)
  String _driveLetter = 'X:';
  
  /// Path to the local sync folder
  final String _localSyncFolder;
  
  WindowsNativeFileSystemAdapter(this._secureStorage, this._localSyncFolder);
  
  @override
  Future<bool> initialize() async {
    try {
      await loadConfiguration();
      
      // Check if WinFsp is installed
      if (!await _isWinFspInstalled()) {
        _logger.warning('WinFsp is not installed. Required for virtual drive functionality.');
        return false;
      }
      
      // Check if we should auto-mount
      if (_autoMount) {
        final mountPoint = await _secureStorage.getString(_configKeyMountPoint) ?? _driveLetter;
        return await mountVirtualDrive(mountPoint);
      }
      
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize Windows Native FS Adapter: $e');
      return false;
    }
  }
  
  @override
  Future<bool> mountVirtualDrive(String mountPoint) async {
    try {
      if (await isVirtualDriveMounted()) {
        _logger.info('Virtual drive already mounted at $_mountPoint');
        return true;
      }
      
      // Ensure mountPoint is a valid drive letter with colon
      if (mountPoint.length != 2 || mountPoint[1] != ':') {
        mountPoint = 'X:';
      }
      _driveLetter = mountPoint;
      
      // Use DokanNet (via a helper executable we bundle) to mount the virtual drive
      final ShellResult result = await runExecutableArguments(
        'OxiCloudVirtualDrive.exe',
        ['mount', _driveLetter, _localSyncFolder]
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to mount virtual drive: ${result.stderr}');
        return false;
      }
      
      // Update state
      setMountedState(true, _driveLetter);
      await _secureStorage.setString(_configKeyMountPoint, _driveLetter);
      
      _logger.info('Virtual drive mounted at $_driveLetter mapping to $_localSyncFolder');
      return true;
    } catch (e) {
      _logger.severe('Failed to mount virtual drive: $e');
      return false;
    }
  }
  
  @override
  Future<bool> unmountVirtualDrive() async {
    try {
      if (!await isVirtualDriveMounted()) {
        return true;
      }
      
      // Use DokanNet (via a helper executable we bundle) to unmount the virtual drive
      final ShellResult result = await runExecutableArguments(
        'OxiCloudVirtualDrive.exe',
        ['unmount', _driveLetter]
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to unmount virtual drive: ${result.stderr}');
        return false;
      }
      
      // Update state
      setMountedState(false, null);
      
      _logger.info('Virtual drive unmounted from $_driveLetter');
      return true;
    } catch (e) {
      _logger.severe('Failed to unmount virtual drive: $e');
      return false;
    }
  }
  
  @override
  Future<void> refreshDirectory(String directoryPath) async {
    try {
      if (!await isVirtualDriveMounted()) {
        return;
      }
      
      // Use SHChangeNotify from shell32.dll (via our helper executable)
      await runExecutableArguments(
        'OxiCloudVirtualDrive.exe',
        ['refresh', directoryPath]
      );
    } catch (e) {
      _logger.warning('Failed to refresh directory: $directoryPath - $e');
    }
  }
  
  @override
  Future<bool> openFileWithDefaultAppInternal(File file) async {
    try {
      final Uri uri = Uri.file(file.path);
      return await launchUrl(uri);
    } catch (e) {
      _logger.warning('Failed to open file: ${file.path} - $e');
      return false;
    }
  }
  
  @override
  Future<bool> revealInFileExplorer(String filePath) async {
    try {
      // Use Explorer to select the specific file
      final ShellResult result = await runExecutableArguments(
        'explorer.exe',
        ['/select,', filePath]
      );
      
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('Failed to reveal file in explorer: $filePath - $e');
      return false;
    }
  }
  
  @override
  Future<List<String>> getVirtualDriveRequirements() async {
    return [
      'Windows 10 or later',
      'WinFsp 1.9 or later installed',
      'Administrator rights for first-time setup'
    ];
  }
  
  @override
  Future<bool> checkVirtualDriveRequirements() async {
    try {
      // Check if WinFsp is installed
      if (!await _isWinFspInstalled()) {
        return false;
      }
      
      // Check if user has admin rights if needed
      // This is a simplified check, might need to be improved
      if (!await _canWriteToSystemDirectories()) {
        _logger.warning('User does not have sufficient privileges for virtual drive setup');
        return false;
      }
      
      return true;
    } catch (e) {
      _logger.warning('Failed to check virtual drive requirements: $e');
      return false;
    }
  }
  
  @override
  Future<Map<String, String>> getVirtualDriveLimitations() async {
    return {
      'max_path_length': '260 characters (Windows limitation)',
      'invalid_characters': r'< > : " / \ | ? *',
      'offline_access': 'Limited to files already synced locally',
      'performance': 'May be slower than direct file access for large files'
    };
  }
  
  @override
  Future<void> persistConfiguration() async {
    await _secureStorage.setBool(_configKeyAutoMount, _autoMount);
    if (_mountPoint != null) {
      await _secureStorage.setString(_configKeyMountPoint, _mountPoint!);
    }
    
    // Add start-on-boot registry entry if auto-mount is enabled
    await _setStartOnBoot(_autoMount);
  }
  
  @override
  Future<void> loadConfiguration() async {
    _autoMount = await _secureStorage.getBool(_configKeyAutoMount) ?? false;
    _mountPoint = await _secureStorage.getString(_configKeyMountPoint);
    
    // Check if we have an active mount
    if (_mountPoint != null) {
      final mounted = await _isDriveMounted(_mountPoint!);
      setMountedState(mounted, mounted ? _mountPoint : null);
    }
  }
  
  /// Check if WinFsp is installed
  Future<bool> _isWinFspInstalled() async {
    try {
      // Check the registry for WinFsp installation
      final regKey = Registry.openPath(RegistryHive.localMachine, 
                                       path: r'SOFTWARE\WOW6432Node\WinFsp');
      return regKey != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if the given drive letter is currently mounted
  Future<bool> _isDriveMounted(String driveLetter) async {
    try {
      final Directory dir = Directory('$driveLetter\\');
      return await dir.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Check if the user can write to system directories
  Future<bool> _canWriteToSystemDirectories() async {
    try {
      final programFilesDir = Directory(path.join(Platform.environment['ProgramFiles'] ?? 'C:\\Program Files', 'OxiCloud'));
      
      // Try to create a temporary file in Program Files
      final tempFile = File(path.join(programFilesDir.path, 'test_write_${DateTime.now().millisecondsSinceEpoch}.tmp'));
      
      if (!programFilesDir.existsSync()) {
        await programFilesDir.create(recursive: true);
      }
      
      await tempFile.writeAsString('test');
      await tempFile.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Set the application to start on boot via Registry
  Future<void> _setStartOnBoot(bool enabled) async {
    try {
      final executablePath = Platform.resolvedExecutable;
      final runKey = Registry.openPath(RegistryHive.currentUser, 
                                      path: r'SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
                                      desiredAccessRights: AccessRights.allAccess);
                                      
      if (runKey == null) {
        _logger.warning('Could not open Run registry key');
        return;
      }
      
      if (enabled) {
        // Add entry to run key
        runKey.createValue(RegistryValue(
          'OxiCloudClient',
          RegistryValueType.string,
          '"$executablePath" --start-minimized'
        ));
      } else {
        // Remove entry from run key
        if (runKey.getValueNames().contains('OxiCloudClient')) {
          runKey.deleteValue('OxiCloudClient');
        }
      }
    } catch (e) {
      _logger.warning('Failed to update start on boot settings: $e');
    }
  }
}