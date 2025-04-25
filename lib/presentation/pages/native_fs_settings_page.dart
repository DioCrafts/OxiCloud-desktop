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
    // Simplify the UI to ensure it compiles
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Native File System Integration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'OxiCloud can integrate with your operating system to provide a '
                        'virtual drive that appears like any other drive or folder in your file explorer. '
                        'This allows you to work with your files using your favorite apps, '
                        'without needing to download them first.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mount Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          final mountPoint = _getDefaultMountPoint(context);
                          await getIt<NativeFileSystemService>().mountVirtualDrive(mountPoint);
                          ref.refresh(nativeFsMountedProvider);
                        },
                        child: const Text('Mount Virtual Drive'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDefaultMountPoint(BuildContext? buildContext) {
    final platform = buildContext != null ? Theme.of(buildContext).platform : TargetPlatform.linux;
    if (TargetPlatform.windows == platform) {
      return 'X:';
    } else if (TargetPlatform.macOS == platform) {
      return '/Volumes/OxiCloud';
    } else {
      return '~/OxiCloud';
    }
  }
}