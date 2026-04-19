import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/share_entity.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';

// --- State ---

class SharesState {
  final List<ShareEntity> shares;
  final bool loading;
  final String? error;

  const SharesState({this.shares = const [], this.loading = false, this.error});

  SharesState copyWith({
    List<ShareEntity>? shares,
    bool? loading,
    String? error,
  }) {
    return SharesState(
      shares: shares ?? this.shares,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// --- Notifier ---

class SharesNotifier extends Notifier<SharesState> {
  @override
  SharesState build() => const SharesState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final shares = await ref.read(shareRepositoryProvider).listShares();
      state = state.copyWith(shares: shares, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> deleteShare(String id) async {
    await ref.read(shareRepositoryProvider).deleteShare(id);
    await load();
  }
}

final sharesProvider = NotifierProvider<SharesNotifier, SharesState>(
  SharesNotifier.new,
);

// --- Page ---

class SharesPage extends ConsumerStatefulWidget {
  const SharesPage({super.key});

  @override
  ConsumerState<SharesPage> createState() => _SharesPageState();
}

class _SharesPageState extends ConsumerState<SharesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(sharesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sharesProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.shares.isEmpty) {
      body = const EmptyState(
        icon: Icons.share_outlined,
        title: 'No shares yet',
        subtitle: 'Share files from the file browser to see them here',
      );
    } else {
      body = ListView.builder(
        itemCount: state.shares.length,
        itemBuilder: (_, i) => _ShareTile(
          share: state.shares[i],
          onCopyLink: () {
            Clipboard.setData(ClipboardData(text: state.shares[i].url));
            AppDialogs.showSnack(context, 'Link copied to clipboard');
          },
          onDelete: () async {
            final confirm = await AppDialogs.showConfirm(
              context: context,
              title: 'Delete share?',
              message: 'The link will no longer work. This cannot be undone.',
              isDanger: true,
            );
            if (confirm) {
              ref.read(sharesProvider.notifier).deleteShare(state.shares[i].id);
            }
          },
        ),
      );
    }

    return AdaptiveShell(
      currentPath: '/shares',
      title: 'Shares',
      itemCount: state.shares.length,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(sharesProvider.notifier).load(),
        ),
      ],
      child: body,
    );
  }
}

class _ShareTile extends StatelessWidget {
  final ShareEntity share;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;

  const _ShareTile({
    required this.share,
    required this.onCopyLink,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = share.isExpired;

    return ListTile(
      leading: Icon(
        share.itemType == 'folder' ? Icons.folder : Icons.insert_drive_file,
        color: isExpired ? Colors.grey : Colors.amber.shade700,
      ),
      title: Text(
        share.itemName ?? share.itemId,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isExpired
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: Text(
        _buildSubtitle(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (share.hasPassword)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.lock,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy link',
            onPressed: onCopyLink,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete share',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    if (share.isExpired) {
      parts.add('Expired');
    } else if (share.expiresAt != null) {
      final diff = share.expiresAt!.difference(DateTime.now());
      if (diff.inDays > 0) {
        parts.add('Expires in ${diff.inDays}d');
      } else {
        parts.add('Expires in ${diff.inHours}h');
      }
    } else {
      parts.add('No expiration');
    }
    parts.add('${share.accessCount} views');
    final perms = <String>[];
    if (share.permissions.read) perms.add('read');
    if (share.permissions.write) perms.add('write');
    if (share.permissions.reshare) perms.add('reshare');
    if (perms.isNotEmpty) parts.add(perms.join('+'));
    return parts.join(' · ');
  }
}
