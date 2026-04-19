import 'package:flutter/material.dart';

import '../../core/sync/sync_models.dart';
import '../../core/theme/app_colors.dart';

class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final int pendingCount;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _resolve();
    return Tooltip(
      message: pendingCount > 0 ? '$label ($pendingCount pending)' : label,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == SyncStatus.syncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall!.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _resolve() {
    return switch (status) {
      SyncStatus.idle => (Icons.cloud_done, AppColors.syncIdle, 'Synced'),
      SyncStatus.syncing => (Icons.sync, AppColors.syncing, 'Syncing…'),
      SyncStatus.error => (Icons.cloud_off, AppColors.syncError, 'Sync error'),
      SyncStatus.offline => (Icons.wifi_off, AppColors.syncIdle, 'Offline'),
    };
  }
}
