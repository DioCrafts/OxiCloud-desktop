import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/application/services/auth_service.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/infrastructure/services/background_sync_service.dart';
import 'package:oxicloud_desktop/infrastructure/services/local_storage_manager.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';

/// Page for application settings
class SettingsPage extends ConsumerStatefulWidget {
  /// Create a SettingsPage
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final AppConfig _appConfig = getIt<AppConfig>();
  final LocalStorageManager _storageManager = getIt<LocalStorageManager>();
  final BackgroundSyncService _backgroundSyncService = getIt<BackgroundSyncService>();
  
  // Local state for toggles and sliders
  late bool _syncOnWifiOnly;
  late bool _enableBackgroundSync;
  late bool _uploadOnWifiOnly;
  late int _syncIntervalMinutes;
  late int _maxCacheSizeMB;
  
  // State for storage info
  int _cacheSize = 0;
  int _offlineSize = 0;
  
  @override
  void initState() {
    super.initState();
    
    // Load current settings
    _syncOnWifiOnly = _appConfig.syncOnWifiOnly;
    _enableBackgroundSync = _appConfig.enableBackgroundSync;
    _uploadOnWifiOnly = _appConfig.uploadOnWifiOnly;
    _syncIntervalMinutes = _appConfig.syncIntervalMinutes;
    _maxCacheSizeMB = _appConfig.maxCacheSizeMB;
    
    // Load storage info
    _loadStorageInfo();
  }
  
  Future<void> _loadStorageInfo() async {
    final cacheSize = await _storageManager.getCacheSize();
    final offlineSize = await _storageManager.getOfflineSize();
    
    setState(() {
      _cacheSize = cacheSize;
      _offlineSize = offlineSize;
    });
  }
  
  void _saveSettings() {
    // Save settings to AppConfig
    _appConfig.syncOnWifiOnly = _syncOnWifiOnly;
    _appConfig.enableBackgroundSync = _enableBackgroundSync;
    _appConfig.uploadOnWifiOnly = _uploadOnWifiOnly;
    _appConfig.syncIntervalMinutes = _syncIntervalMinutes;
    _appConfig.maxCacheSizeMB = _maxCacheSizeMB;
    
    // Update background sync
    _backgroundSyncService.setBackgroundSyncEnabled(_enableBackgroundSync);
    _backgroundSyncService.updateSyncInterval();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved'),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the cache? '
          'This will delete all cached files that are not marked for offline access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _storageManager.clearCache();
      await _loadStorageInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
  
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? '
          'Your cached files will remain on the device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
  
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return i == 0
        ? '$size ${suffixes[i]}'
        : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
  
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account section
          ListTile(
            title: const Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            tileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          if (currentUser != null) ...[
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(currentUser.displayName),
              subtitle: Text(currentUser.username),
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Storage Usage'),
              subtitle: Text(
                '${_formatSize(currentUser.usedBytes)} of '
                '${currentUser.quotaBytes == 0 ? 'Unlimited' : _formatSize(currentUser.quotaBytes)}',
              ),
              trailing: currentUser.quotaBytes > 0
                  ? SizedBox(
                      width: 50,
                      child: LinearProgressIndicator(
                        value: currentUser.usagePercentage / 100,
                      ),
                    )
                  : null,
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
          
          // Sync section
          ListTile(
            title: const Text(
              'Synchronization',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            tileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          SwitchListTile(
            title: const Text('Sync on WiFi Only'),
            subtitle: const Text('Only sync when connected to WiFi'),
            value: _syncOnWifiOnly,
            onChanged: (value) {
              setState(() {
                _syncOnWifiOnly = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Upload on WiFi Only'),
            subtitle: const Text('Only upload files when connected to WiFi'),
            value: _uploadOnWifiOnly,
            onChanged: (value) {
              setState(() {
                _uploadOnWifiOnly = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Background Sync'),
            subtitle: const Text('Sync in the background when the app is closed'),
            value: _enableBackgroundSync,
            onChanged: (value) {
              setState(() {
                _enableBackgroundSync = value;
              });
            },
          ),
          ListTile(
            title: const Text('Sync Interval'),
            subtitle: Text('${_syncIntervalMinutes} minutes'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                min: 15,
                max: 240,
                divisions: 15,
                value: _syncIntervalMinutes.toDouble(),
                label: '${_syncIntervalMinutes}m',
                onChanged: (value) {
                  setState(() {
                    _syncIntervalMinutes = value.toInt();
                  });
                },
              ),
            ),
          ),
          
          // Storage section
          ListTile(
            title: const Text(
              'Storage',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            tileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          ListTile(
            title: const Text('Cache Size'),
            subtitle: Text('Maximum cache size: ${_maxCacheSizeMB} MB'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                min: 50,
                max: 1000,
                divisions: 19,
                value: _maxCacheSizeMB.toDouble(),
                label: '${_maxCacheSizeMB}MB',
                onChanged: (value) {
                  setState(() {
                    _maxCacheSizeMB = value.toInt();
                  });
                },
              ),
            ),
          ),
          ListTile(
            title: const Text('Current Cache Usage'),
            subtitle: Text('${_formatSize(_cacheSize)} used for cache'),
            trailing: TextButton(
              onPressed: _clearCache,
              child: const Text('Clear Cache'),
            ),
          ),
          ListTile(
            title: const Text('Offline Files'),
            subtitle: Text('${_formatSize(_offlineSize)} used for offline files'),
          ),
          
          // Advanced features section
          ListTile(
            title: const Text(
              'Advanced Features',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            tileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          ListTile(
            leading: const Icon(Icons.folder_special),
            title: const Text('Native File System Integration'),
            subtitle: const Text('Access OxiCloud files directly from your system file explorer'),
            onTap: () {
              context.push('/native-fs');
            },
          ),
          
          // About section
          ListTile(
            title: const Text(
              'About',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            tileColor: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
          ),
          const ListTile(
            title: Text('OxiCloud Desktop'),
            subtitle: Text('Version 0.1.0'),
          ),
          
          // Save button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }
}