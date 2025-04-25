import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_base.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';
// import 'package:url_launcher/url_launcher.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

/// Linux implementation for native file system integration
class LinuxNativeFileSystemAdapter extends NativeFileSystemAdapterBase {
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('LinuxNativeFileSystemAdapter');
  
  // Linux-specific configuration keys
  static const String _configKeyAutoMount = 'linux_native_fs_auto_mount';
  static const String _configKeyMountPoint = 'linux_native_fs_mount_point';
  
  /// Path to the local sync folder
  final String _localSyncFolder;
  
  /// Default mount point path
  late final String _defaultMountPoint;
  
  /// Path to autostart file
  late final String _autostartFilePath;
  
  LinuxNativeFileSystemAdapter(this._secureStorage, this._localSyncFolder) {
    // Set default mount point in home directory
    final home = Platform.environment['HOME'];
    _defaultMountPoint = path.join(home ?? '/home/${Platform.environment['USER']}', 'OxiCloud');
    
    // Set autostart file path
    _autostartFilePath = path.join(
      xdg.configHome.path,
      'autostart',
      'oxicloud-mount.desktop'
    );
  }
  
  @override
  Future<bool> initialize() async {
    try {
      await loadConfiguration();
      
      // Check if FUSE is installed and available
      if (!await _isFuseAvailable()) {
        _logger.warning('FUSE is not available. Required for virtual filesystem functionality.');
        return false;
      }
      
      // Check if we should auto-mount
      if (await getAutoMount()) {
        final mountPoint = await _secureStorage.getString(_configKeyMountPoint) ?? _defaultMountPoint;
        return await mountVirtualDrive(mountPoint);
      }
      
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize Linux Native FS Adapter: $e');
      return false;
    }
  }
  
  @override
  Future<bool> mountVirtualDrive(String mountPoint) async {
    try {
      if (await isVirtualDriveMounted()) {
        final currentMountPoint = await getVirtualDriveMountPoint();
        _logger.info('Virtual drive already mounted at $currentMountPoint');
        return true;
      }
      
      // Use default if no mount point specified
      if (mountPoint.isEmpty) {
        mountPoint = _defaultMountPoint;
      }
      
      // Create mount point directory if it doesn't exist
      final mountDir = Directory(mountPoint);
      if (!mountDir.existsSync()) {
        await mountDir.create(recursive: true);
      }
      
      // Use FUSE to mount the folder
      final result = await runExecutableArguments(
        'fusermount',
        ['-o', 'allow_other', mountPoint]
      );
      
      // Command above should fail, now run our custom FUSE implementation
      final fuseResult = await runExecutableArguments(
        'oxicloud-fuse',
        [_localSyncFolder, mountPoint]
      );
      
      if (fuseResult.exitCode != 0) {
        _logger.warning('Failed to mount virtual drive: ${fuseResult.stderr}');
        return false;
      }
      
      // Update state and config
      setMountedState(true, mountPoint);
      await _secureStorage.setString(_configKeyMountPoint, mountPoint);
      
      _logger.info('Virtual drive mounted at $mountPoint mapping to $_localSyncFolder');
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
      
      final mountPoint = await getVirtualDriveMountPoint();
      if (mountPoint == null) {
        _logger.warning('No mount point found to unmount');
        return false;
      }
      
      // Use fusermount to unmount
      final result = await runExecutableArguments(
        'fusermount',
        ['-u', mountPoint]
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to unmount virtual drive: ${result.stderr}');
        
        // Try force unmount if regular unmount fails
        final forceResult = await runExecutableArguments(
          'fusermount',
          ['-uz', mountPoint]
        );
        
        if (forceResult.exitCode != 0) {
          _logger.severe('Force unmount also failed: ${forceResult.stderr}');
          return false;
        }
      }
      
      // Update state
      setMountedState(false, null);
      
      _logger.info('Virtual drive unmounted from $mountPoint');
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
      
      // On Linux we use touch to update directory mtime which triggers a refresh in most file managers
      await runExecutableArguments(
        'touch',
        [directoryPath]
      );
    } catch (e) {
      _logger.warning('Failed to refresh directory: $directoryPath - $e');
    }
  }
  
