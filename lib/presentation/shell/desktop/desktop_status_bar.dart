import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers.dart';
import '../../widgets/sync_status_indicator.dart';

class DesktopStatusBar extends ConsumerWidget {
  final int? itemCount;
  final int? selectedCount;

  const DesktopStatusBar({super.key, this.itemCount, this.selectedCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncEngine = ref.watch(syncEngineProvider);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (itemCount != null)
            Text(
              selectedCount != null && selectedCount! > 0
                  ? '$selectedCount of $itemCount selected'
                  : '$itemCount items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          const Spacer(),
          ListenableBuilder(
            listenable: syncEngine,
            builder: (context, _) => SyncStatusIndicator(
              status: syncEngine.status,
              pendingCount: syncEngine.pendingCount,
            ),
          ),
        ],
      ),
    );
  }
}
