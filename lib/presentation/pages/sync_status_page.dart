import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/sync_service.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/core/platform/battery_service.dart';
import 'package:oxicloud_desktop/infrastructure/services/background_sync_service.dart';
import 'package:oxicloud_desktop/presentation/providers/sync_provider.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:intl/intl.dart';

/// Page for displaying synchronization status and history
class SyncStatusPage extends ConsumerStatefulWidget {
  /// Create a SyncStatusPage
  const SyncStatusPage({super.key});

  @override
  ConsumerState<SyncStatusPage> createState() => _SyncStatusPageState();
}

class _SyncStatusPageState extends ConsumerState<SyncStatusPage> {
  final BatteryService _batteryService = getIt<BatteryService>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();
  final BackgroundSyncService _backgroundSyncService = getIt<BackgroundSyncService>();
  
  BatteryInfo? _batteryInfo;
  NetworkType? _networkType;
  
  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }
  
  Future<void> _loadDeviceInfo() async {
    // Get battery info
    final batteryInfo = await _batteryService.getBatteryInfo();
    
    // Get network type
    final networkType = await _connectivityService.getConnectionType();
    
    if (mounted) {
      setState(() {
        _batteryInfo = batteryInfo;
        _networkType = networkType;
      });
    }
  }
  
  Future<void> _refreshDeviceInfo() async {
    await _loadDeviceInfo();
  }
  
  Future<void> _syncNow() async {
    await _backgroundSyncService.syncNow();
  }
  
  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final syncStatsAsync = ref.watch(syncStatsProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshDeviceInfo,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshDeviceInfo,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current sync status
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    syncStatusAsync.when(
                      data: (status) => _buildCurrentStatus(status, lastSyncTime),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: isSyncing ? null : _syncNow,
                        icon: const Icon(Icons.sync),
                        label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Sync conditions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sync Conditions',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildSyncConditions(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Last sync results
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Sync Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    syncStatsAsync.when(
                      data: (stats) => _buildSyncStats(stats),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentStatus(SyncStatus status, DateTime? lastSyncTime) {
    IconData iconData;
    Color iconColor;
    String statusText;
    
    switch (status) {
      case SyncStatus.syncing:
        iconData = Icons.sync;
        iconColor = Colors.blue;
        statusText = 'Syncing...';
        break;
      case SyncStatus.synced:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        statusText = 'Synced';
        break;
      case SyncStatus.failed:
        iconData = Icons.error;
        iconColor = Colors.red;
        statusText = 'Sync Failed';
        break;
      case SyncStatus.paused:
        iconData = Icons.pause_circle_filled;
        iconColor = Colors.amber;
        statusText = 'Sync Paused';
        break;
      case SyncStatus.conflict:
        iconData = Icons.warning;
        iconColor = Colors.orange;
        statusText = 'Sync Conflicts';
        break;
      case SyncStatus.initial:
        iconData = Icons.sync_disabled;
        iconColor = Colors.grey;
        statusText = 'Not Synced Yet';
        break;
    }
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (lastSyncTime != null)
                    Text(
                      'Last sync: ${_formatDateTime(lastSyncTime)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ],
        ),
        if (status == SyncStatus.conflict)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton(
              onPressed: () {
                // Navigate to conflict resolution
              },
              child: const Text('Resolve Conflicts'),
            ),
          ),
      ],
    );
  }
  
  Widget _buildSyncConditions() {
    return Column(
      children: [
        _buildConditionItem(
          'Network',
          _networkType?.displayName ?? 'Unknown',
          _networkType != null && _networkType != NetworkType.none,
          icon: Icons.network_wifi,
        ),
        const Divider(),
        _buildConditionItem(
          'Battery',
          _batteryInfo != null 
              ? '${_batteryInfo!.level}%${_batteryInfo!.isCharging ? ' (Charging)' : ''}'
              : 'Unknown',
          _batteryInfo != null && (_batteryInfo!.level > 20 || _batteryInfo!.isCharging),
          icon: Icons.battery_charging_full,
        ),
        const Divider(),
        _buildConditionItem(
          'Background Sync',
          'Enabled',
          true,
          icon: Icons.sync,
        ),
      ],
    );
  }
  
  Widget _buildConditionItem(
    String title,
    String value,
    bool isOk, {
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isOk ? Colors.green : Colors.red,
      ),
      title: Text(title),
      subtitle: Text(value),
      trailing: Icon(
        isOk ? Icons.check_circle : Icons.error,
        color: isOk ? Colors.green : Colors.red,
      ),
    );
  }
  
  Widget _buildSyncStats(SyncStats stats) {
    if (stats.filesUploaded == 0 &&
        stats.filesDownloaded == 0 &&
        stats.filesDeleted == 0 &&
        stats.foldersCreated == 0 &&
        stats.foldersDeleted == 0) {
      return const Center(
        child: Text('No changes in last sync'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.filesUploaded > 0)
          _buildStatItem('Files Uploaded', stats.filesUploaded.toString()),
        if (stats.filesDownloaded > 0)
          _buildStatItem('Files Downloaded', stats.filesDownloaded.toString()),
        if (stats.filesDeleted > 0)
          _buildStatItem('Files Deleted', stats.filesDeleted.toString()),
        if (stats.foldersCreated > 0)
          _buildStatItem('Folders Created', stats.foldersCreated.toString()),
        if (stats.foldersDeleted > 0)
          _buildStatItem('Folders Deleted', stats.foldersDeleted.toString()),
        if (stats.conflicts > 0)
          _buildStatItem('Conflicts', stats.conflicts.toString()),
        const Divider(),
        _buildStatItem('Duration', _formatDuration(stats.duration)),
        _buildStatItem('Timestamp', _formatDateTime(stats.timestamp)),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, y HH:mm:ss').format(dateTime);
  }
  
  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds % 60;
    final minutes = duration.inMinutes % 60;
    final hours = duration.inHours;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}