import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:oxicloud_desktop/presentation/providers/file_list_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/file_list_item.dart';
import 'package:oxicloud_desktop/presentation/widgets/sync_status_indicator.dart';

/// Page for browsing files and folders
class FileBrowserPage extends ConsumerWidget {
  /// ID of the folder to browse
  final String folderId;
  
  /// Create a FileBrowserPage
  const FileBrowserPage({
    super.key,
    required this.folderId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileListAsync = ref.watch(fileListProvider(folderId));
    final folderPathAsync = ref.watch(folderPathProvider(folderId));
    
    return Scaffold(
      appBar: AppBar(
        title: folderPathAsync.when(
          data: (pathSegments) => Text(
            pathSegments.isEmpty ? 'Root' : pathSegments.last,
          ),
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Files'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(26),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: folderPathAsync.when(
                data: (pathSegments) => _buildBreadcrumbs(context, pathSegments),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: () {
              // Navigate to search page
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(fileListProvider(folderId).notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: () {
              _showMoreOptions(context);
            },
          ),
        ],
      ),
      body: fileListAsync.when(
        data: (items) => _buildItemList(context, ref, items),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load files',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(fileListProvider(folderId).notifier).refresh();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, ref),
      floatingActionButton: _buildFab(context, ref),
    );
  }
  
  /// Build breadcrumbs navigation
  Widget _buildBreadcrumbs(BuildContext context, List<String> pathSegments) {
    // If we only have the root folder, don't show breadcrumbs
    if (pathSegments.length <= 1) {
      return const SizedBox();
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < pathSegments.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i > 0) ...[
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                ],
                InkWell(
                  onTap: i < pathSegments.length - 1
                      ? () {
                          // Navigate to this segment
                          // In a real implementation, you would have
                          // to map the segment name back to a folder ID
                        }
                      : null,
                  child: Text(
                    pathSegments[i],
                    style: TextStyle(
                      color: i < pathSegments.length - 1
                          ? Theme.of(context).colorScheme.primary
                          : null,
                      fontWeight: i == pathSegments.length - 1
                          ? FontWeight.bold
                          : null,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  /// Build list of files and folders
  Widget _buildItemList(
    BuildContext context,
    WidgetRef ref,
    List<StorageItem> items,
  ) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text('This folder is empty'),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return FileListItem(
          item: item,
          onTap: () => _handleItemTap(context, ref, item),
          onLongPress: () => _showItemOptions(context, ref, item),
        );
      },
    );
  }
  
  /// Build bottom bar with sync status
  Widget _buildBottomBar(BuildContext context, WidgetRef ref) {
    return BottomAppBar(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const SyncStatusIndicator(),
          const Spacer(),
          Text(
            'OxiCloud',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
  
  /// Build floating action button
  Widget _buildFab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => _showAddOptions(context, ref),
    );
  }
  
  /// Handle item tap
  void _handleItemTap(BuildContext context, WidgetRef ref, StorageItem item) {
    if (item.isFolder) {
      // Navigate to folder
      context.push('/folder/${item.id}');
    } else {
      // Preview file
      _previewFile(context, ref, item);
    }
  }
  
  /// Show file preview
  void _previewFile(BuildContext context, WidgetRef ref, StorageItem item) {
    // Placeholder for file preview
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SizedBox(
          width: 400,
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text('File preview not implemented yet'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Download file
              Navigator.of(context).pop();
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
  
  /// Show options for a file or folder
  void _showItemOptions(
    BuildContext context,
    WidgetRef ref,
    StorageItem item,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.of(context).pop();
                // Download file
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.of(context).pop();
                // Share file
              },
            ),
            ListTile(
              leading: Icon(
                item.isFavorite ? Icons.star : Icons.star_border,
              ),
              title: Text(
                item.isFavorite ? 'Remove from favorites' : 'Add to favorites',
              ),
              onTap: () {
                Navigator.of(context).pop();
                ref.read(fileListProvider(folderId).notifier).markAsFavorite(
                      item,
                      !item.isFavorite,
                    );
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.of(context).pop();
                _showRenameDialog(context, ref, item);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(context, ref, item);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show dialog to rename an item
  void _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    StorageItem item,
  ) {
    final controller = TextEditingController(text: item.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename ${item.isFolder ? 'Folder' : 'File'}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != item.name) {
                ref.read(fileListProvider(folderId).notifier).renameItem(
                      item,
                      newName,
                    );
              }
              Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
  
  /// Show confirmation dialog to delete an item
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    StorageItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Trash'),
        content: Text(
          'Are you sure you want to move "${item.name}" to trash? You can restore it later from the trash.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(fileListProvider(folderId).notifier).deleteItem(item);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Move to Trash'),
          ),
        ],
      ),
    );
  }
  
  /// Show options to add a file or folder
  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Create Folder'),
              onTap: () {
                Navigator.of(context).pop();
                _showCreateFolderDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload File'),
              onTap: () {
                Navigator.of(context).pop();
                // Upload file
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                // Take photo
              },
            ),
          ],
        ),
      ),
    );
  }
  
  /// Show dialog to create a new folder
  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(fileListProvider(folderId).notifier).createFolder(name);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  /// Show more options menu
  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to favorites
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Recent'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to recent
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Trash'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/trash');
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Settings'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to sync settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                // Logout
              },
            ),
          ],
        ),
      ),
    );
  }
}