  @override
  Future<bool> openFileWithDefaultAppInternal(File file) async {
    try {
      // Try xdg-open first, which is the standard way on Linux
      final result = await runExecutableArguments(
        'xdg-open',
        [file.path]
      );
      
      if (result.exitCode == 0) {
        return true;
      }
      
      // URL Launcher disabled for Linux compilation
      _logger.info('URL Launcher disabled, unable to launch file');
      return false;
    } catch (e) {
      _logger.warning('Failed to open file: ${file.path} - $e');
      return false;
    }
  }
  
  @override
  Future<bool> revealInFileExplorer(String filePath) async {
    try {
      // Different file managers have different ways to reveal files
      // First, detect the file manager
      String? fileManager = await _detectFileManager();
      
      if (fileManager == null) {
        // Fallback to opening the parent directory
        final directory = path.dirname(filePath);
        final result = await runExecutableArguments(
          'xdg-open',
          [directory]
        );
        return result.exitCode == 0;
      } else {
        // Handle specific file managers
        switch (fileManager) {
          case 'nautilus': // GNOME Files
            return await _executeCommand('nautilus', ['--select', filePath]);
          case 'dolphin': // KDE Dolphin
            return await _executeCommand('dolphin', ['--select', filePath]);
          case 'nemo': // Cinnamon Nemo
            return await _executeCommand('nemo', ['--no-desktop', filePath]);
          case 'thunar': // XFCE Thunar
            return await _executeCommand('thunar', [path.dirname(filePath)]);
          default:
            // Default to opening the parent directory
            final directory = path.dirname(filePath);
            return await _executeCommand('xdg-open', [directory]);
        }
      }
    } catch (e) {
      _logger.warning('Failed to reveal file in file manager: $filePath - $e');
      return false;
    }
  }
  
  @override
  Future<List<String>> getVirtualDriveRequirements() async {
    return [
      'Linux with FUSE 2.9 or later installed',
      'User in the "fuse" group',
      'filesystem_in_userspace enabled in kernel'
    ];
  }
  
  @override
  Future<bool> checkVirtualDriveRequirements() async {
    try {
      // Check if FUSE is available
      if (!await _isFuseAvailable()) {
        return false;
      }
      
      // Check if user has necessary permissions
      if (!await _userHasFusePermissions()) {
        _logger.warning('User does not have FUSE permissions');
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
      'max_path_length': '4096 characters (Linux limitation)',
      'invalid_characters': 'None (all Unicode characters supported)',
      'offline_access': 'Limited to files already synced locally',
      'permissions': 'File permissions may differ from original files'
    };
  }
  
  @override
  Future<void> persistConfiguration() async {
    final autoMount = await getAutoMount();
    await _secureStorage.setBool(_configKeyAutoMount, autoMount);
    final mountPoint = await getVirtualDriveMountPoint();
    if (mountPoint != null) {
      await _secureStorage.setString(_configKeyMountPoint, mountPoint);
    }
    
    // Set up autostart entry if needed
    await _setupAutostart(autoMount);
  }
  
  @override
  Future<void> loadConfiguration() async {
    final autoMount = await _secureStorage.getBool(_configKeyAutoMount) ?? false;
    await setAutoMount(autoMount);
    final mountPoint = await _secureStorage.getString(_configKeyMountPoint);
    
    // Check if the mount point is actually mounted
    if (mountPoint != null) {
      final mounted = await _isPathMounted(mountPoint);
      setMountedState(mounted, mounted ? mountPoint : null);
    }
  }
  
  /// Check if FUSE is available on the system
  Future<bool> _isFuseAvailable() async {
    try {
      // Check if fusermount is available
      final fuseResult = await runExecutableArguments(
        'which',
        ['fusermount']
      );
      
      if (fuseResult.exitCode != 0) {
        return false;
      }
      
      // Check if FUSE module is loaded
      final lsmodResult = await runExecutableArguments(
        'lsmod',
        []
      );
      
      return lsmodResult.stdout.contains('fuse');
    } catch (e) {
      return false;
    }
  }
  
  /// Check if user has necessary FUSE permissions
  Future<bool> _userHasFusePermissions() async {
    try {
      // Try to touch a test file to see if we have permissions
      final String testPath = '/tmp/oxicloud_fuse_test_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await runExecutableArguments(
        'touch',
        [testPath]
      );
      
      if (result.exitCode != 0) {
        return false;
      }
      
      // Clean up test file
      await File(testPath).delete();
      
      // Check if user is in the fuse group
      final groupsResult = await runExecutableArguments(
        'groups',
        []
      );
      
      final String groups = groupsResult.stdout.toLowerCase();
      
      return groups.contains('fuse') || 
             groups.contains('plugdev') ||
             await _canUserMountFuse();
    } catch (e) {
      return false;
    }
  }
  
