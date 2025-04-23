import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/native_fs_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/presentation/providers/native_fs_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/platform_adaptive_alert.dart';

/// Page for managing native file system integration settings
class NativeFileSystemSettingsPage extends ConsumerWidget {
  /// Create a NativeFileSystemSettingsPage
  const NativeFileSystemSettingsPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nativeFs = ref.watch(nativeFsProvider);
    final mountedStatus = ref.watch(nativeFsMountedProvider);
    final requirementsStatus = ref.watch(nativeFsRequirementsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native File System Integration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroSection(context),
              const SizedBox(height: 24),
              _buildStatusSection(context, mountedStatus),
              const SizedBox(height: 24),
              _buildRequirementsSection(context, requirementsStatus),
              const SizedBox(height: 24),
              _buildActionsSection(context, ref, mountedStatus),
              const SizedBox(height: 24),
              _buildSettingsSection(context, ref, nativeFs),
              const SizedBox(height: 24),
              _buildLimitationsSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildIntroSection(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Native File System Integration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Access your OxiCloud files directly from your system\'s file explorer. '
              'This feature mounts your OxiCloud files as a virtual drive, '
              'allowing you to browse and edit files as if they were on your local disk.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusSection(BuildContext context, AsyncValue<bool> mountedStatus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            mountedStatus.when(
              data: (isMounted) => Row(
                children: [
                  Icon(
                    isMounted ? Icons.check_circle : Icons.error_outline,
                    color: isMounted ? Colors.green : Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isMounted
                        ? 'Virtual drive is mounted'
                        : 'Virtual drive is not mounted',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String?>(
              future: getIt<NativeFileSystemService>().getVirtualDriveMountPoint(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    'Mount point: ${snapshot.data}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequirementsSection(BuildContext context, AsyncValue<bool> requirementsStatus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Requirements',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            requirementsStatus.when(
              data: (meetsRequirements) => Row(
                children: [
                  Icon(
                    meetsRequirements ? Icons.check_circle : Icons.error_outline,
                    color: meetsRequirements ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    meetsRequirements
                        ? 'Your system meets all requirements'
                        : 'Your system does not meet all requirements',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: getIt<NativeFileSystemService>().getVirtualDriveRequirements(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Required:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...snapshot.data!.map((requirement) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(requirement)),
                          ],
                        ),
                      )),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionsSection(BuildContext context, WidgetRef ref, AsyncValue<bool> mountedStatus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                mountedStatus.maybeWhen(
                  data: (isMounted) => ElevatedButton.icon(
                    icon: Icon(isMounted ? Icons.eject : Icons.drive_file_move),
                    label: Text(isMounted ? 'Unmount Drive' : 'Mount Drive'),
                    onPressed: () => isMounted
                        ? _unmountDrive(context, ref)
                        : _mountDrive(context, ref),
                  ),
                  orElse: () => const ElevatedButton(
                    onPressed: null,
                    child: Text('Loading...'),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Requirements'),
                  onPressed: () {
                    ref.refresh(nativeFsRequirementsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open in File Explorer'),
                onPressed: () async {
                  final mountPoint = await getIt<NativeFileSystemService>().getVirtualDriveMountPoint();
                  if (mountPoint != null) {
                    await getIt<NativeFileSystemService>().revealInFileExplorer(mountPoint);
                  } else {
                    if (context.mounted) {
                      showPlatformAdaptiveAlert(
                        context,
                        title: 'Not Mounted',
                        content: 'The virtual drive is not currently mounted.',
                        actions: [
                          PlatformAdaptiveAlertAction(
                            label: 'OK',
                            isDefaultAction: true,
                          ),
                        ],
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection(BuildContext context, WidgetRef ref, AsyncValue<bool> autoMountStatus) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            autoMountStatus.when(
              data: (autoMount) => SwitchListTile(
                title: const Text('Auto-mount on startup'),
                subtitle: const Text(
                  'Automatically mount the virtual drive when you start the application',
                ),
                value: autoMount,
                onChanged: (value) {
                  ref.read(nativeFsProvider.notifier).setAutoMount(value);
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                'Error: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Change mount location'),
              subtitle: const Text('Set where the virtual drive appears on your system'),
              trailing: const Icon(Icons.folder_open),
              onPressed: () => _showChangeMountPointDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLimitationsSection(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Limitations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, String>>(
              future: getIt<NativeFileSystemService>().getVirtualDriveLimitations(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.data!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key.replaceAll('_', ' ').toTitleCase()}:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(entry.value),
                        ],
                      ),
                    )).toList(),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _mountDrive(BuildContext context, WidgetRef ref) async {
    final mountPoint = await getIt<NativeFileSystemService>().getVirtualDriveMountPoint() ?? 
                     _getDefaultMountPoint();
    
    final success = await getIt<NativeFileSystemService>().mountVirtualDrive(mountPoint);
    
    if (success) {
      ref.refresh(nativeFsMountedProvider);
    } else if (context.mounted) {
      showPlatformAdaptiveAlert(
        context,
        title: 'Mount Failed',
        content: 'Failed to mount the virtual drive. Please check that your system '
                'meets all requirements and try again.',
        actions: [
          PlatformAdaptiveAlertAction(
            label: 'OK',
            isDefaultAction: true,
          ),
        ],
      );
    }
  }
  
  Future<void> _unmountDrive(BuildContext context, WidgetRef ref) async {
    final success = await getIt<NativeFileSystemService>().unmountVirtualDrive();
    
    if (success) {
      ref.refresh(nativeFsMountedProvider);
    } else if (context.mounted) {
      showPlatformAdaptiveAlert(
        context,
        title: 'Unmount Failed',
        content: 'Failed to unmount the virtual drive. Please make sure there are no '
                'open files or applications using the drive and try again.',
        actions: [
          PlatformAdaptiveAlertAction(
            label: 'OK',
            isDefaultAction: true,
          ),
        ],
      );
    }
  }
  
  void _showChangeMountPointDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    FutureBuilder<String?>(
      future: getIt<NativeFileSystemService>().getVirtualDriveMountPoint(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          controller.text = snapshot.data!;
        } else {
          controller.text = _getDefaultMountPoint();
        }
        
        return showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Change Mount Location'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enter the location where you want the virtual drive to appear on your system. '
                  'This will take effect the next time you mount the drive.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Mount Location',
                    helperText: 'e.g., X: (Windows) or /Volumes/OxiCloud (macOS/Linux)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final mountPoint = controller.text.trim();
                  if (mountPoint.isNotEmpty) {
                    // First unmount if currently mounted
                    if (await getIt<NativeFileSystemService>().isVirtualDriveMounted()) {
                      await getIt<NativeFileSystemService>().unmountVirtualDrive();
                    }
                    
                    // Mount with new location
                    final success = await getIt<NativeFileSystemService>().mountVirtualDrive(mountPoint);
                    
                    if (success) {
                      ref.refresh(nativeFsMountedProvider);
                    }
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Save & Mount'),
              ),
            ],
          ),
        );
      },
    );
  }
  
  String _getDefaultMountPoint() {
    if (TargetPlatform.windows == defaultTargetPlatform) {
      return 'X:';
    } else if (TargetPlatform.macOS == defaultTargetPlatform) {
      return '/Volumes/OxiCloud';
    } else {
      return '~/OxiCloud';
    }
  }
}

extension StringExtension on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.isEmpty 
        ? '' 
        : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
    ).join(' ');
  }
}