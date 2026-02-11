import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/settings/settings_bloc.dart';
import '../theme/oxicloud_colors.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(const LoadSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 48, color: OxiColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettingsBloc>().add(const LoadSettings());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SettingsLoaded) {
            return _buildSettingsList(context, state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context, SettingsLoaded state) {
    final config = state.config;

    return ListView(
      children: [
        // Sync Settings Section
        _buildSectionHeader('Sync Settings'),
        
        ListTile(
          leading: const Icon(Icons.folder),
          title: const Text('Sync Folder'),
          subtitle: Text(config.syncFolder),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _selectSyncFolder(context),
        ),

        ListTile(
          leading: const Icon(Icons.timer),
          title: const Text('Sync Interval'),
          subtitle: Text(_formatInterval(config.syncIntervalSeconds)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSyncIntervalDialog(context, config.syncIntervalSeconds),
        ),

        SwitchListTile(
          secondary: const Icon(Icons.speed),
          title: const Text('Delta Sync'),
          subtitle: const Text('Only upload changed parts of files'),
          value: config.deltaSyncEnabled,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleDeltaSync(value));
          },
        ),

        SwitchListTile(
          secondary: const Icon(Icons.visibility),
          title: const Text('Watch Filesystem'),
          subtitle: const Text('Automatically detect file changes'),
          value: config.watchFilesystem,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleFilesystemWatch(value));
          },
        ),

        const Divider(),

        // Network Settings Section
        _buildSectionHeader('Network'),

        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Upload Speed Limit'),
          subtitle: Text(config.maxUploadSpeedKbps == 0
              ? 'Unlimited'
              : '${config.maxUploadSpeedKbps} KB/s'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSpeedLimitDialog(
            context,
            'Upload',
            config.maxUploadSpeedKbps,
            (value) {
              context.read<SettingsBloc>().add(UpdateBandwidthLimits(
                    uploadKbps: value,
                    downloadKbps: config.maxDownloadSpeedKbps,
                  ));
            },
          ),
        ),

        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Download Speed Limit'),
          subtitle: Text(config.maxDownloadSpeedKbps == 0
              ? 'Unlimited'
              : '${config.maxDownloadSpeedKbps} KB/s'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSpeedLimitDialog(
            context,
            'Download',
            config.maxDownloadSpeedKbps,
            (value) {
              context.read<SettingsBloc>().add(UpdateBandwidthLimits(
                    uploadKbps: config.maxUploadSpeedKbps,
                    downloadKbps: value,
                  ));
            },
          ),
        ),

        // Only show mobile network options on mobile platforms
        if (Platform.isAndroid || Platform.isIOS) ...[
          SwitchListTile(
            secondary: const Icon(Icons.wifi),
            title: const Text('WiFi Only'),
            subtitle: const Text('Only sync when connected to WiFi'),
            value: config.wifiOnly,
            onChanged: (value) {
              context.read<SettingsBloc>().add(ToggleWifiOnly(value));
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.data_usage),
            title: const Text('Pause on Metered'),
            subtitle: const Text('Pause sync on metered connections'),
            value: config.pauseOnMetered,
            onChanged: (value) {
              context.read<SettingsBloc>().add(TogglePauseOnMetered(value));
            },
          ),
        ],

        const Divider(),

        // App Settings Section
        _buildSectionHeader('Application'),

        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          subtitle: const Text('Show sync notifications'),
          value: config.notificationsEnabled,
          onChanged: (value) {
            context.read<SettingsBloc>().add(ToggleNotifications(value));
          },
        ),

        // Desktop-only options
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) ...[
          SwitchListTile(
            secondary: const Icon(Icons.launch),
            title: const Text('Launch at Startup'),
            subtitle: const Text('Start OxiCloud when you log in'),
            value: config.launchAtStartup,
            onChanged: (value) {
              context.read<SettingsBloc>().add(ToggleLaunchAtStartup(value));
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.minimize),
            title: const Text('Minimize to Tray'),
            subtitle: const Text('Keep running in system tray'),
            value: config.minimizeToTray,
            onChanged: (value) {
              context.read<SettingsBloc>().add(ToggleMinimizeToTray(value));
            },
          ),
        ],

        const Divider(),

        // Ignore Patterns Section
        _buildSectionHeader('Ignore Patterns'),

        ListTile(
          leading: const Icon(Icons.filter_list),
          title: const Text('File Ignore Patterns'),
          subtitle: Text('${config.ignorePatterns.length} patterns configured'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showIgnorePatternsDialog(context, config.ignorePatterns),
        ),

        const Divider(),

        // About Section
        _buildSectionHeader('About'),

        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),

        ListTile(
          leading: const Icon(Icons.code),
          title: const Text('GitHub'),
          subtitle: const Text('https://github.com/oxicloud'),
          onTap: () {
            // TODO: Open GitHub URL
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  String _formatInterval(int seconds) {
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${seconds ~/ 60} minutes';
    return '${seconds ~/ 3600} hours';
  }

  Future<void> _selectSyncFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      if (context.mounted) {
        context.read<SettingsBloc>().add(UpdateSyncFolder(result));
      }
    }
  }

  Future<void> _showSyncIntervalDialog(BuildContext context, int currentSeconds) async {
    final intervals = [
      (60, '1 minute'),
      (300, '5 minutes'),
      (600, '10 minutes'),
      (1800, '30 minutes'),
      (3600, '1 hour'),
    ];

    await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sync Interval'),
        children: intervals.map((interval) {
          final (seconds, label) = interval;
          return RadioListTile<int>(
            value: seconds,
            groupValue: currentSeconds,
            title: Text(label),
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(UpdateSyncInterval(value));
              }
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showSpeedLimitDialog(
    BuildContext context,
    String type,
    int currentKbps,
    void Function(int) onChanged,
  ) async {
    final controller = TextEditingController(
      text: currentKbps == 0 ? '' : currentKbps.toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type Speed Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Speed (KB/s)',
                hintText: 'Leave empty for unlimited',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set to 0 or leave empty for unlimited speed',
              style: TextStyle(fontSize: 12, color: OxiColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text) ?? 0;
              onChanged(value);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showIgnorePatternsDialog(
    BuildContext context,
    List<String> currentPatterns,
  ) async {
    final controller = TextEditingController(
      text: currentPatterns.join('\n'),
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ignore Patterns'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter patterns to ignore (one per line):',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 6,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '*.tmp\n.DS_Store\n~*',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Examples: *.tmp, .DS_Store, ~*, Thumbs.db',
                style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final patterns = controller.text
                  .split('\n')
                  .map((p) => p.trim())
                  .where((p) => p.isNotEmpty)
                  .toList();
              context.read<SettingsBloc>().add(UpdateIgnorePatterns(patterns));
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
