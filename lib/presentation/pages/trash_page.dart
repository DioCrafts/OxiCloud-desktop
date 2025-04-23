import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:oxicloud_desktop/domain/entities/trashed_item.dart';
import 'package:oxicloud_desktop/domain/services/mime_type_service.dart';
import 'package:oxicloud_desktop/presentation/providers/trash_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/sync_status_indicator.dart';

/// Page for trash management
class TrashPage extends ConsumerWidget {
  /// Create a TrashPage
  const TrashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trashedItemsAsync = ref.watch(trashedItemsProvider);
    final expirationDaysAsync = ref.watch(trashExpirationDaysProvider);
    final trashOperationState = ref.watch(trashNotifierProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
        actions: [
          trashedItemsAsync.when(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.delete_forever),
                    tooltip: 'Empty trash',
                    onPressed: trashOperationState.isLoading
                        ? null
                        : () => _showEmptyTrashDialog(context, ref),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: trashOperationState.isLoading
                ? null
                : () => ref.refresh(trashedItemsProvider),
          ),
        ],
      ),
      body: _buildBody(
        context, 
        ref,
        trashedItemsAsync,
        expirationDaysAsync,
        trashOperationState,
      ),
      bottomNavigationBar: BottomAppBar(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SyncStatusIndicator(
              showSyncButton: false,
            ),
            const Spacer(),
            expirationDaysAsync.when(
              data: (days) => Text(
                'Items will be deleted after $days days',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<TrashedItem>> trashedItemsAsync,
    AsyncValue<int> expirationDaysAsync,
    AsyncValue<void> trashOperationState,
  ) {
    // Show loading indicator if operations are in progress
    if (trashOperationState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // Show error for operations
    if (trashOperationState.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              trashOperationState.error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(trashedItemsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Show trashed items
    return trashedItemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('Trash is empty'),
              ],
            ),
          );
        }
        
        // Sort items by trashed date, newest first
        final sortedItems = List<TrashedItem>.from(items)
          ..sort((a, b) => b.trashedAt.compareTo(a.trashedAt));
        
        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(trashedItemsProvider);
          },
          child: ListView.builder(
            itemCount: sortedItems.length,
            itemBuilder: (context, index) {
              final item = sortedItems[index];
              return _buildTrashedItemTile(context, ref, item);
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade700,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(trashedItemsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrashedItemTile(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item,
  ) {
    final daysRemaining = item.daysRemaining;
    final expiresText = daysRemaining > 0
        ? 'Expires in $daysRemaining days'
        : 'Expires today';
    
    IconData iconData;
    if (item.isFolder) {
      iconData = Icons.folder;
    } else if (item.mimeType != null) {
      iconData = MimeTypeService.getFileIcon(item.mimeType!);
    } else {
      iconData = Icons.insert_drive_file;
    }
    
    return ListTile(
      leading: Icon(
        iconData,
        color: item.isFolder ? Colors.amber : null,
      ),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deleted on ${DateFormat.yMMMd().format(item.trashedAt)}',
          ),
          Text(
            expiresText,
            style: TextStyle(
              color: daysRemaining < 3 ? Colors.red : null,
              fontWeight: daysRemaining < 3 ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore',
            onPressed: () => _restoreItem(context, ref, item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete permanently',
            onPressed: () => _showDeletePermanentlyDialog(context, ref, item),
          ),
        ],
      ),
      onTap: () => _showItemDetails(context, ref, item),
    );
  }
  
  void _showItemDetails(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'Type',
              item.isFolder ? 'Folder' : 'File',
            ),
            _buildDetailRow(
              context,
              'Original path',
              item.originalPath,
            ),
            if (!item.isFolder) ...[
              _buildDetailRow(
                context,
                'Size',
                _formatSize(item.size),
              ),
              if (item.mimeType != null)
                _buildDetailRow(
                  context,
                  'Type',
                  item.mimeType!,
                ),
            ],
            _buildDetailRow(
              context,
              'Deleted on',
              DateFormat.yMMMd().add_Hm().format(item.trashedAt),
            ),
            _buildDetailRow(
              context,
              'Expires on',
              DateFormat.yMMMd().add_Hm().format(item.expiresAt),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _restoreItem(context, ref, item);
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Restore'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _extendExpiration(context, ref, item);
                  },
                  icon: const Icon(Icons.access_time),
                  label: const Text('Extend Time'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  void _restoreItem(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item,
  ) {
    _showRestoreDialog(
      context, 
      ref, 
      item,
      onRestore: () {
        ref.read(trashNotifierProvider.notifier).restoreItem(item.id);
        ref.refresh(trashedItemsProvider);
      },
    );
  }
  
  void _showRestoreDialog(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item, {
    required VoidCallback onRestore,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Item'),
        content: Text(
          'Do you want to restore "${item.name}" to its original location?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          // TODO: Add option to restore to different location
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRestore();
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
  
  void _showDeletePermanentlyDialog(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently'),
        content: Text(
          'Are you sure you want to permanently delete "${item.name}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(trashNotifierProvider.notifier).deleteItemPermanently(item.id);
              ref.refresh(trashedItemsProvider);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }
  
  void _showEmptyTrashDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Empty Trash'),
        content: const Text(
          'Are you sure you want to permanently delete all items in the trash? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(trashNotifierProvider.notifier).emptyTrash();
              ref.refresh(trashedItemsProvider);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Empty Trash'),
          ),
        ],
      ),
    );
  }
  
  void _extendExpiration(
    BuildContext context,
    WidgetRef ref,
    TrashedItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Expiration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Extend expiration time for "${item.name}"',
            ),
            const SizedBox(height: 8),
            Text(
              'Current expiration: ${DateFormat.yMMMd().format(item.expiresAt)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Select additional days:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(trashNotifierProvider.notifier).extendExpiration(item.id, 7);
              ref.refresh(trashedItemsProvider);
            },
            child: const Text('7 Days'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(trashNotifierProvider.notifier).extendExpiration(item.id, 30);
              ref.refresh(trashedItemsProvider);
            },
            child: const Text('30 Days'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(trashNotifierProvider.notifier).extendExpiration(item.id, 90);
              ref.refresh(trashedItemsProvider);
            },
            child: const Text('90 Days'),
          ),
        ],
      ),
    );
  }
  
  String _formatSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    num size = bytes;
    
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return i == 0
        ? '$size ${suffixes[i]}'
        : '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}