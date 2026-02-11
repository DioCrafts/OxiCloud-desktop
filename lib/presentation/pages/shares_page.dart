import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/share_item.dart';
import '../blocs/share/share_bloc.dart';
import '../theme/oxicloud_colors.dart';

class SharesPage extends StatefulWidget {
  const SharesPage({super.key});

  @override
  State<SharesPage> createState() => _SharesPageState();
}

class _SharesPageState extends State<SharesPage> {
  @override
  void initState() {
    super.initState();
    context.read<ShareBloc>().add(const LoadShares());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Links'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<ShareBloc>().add(const LoadShares()),
          ),
        ],
      ),
      body: BlocConsumer<ShareBloc, ShareState>(
        listener: (context, state) {
          if (state is ShareCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share link created')),
            );
          }
          if (state is ShareUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share updated')),
            );
          }
          if (state is ShareOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is ShareError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ShareLoading || state is ShareOperationInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShareLoaded) {
            if (state.shares.isEmpty) {
              return _buildEmptyState();
            }
            return _buildShareList(context, state);
          }
          if (state is ShareError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ShareBloc>().add(const LoadShares()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.link_off, size: 64, color: OxiColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'No shared links',
            style: TextStyle(fontSize: 18, color: OxiColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create share links from the file browser',
            style: TextStyle(color: OxiColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildShareList(BuildContext context, ShareLoaded state) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            state.pagination.hasNext) {
          context.read<ShareBloc>().add(const LoadMoreShares());
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.shares.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          return _ShareItemTile(
            share: state.shares[index],
            onCopyLink: () => _copyLink(state.shares[index]),
            onDelete: () => _confirmDelete(context, state.shares[index]),
          );
        },
      ),
    );
  }

  void _copyLink(ShareItem share) {
    Clipboard.setData(ClipboardData(text: share.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  void _confirmDelete(BuildContext context, ShareItem share) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Share?'),
        content: Text(
          'This will disable the share link for "${share.itemId}".\n'
          'Anyone with the link will no longer have access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<ShareBloc>()
                  .add(DeleteShareRequested(share.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Share item tile
// =============================================================================

class _ShareItemTile extends StatelessWidget {
  final ShareItem share;
  final VoidCallback onCopyLink;
  final VoidCallback onDelete;

  const _ShareItemTile({
    required this.share,
    required this.onCopyLink,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = share.isExpired;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isExpired ? Colors.grey.shade300 : OxiColors.primaryLight,
        child: Icon(
          share.itemType == 'folder' ? Icons.folder : Icons.insert_drive_file,
          color: isExpired ? Colors.grey : OxiColors.primary,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              share.itemId,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (share.hasPassword)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.lock, size: 16, color: OxiColors.textSecondary),
            ),
          if (isExpired)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Chip(
                label: const Text('Expired'),
                labelStyle: const TextStyle(fontSize: 10),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.red.shade100,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            share.url,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: OxiColors.primary,
            ),
          ),
          Row(
            children: [
              Text(
                '${share.accessCount} views',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Text(
                _permissionsLabel(share.permissions),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: OxiColors.textSecondary,
                ),
              ),
              if (share.expiresAt != null && !isExpired) ...[
                const SizedBox(width: 8),
                Text(
                  'Expires ${_formatDate(share.expiresAt!)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: OxiColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy link',
            onPressed: onCopyLink,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete share',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _permissionsLabel(SharePermissions p) {
    final parts = <String>[];
    if (p.read) parts.add('R');
    if (p.write) parts.add('W');
    if (p.reshare) parts.add('S');
    return parts.join('/');
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