  /// Check if the user can mount with FUSE
  Future<bool> _canUserMountFuse() async {
    try {
      // Try to create a test FUSE mount
      final String testMountPoint = '/tmp/oxicloud_fuse_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // Create the mount point
      await Directory(testMountPoint).create();
      
      // Try to mount with FUSE
      final result = await runExecutableArguments(
        'fusermount',
        ['-V'] // Just get version info, don't actually mount
      );
      
      // Clean up test mount point
      await Directory(testMountPoint).delete();
      
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if a path is currently mounted
  Future<bool> _isPathMounted(String mountPath) async {
    try {
      final result = await runExecutableArguments(
        'mount',
        []
      );
      
      return result.stdout.contains(mountPath);
    } catch (e) {
      return false;
    }
  }
  
  /// Set up or remove autostart entry
  Future<void> _setupAutostart(bool enabled) async {
    try {
      final autostartDir = Directory(path.dirname(_autostartFilePath));
      final autostartFile = File(_autostartFilePath);
      
      if (enabled) {
        // Create autostart directory if it doesn't exist
        if (!autostartDir.existsSync()) {
          await autostartDir.create(recursive: true);
        }
        
        // Create autostart desktop entry
        final desktopEntry = '''[Desktop Entry]
Type=Application
Name=OxiCloud Mount
Exec=${Platform.resolvedExecutable} --mount-drive
Icon=oxicloud
Terminal=false
X-GNOME-Autostart-enabled=true
X-KDE-autostart-after=panel
X-MATE-Autostart-enabled=true
NoDisplay=false
''';

        await autostartFile.writeAsString(desktopEntry);
      } else {
        // Remove autostart file if it exists
        if (autostartFile.existsSync()) {
          await autostartFile.delete();
        }
      }
    } catch (e) {
      _logger.warning('Failed to setup autostart: $e');
    }
  }
  
  /// Detect the user's file manager
  Future<String?> _detectFileManager() async {
    try {
      // Check common desktop environments
      final desktopEnv = Platform.environment['XDG_CURRENT_DESKTOP']?.toLowerCase() ?? '';
      
      if (desktopEnv.contains('gnome')) {
        return 'nautilus';
      } else if (desktopEnv.contains('kde')) {
        return 'dolphin';
      } else if (desktopEnv.contains('xfce')) {
        return 'thunar';
      } else if (desktopEnv.contains('cinnamon')) {
        return 'nemo';
      }
      
      // Try to detect by checking which file manager is installed
      final fileManagers = ['nautilus', 'dolphin', 'nemo', 'thunar', 'pcmanfm', 'caja'];
      
      for (final fm in fileManagers) {
        final result = await runExecutableArguments(
          'which',
          [fm]
        );
        
        if (result.exitCode == 0) {
          return fm;
        }
      }
      
      return null;
    } catch (e) {
      _logger.warning('Failed to detect file manager: $e');
      return null;
    }
  }
  
  /// Execute a command and return success status
  Future<bool> _executeCommand(String command, List<String> args) async {
    try {
      final result = await runExecutableArguments(command, args);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('Failed to execute command: $command $args - $e');
      return false;
    }
  }
}