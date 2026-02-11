import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/trash_item.dart';
import '../blocs/trash/trash_bloc.dart';
import '../theme/oxicloud_colors.dart';

class TrashPage extends StatefulWidget {
  const TrashPage({super.key});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  @override
  void initState() {
    super.initState();
    context.read<TrashBloc>().add(const LoadTrash());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Empty Trash',
            onPressed: () => _confirmEmptyTrash(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<TrashBloc>().add(const LoadTrash()),
          ),
        ],
      ),
      body: BlocConsumer<TrashBloc, TrashState>(
        listener: (context, state) {
          if (state is TrashOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is TrashError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TrashLoading || state is TrashOperationInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is TrashLoaded) {
            if (state.items.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTrashList(context, state.items);
          }
          if (state is TrashError) {
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
                        context.read<TrashBloc>().add(const LoadTrash()),
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
          Icon(Icons.delete_outline, size: 64, color: OxiColors.textSecondary),
          const SizedBox(height: 16),
          Text(
            'Trash is empty',
            style: TextStyle(
              fontSize: 18,
              color: OxiColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashList(BuildContext context, List<TrashItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        return _TrashItemTile(
          item: item,
          onRestore: () =>
              context.read<TrashBloc>().add(RestoreTrashItem(item.id)),
          onDelete: () => _confirmDelete(context, item),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, TrashItem item) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"?\n'
          'This action cannot be undone.',
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
                  .read<TrashBloc>()
                  .add(DeleteTrashItemPermanently(item.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyTrash(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Empty Trash?'),
        content: const Text(
          'All items in the trash will be permanently deleted.\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TrashBloc>().add(const EmptyTrashRequested());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Trash item tile
// =============================================================================

class _TrashItemTile extends StatelessWidget {
  final TrashItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemTile({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        item.isFolder ? Icons.folder : _fileIcon(item.name),
        color: item.isFolder ? OxiColors.primary : OxiColors.textSecondary,
        size: 36,
      ),
      title: Text(
        item.name,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.originalPath,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          Text(
            'Deleted ${_formatTimeAgo(item.trashedAt)} '
            '· ${item.daysUntilDeletion}d until auto-delete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: item.daysUntilDeletion <= 3
                  ? Colors.red
                  : OxiColors.textSecondary,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore',
            onPressed: onRestore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete permanently',
            color: Colors.red,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  IconData _fileIcon(String name) {
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mkv':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
      case 'flac':
        return Icons.audio_file;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'md':
        return Icons.description;
      case 'zip':
      case 'tar':
      case 'gz':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
