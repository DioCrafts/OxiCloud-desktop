import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/sync_service.dart';
import 'package:oxicloud_desktop/presentation/providers/sync_provider.dart';
import 'package:intl/intl.dart';

/// Widget for displaying synchronization status
class SyncStatusIndicator extends ConsumerWidget {
  /// Whether to show the sync button
  final bool showSyncButton;
  
  /// Create a SyncStatusIndicator
  const SyncStatusIndicator({
    super.key,
    this.showSyncButton = true,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatusAsync = ref.watch(syncStatusProvider);
    final lastSyncTime = ref.watch(lastSyncTimeProvider);
    final isSyncing = ref.watch(isSyncingProvider);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        syncStatusAsync.when(
          data: (status) => _buildStatusIcon(status),
          loading: () => const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          error: (_, __) => const Icon(
            Icons.sync_problem,
            color: Colors.red,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: syncStatusAsync.when(
            data: (status) => Text(
              _getStatusText(status, lastSyncTime),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            loading: () => const Text('Loading sync status...'),
            error: (_, __) => const Text('Sync status unknown'),
          ),
        ),
        if (showSyncButton) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.sync, size: 20),
            tooltip: 'Sync now',
            onPressed: isSyncing
                ? null
                : () => ref.read(syncNotifierProvider.notifier).syncNow(),
          ),
        ],
      ],
    );
  }
  
  /// Build status icon based on sync status
  Widget _buildStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.syncing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        );
      case SyncStatus.synced:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        );
      case SyncStatus.failed:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 16,
        );
      case SyncStatus.paused:
        return const Icon(
          Icons.pause_circle_filled,
          color: Colors.amber,
          size: 16,
        );
      case SyncStatus.conflict:
        return const Icon(
          Icons.warning,
          color: Colors.orange,
          size: 16,
        );
      case SyncStatus.initial:
        return const Icon(
          Icons.sync_disabled,
          color: Colors.grey,
          size: 16,
        );
    }
  }
  
  /// Get status text based on sync status
  String _getStatusText(SyncStatus status, DateTime? lastSyncTime) {
    switch (status) {
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.synced:
        if (lastSyncTime != null) {
          return 'Last sync: ${_formatLastSyncTime(lastSyncTime)}';
        }
        return 'Synced';
      case SyncStatus.failed:
        return 'Sync failed';
      case SyncStatus.paused:
        return 'Sync paused';
      case SyncStatus.conflict:
        return 'Sync conflicts detected';
      case SyncStatus.initial:
        return 'Not synced yet';
    }
  }
  
  /// Format last sync time
  String _formatLastSyncTime(DateTime lastSyncTime) {
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime);
    
    if (difference.inSeconds < 10) {
      return 'just now';
    } else if (difference.inMinutes < 1) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y').format(lastSyncTime);
    }
  }
}