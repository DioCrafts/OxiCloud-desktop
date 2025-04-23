import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/infrastructure/services/background_sync_service.dart';
import 'package:oxicloud_desktop/presentation/providers/folder_provider.dart';

/// Provider for initial folder selection state
final initialFolderSelectionProvider = 
    StateNotifierProvider<FolderSelectionNotifier, Map<String, bool>>((ref) {
  return FolderSelectionNotifier();
});

/// Notifier for folder selection state
class FolderSelectionNotifier extends StateNotifier<Map<String, bool>> {
  FolderSelectionNotifier() : super({});
  
  /// Toggle selection for a folder
  void toggleFolder(String folderId, bool selected) {
    state = {...state, folderId: selected};
  }
  
  /// Set all folders selection state
  void setAllFolders(Map<String, bool> folderStates) {
    state = folderStates;
  }
  
  /// Get selected folder IDs
  List<String> getSelectedFolderIds() {
    return state.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Page for initial sync configuration
class InitialSyncSetupPage extends ConsumerStatefulWidget {
  /// Create an InitialSyncSetupPage
  const InitialSyncSetupPage({super.key});

  @override
  ConsumerState<InitialSyncSetupPage> createState() => _InitialSyncSetupPageState();
}

class _InitialSyncSetupPageState extends ConsumerState<InitialSyncSetupPage> {
  final AppConfig _appConfig = getIt<AppConfig>();
  final BackgroundSyncService _backgroundSyncService = getIt<BackgroundSyncService>();
  
  // Sync settings
  bool _syncOnWifiOnly = false;
  bool _enableBackgroundSync = true;
  int _syncIntervalMinutes = 30;
  bool _syncAutomatically = true;
  
  // Folder loading state
  bool _isLoadingFolders = true;
  List<Folder> _rootFolders = [];
  String? _errorMessage;

  // Current step in the setup wizard
  int _currentStep = 0;
  
  @override
  void initState() {
    super.initState();
    _loadRootFolders();
    
    // Load initial settings from AppConfig
    _syncOnWifiOnly = _appConfig.syncOnWifiOnly;
    _enableBackgroundSync = _appConfig.enableBackgroundSync;
    _syncIntervalMinutes = _appConfig.syncIntervalMinutes;
  }
  
  Future<void> _loadRootFolders() async {
    setState(() {
      _isLoadingFolders = true;
      _errorMessage = null;
    });
    
    try {
      // Load root folders
      final folderProvider = ref.read(rootFoldersProvider.notifier);
      await folderProvider.loadRootFolders();
      
      // Get the loaded folders
      final foldersAsync = ref.read(rootFoldersProvider);
      _rootFolders = foldersAsync.whenOrNull(
            data: (folders) => folders,
          ) ??
          [];
      
      // Initialize folder selection state
      final folderStates = <String, bool>{};
      for (final folder in _rootFolders) {
        folderStates[folder.id] = true; // Select all by default
      }
      ref.read(initialFolderSelectionProvider.notifier).setAllFolders(folderStates);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load folders: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoadingFolders = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      // Save sync settings
      _appConfig.syncOnWifiOnly = _syncOnWifiOnly;
      _appConfig.enableBackgroundSync = _enableBackgroundSync;
      _appConfig.syncIntervalMinutes = _syncIntervalMinutes;
      
      // Save selected folders
      final selectedFolderIds = ref.read(initialFolderSelectionProvider.notifier).getSelectedFolderIds();
      // In a real implementation, you would save the selected folders
      // to a persistent storage and configure sync for these folders
      
      // Update background sync
      await _backgroundSyncService.setBackgroundSyncEnabled(_enableBackgroundSync);
      await _backgroundSyncService.updateSyncInterval();
      
      // Navigate to home page
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Setup'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            _saveSettings();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          // Step 1: Welcome
          Step(
            title: const Text('Welcome'),
            content: _buildWelcomeStep(),
            isActive: _currentStep == 0,
          ),
          // Step 2: Folder selection
          Step(
            title: const Text('Folders'),
            content: _buildFolderSelectionStep(),
            isActive: _currentStep == 1,
          ),
          // Step 3: Sync settings
          Step(
            title: const Text('Settings'),
            content: _buildSyncSettingsStep(),
            isActive: _currentStep == 2,
          ),
        ],
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: details.onStepContinue,
                  child: Text(_currentStep < 2 ? 'Next' : 'Finish'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildWelcomeStep() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 100,
              // If image is not available, use placeholder
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.cloud_done,
                size: 100,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to OxiCloud Desktop',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Let\'s set up your sync preferences. This will help us ensure your files are always up to date across all your devices.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFolderSelectionStep() {
    if (_isLoadingFolders) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade700,
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRootFolders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final folderStates = ref.watch(initialFolderSelectionProvider);
    
    return SizedBox(
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select folders to sync',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which folders you want to keep in sync with your device. You can change this later in the settings.',
          ),
          const SizedBox(height: 16),
          
          // All folders checkbox
          CheckboxListTile(
            title: const Text(
              'All folders',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _rootFolders.isNotEmpty &&
                _rootFolders.every((folder) => folderStates[folder.id] == true),
            onChanged: (value) {
              if (value != null) {
                final newStates = <String, bool>{};
                for (final folder in _rootFolders) {
                  newStates[folder.id] = value;
                }
                ref.read(initialFolderSelectionProvider.notifier).setAllFolders(newStates);
              }
            },
          ),
          
          const Divider(),
          
          // Folder list
          Expanded(
            child: _rootFolders.isEmpty
                ? const Center(
                    child: Text('No folders found'),
                  )
                : ListView.builder(
                    itemCount: _rootFolders.length,
                    itemBuilder: (context, index) {
                      final folder = _rootFolders[index];
                      final isSelected = folderStates[folder.id] ?? false;
                      
                      return CheckboxListTile(
                        title: Text(folder.name),
                        subtitle: Text(folder.path),
                        value: isSelected,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(initialFolderSelectionProvider.notifier).toggleFolder(
                              folder.id,
                              value,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSyncSettingsStep() {
    return SizedBox(
      height: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Settings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure how and when your files should be synchronized. These settings can be adjusted later.',
          ),
          const SizedBox(height: 16),
          
          // Sync automatically
          SwitchListTile(
            title: const Text('Sync automatically'),
            subtitle: const Text('Files will sync without manual intervention'),
            value: _syncAutomatically,
            onChanged: (value) {
              setState(() {
                _syncAutomatically = value;
                
                // If automatic sync is disabled, also disable background sync
                if (!value) {
                  _enableBackgroundSync = false;
                }
              });
            },
          ),
          
          // Background sync
          SwitchListTile(
            title: const Text('Background sync'),
            subtitle: const Text('Sync files even when the app is closed'),
            value: _enableBackgroundSync,
            onChanged: _syncAutomatically
                ? (value) {
                    setState(() {
                      _enableBackgroundSync = value;
                    });
                  }
                : null,
          ),
          
          // WiFi only
          SwitchListTile(
            title: const Text('Sync on WiFi only'),
            subtitle: const Text('Only sync when connected to WiFi'),
            value: _syncOnWifiOnly,
            onChanged: (value) {
              setState(() {
                _syncOnWifiOnly = value;
              });
            },
          ),
          
          // Sync interval
          ListTile(
            title: const Text('Sync interval'),
            subtitle: Text('${_syncIntervalMinutes} minutes'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                min: 15,
                max: 240,
                divisions: 15,
                value: _syncIntervalMinutes.toDouble(),
                label: '${_syncIntervalMinutes}m',
                onChanged: _syncAutomatically
                    ? (value) {
                        setState(() {
                          _syncIntervalMinutes = value.toInt();
                        });
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}