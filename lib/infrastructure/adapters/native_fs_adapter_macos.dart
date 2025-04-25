import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_base.dart';
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';
// import 'package:url_launcher/url_launcher.dart';

/// macOS implementation for native file system integration
class MacOSNativeFileSystemAdapter extends NativeFileSystemAdapterBase {
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('MacOSNativeFileSystemAdapter');

  /// Path to macFUSE helper app
  final String _helperAppPath;
  
  // macOS-specific configuration keys
  static const String _configKeyAutoMount = 'macos_native_fs_auto_mount';
  static const String _configKeyMountPoint = 'macos_native_fs_mount_point';
  
  /// Default mount point in /Volumes
  String _volumeName = 'OxiCloud';
  
  /// Path to the local sync folder
  final String _localSyncFolder;
  
  /// Path to launch agent plist
  late final String _launchAgentPath;
  
  MacOSNativeFileSystemAdapter(this._secureStorage, this._localSyncFolder)
      : _helperAppPath = path.join(
          '/Applications/OxiCloud.app/Contents/Resources',
          'OxiCloudMounter.app/Contents/MacOS/OxiCloudMounter'
        ) {
    // Set up launch agent path
    final home = Platform.environment['HOME'];
    _launchAgentPath = path.join(
      home ?? '',
      'Library/LaunchAgents/com.oxicloud.mounter.plist'
    );
  }
  
  @override
  Future<bool> initialize() async {
    try {
      await loadConfiguration();
      
      // Check if macFUSE is installed
      if (!await _isMacFuseInstalled()) {
        _logger.warning('macFUSE is not installed. Required for virtual drive functionality.');
        return false;
      }
      
      // Check if we should auto-mount
      if (await getAutoMount()) {
        final mountPoint = await _secureStorage.getString(_configKeyMountPoint) ?? 
                           path.join('/Volumes', _volumeName);
        return await mountVirtualDrive(mountPoint);
      }
      
      return true;
    } catch (e) {
      _logger.severe('Failed to initialize macOS Native FS Adapter: $e');
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
        mountPoint = path.join('/Volumes', _volumeName);
      }
      
      // Create mount point directory if it doesn't exist
      final mountDir = Directory(mountPoint);
      if (!mountDir.existsSync()) {
        await mountDir.create(recursive: true);
      }
      
      // Use macFUSE via our helper app to mount the folder
      final result = await runExecutableArguments(
        _helperAppPath,
        ['mount', mountPoint, _localSyncFolder]
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to mount virtual drive: ${result.stderr}');
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
      
      // Use macFUSE via our helper app to unmount
      final result = await runExecutableArguments(
        'umount',
        [mountPoint]
      );
      
      if (result.exitCode != 0) {
        _logger.warning('Failed to unmount virtual drive: ${result.stderr}');
        
        // Try force unmount if regular unmount fails
        final forceResult = await runExecutableArguments(
          'umount',
          ['-f', mountPoint]
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
      
      // On macOS we use touch to update directory mtime which triggers a refresh
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
      // Use NSWorkspace to reveal the file in Finder
      final result = await runExecutableArguments(
        'open',
        ['-R', filePath]
      );
      
      return result.exitCode == 0;
    } catch (e) {
      _logger.warning('Failed to reveal file in Finder: $filePath - $e');
      return false;
    }
  }
  
  @override
  Future<List<String>> getVirtualDriveRequirements() async {
    return [
      'macOS 10.15 or later',
      'macFUSE 4.0 or later installed',
      'System Extensions allowed in Security & Privacy'
    ];
  }
  
  @override
  Future<bool> checkVirtualDriveRequirements() async {
    try {
      // Check if macFUSE is installed
      if (!await _isMacFuseInstalled()) {
        return false;
      }
      
      // Check version of macOS
      final osVersion = Platform.operatingSystemVersion;
      final versionParts = osVersion.split('.');
      
      if (versionParts.isNotEmpty) {
        final majorVersion = int.tryParse(versionParts[0]) ?? 0;
        if (majorVersion < 10) {
          _logger.warning('macOS version too old: $osVersion');
          return false;
        }
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
      'max_path_length': '1024 characters',
      'invalid_characters': 'None (all Unicode characters supported)',
      'offline_access': 'Limited to files already synced locally',
      'performance': 'May be slower than native filesystem for many small files'
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
    
    // Set up launch agent for auto-start if needed
    await _setupLaunchAgent(autoMount);
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
  
  /// Check if macFUSE is installed
  Future<bool> _isMacFuseInstalled() async {
    try {
      final macFusePkgResult = await runExecutableArguments(
        'pkgutil',
        ['--pkg-info', 'com.github.osxfuse.pkg.macFUSE']
      );
      
      if (macFusePkgResult.exitCode == 0) {
        return true;
      }
      
      // Alternative check for macFUSE 4.0+
      final macFuse4Result = await runExecutableArguments(
        'pkgutil',
        ['--pkg-info', 'io.macfuse.installer.macfuse']
      );
      
      return macFuse4Result.exitCode == 0;
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
  
  /// Set up or remove the launch agent for auto-start
  Future<void> _setupLaunchAgent(bool enabled) async {
    try {
      final launchAgentFile = File(_launchAgentPath);
      
      if (enabled) {
        // Create launch agent plist
        final plistContent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.oxicloud.mounter</string>
    <key>ProgramArguments</key>
    <array>
        <string>${_helperAppPath}</string>
        <string>mount</string>
        <string>${await getVirtualDriveMountPoint() ?? path.join('/Volumes', _volumeName)}</string>
        <string>${_localSyncFolder}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>''';

        await launchAgentFile.writeAsString(plistContent);
        
        // Load the launch agent
        await runExecutableArguments(
          'launchctl',
          ['load', _launchAgentPath]
        );
      } else {
        // Unload and remove the launch agent if it exists
        if (launchAgentFile.existsSync()) {
          await runExecutableArguments(
            'launchctl',
            ['unload', _launchAgentPath]
          );
          
          await launchAgentFile.delete();
        }
      }
    } catch (e) {
      _logger.warning('Failed to setup launch agent: $e');
    }
  }
}