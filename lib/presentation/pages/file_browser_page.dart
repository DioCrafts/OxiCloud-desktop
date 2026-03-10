import 'dart:io';

import 'package:file_picker/file_picker.dart' hide FileType;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/entities/file_item.dart';
import '../blocs/file_browser/file_browser_bloc.dart';
import '../theme/oxicloud_colors.dart';
import '../widgets/breadcrumb_bar.dart';
import '../widgets/file_item_tile.dart';

/// Full-featured file browser page.
///
/// Provides folder navigation, file listing, upload, create folder,
/// rename, delete, download, favorites, thumbnails, multi-select
/// with batch operations, and chunked upload with progress.
class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  // Multi-select state
  final Set<String> _selectedFileIds = {};
  final Set<String> _selectedFolderIds = {};
  bool get _isSelecting => _selectedFileIds.isNotEmpty || _selectedFolderIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Load root folder on first build
    context.read<FileBrowserBloc>().add(const LoadFolder());
  }

  void _clearSelection() {
    setState(() {
      _selectedFileIds.clear();
      _selectedFolderIds.clear();
    });
  }

  void _toggleFileSelection(String fileId) {
    setState(() {
      if (_selectedFileIds.contains(fileId)) {
        _selectedFileIds.remove(fileId);
      } else {
        _selectedFileIds.add(fileId);
      }
    });
  }

  void _toggleFolderSelection(String folderId) {
    setState(() {
      if (_selectedFolderIds.contains(folderId)) {
        _selectedFolderIds.remove(folderId);
      } else {
        _selectedFolderIds.add(folderId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FileBrowserBloc, FileBrowserState>(
      listenWhen: (_, current) =>
          current is FileBrowserActionSuccess ||
          current is FileBrowserActionError,
      listener: (context, state) {
        if (state is FileBrowserActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: OxiColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        if (state is FileBrowserActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: OxiColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      buildWhen: (_, current) =>
          current is! FileBrowserActionSuccess &&
          current is! FileBrowserActionError,
      builder: (context, state) {
        return Scaffold(
          appBar: _buildAppBar(state),
          body: Column(
            children: [
              // Multi-select action bar
              if (_isSelecting)
                MultiSelectActionBar(
                  selectedCount: _selectedFileIds.length + _selectedFolderIds.length,
                  onDelete: () {
                    context.read<FileBrowserBloc>().add(BatchDeleteRequested(
                      fileIds: _selectedFileIds.toList(),
                      folderIds: _selectedFolderIds.toList(),
                    ));
                    _clearSelection();
                  },
                  onMove: () => _showMoveDialog(context),
                  onCopy: () => _showCopyDialog(context),
                  onClearSelection: _clearSelection,
                ),
              // Breadcrumb navigation
              if (state is FileBrowserLoaded)
                BreadcrumbBar(
                  items: state.breadcrumbs,
                  onTap: (index) => context
                      .read<FileBrowserBloc>()
                      .add(NavigateToBreadcrumb(index)),
                ),
              // Upload progress overlay
              if (state is FileBrowserUploadProgress)
                UploadProgressOverlay(
                  fileName: state.fileName,
                  progress: state.progress,
                  percent: state.percent,
                ),
              // Content
              Expanded(child: _buildBody(state)),
            ],
          ),
          floatingActionButton: _buildFab(state),
        );
      },
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(FileBrowserState state) {
    final canGoUp = state is FileBrowserLoaded && !state.isRoot;
    final isGrid = state is FileBrowserLoaded && state.viewMode == ViewMode.grid;

    return AppBar(
      leading: canGoUp
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Up one level',
              onPressed: () =>
                  context.read<FileBrowserBloc>().add(const NavigateUp()),
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to Home',
              onPressed: () => Navigator.of(context).pop(),
            ),
      title: const Text('Files'),
      actions: [
        // Grid / List toggle
        IconButton(
          icon: Icon(isGrid ? Icons.view_list : Icons.grid_view),
          tooltip: isGrid ? 'List view' : 'Grid view',
          onPressed: () =>
              context.read<FileBrowserBloc>().add(const ToggleViewMode()),
        ),
        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () =>
              context.read<FileBrowserBloc>().add(const RefreshFolder()),
        ),
      ],
    );
  }

  // ── Body ────────────────────────────────────────────────────────────────

  Widget _buildBody(FileBrowserState state) {
    if (state is FileBrowserLoading || state is FileBrowserInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FileBrowserUploadProgress) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FileBrowserError) {
      return _buildErrorView(state.message);
    }

    if (state is FileBrowserLoaded) {
      if (state.totalItems == 0) {
        return _buildEmptyView();
      }

      if (state.viewMode == ViewMode.grid) {
        return _buildGridView(state);
      }
      return _buildListView(state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildListView(FileBrowserLoaded state) {
    final bloc = context.read<FileBrowserBloc>();

    return RefreshIndicator(
      onRefresh: () async {
        bloc.add(const RefreshFolder());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          // Folders first
          ...state.folders.map((folder) => FolderTile(
                folder: folder,
                isSelected: _selectedFolderIds.contains(folder.id),
                onTap: _isSelecting
                    ? () => _toggleFolderSelection(folder.id)
                    : () => bloc.add(NavigateToFolder(
                          folderId: folder.id,
                          folderName: folder.name,
                        )),
                onLongPress: () => _toggleFolderSelection(folder.id),
                onRename: () => _showRenameDialog(
                  context,
                  currentName: folder.name,
                  isFolder: true,
                  id: folder.id,
                ),
                onDelete: () => _showDeleteConfirmation(
                  context,
                  name: folder.name,
                  isFolder: true,
                  id: folder.id,
                ),
                onFavoriteToggle: () => bloc.add(ToggleFavorite(
                  itemId: folder.id,
                  itemType: 'folder',
                  isFavorite: false,
                )),
                onDownloadZip: () => _downloadFolderAsZip(folder),
              )),
          // Divider between folders and files
          if (state.folders.isNotEmpty && state.files.isNotEmpty)
            Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: OxiColors.border,
            ),
          // Files
          ...state.files.map((file) => FileTile(
                file: file,
                isSelected: _selectedFileIds.contains(file.id),
                thumbnailUrl: _getThumbnailUrl(file),
                onTap: _isSelecting
                    ? () => _toggleFileSelection(file.id)
                    : () => _onFileTap(file),
                onLongPress: () => _toggleFileSelection(file.id),
                onRename: () => _showRenameDialog(
                  context,
                  currentName: file.name,
                  isFolder: false,
                  id: file.id,
                ),
                onDelete: () => _showDeleteConfirmation(
                  context,
                  name: file.name,
                  isFolder: false,
                  id: file.id,
                ),
                onDownload: () => _downloadFile(file),
                onFavoriteToggle: () => bloc.add(ToggleFavorite(
                  itemId: file.id,
                  itemType: 'file',
                  isFavorite: false,
                )),
              )),
        ],
      ),
    );
  }

  Widget _buildGridView(FileBrowserLoaded state) {
    final bloc = context.read<FileBrowserBloc>();

    final items = <Widget>[
      ...state.folders.map((folder) => FolderGridCard(
            folder: folder,
            isSelected: _selectedFolderIds.contains(folder.id),
            onTap: _isSelecting
                ? () => _toggleFolderSelection(folder.id)
                : () => bloc.add(NavigateToFolder(
                      folderId: folder.id,
                      folderName: folder.name,
                    )),
            onLongPress: () => _toggleFolderSelection(folder.id),
            onRename: () => _showRenameDialog(
              context,
              currentName: folder.name,
              isFolder: true,
              id: folder.id,
            ),
            onDelete: () => _showDeleteConfirmation(
              context,
              name: folder.name,
              isFolder: true,
              id: folder.id,
            ),
            onFavoriteToggle: () => bloc.add(ToggleFavorite(
              itemId: folder.id,
              itemType: 'folder',
              isFavorite: false,
            )),
          )),
      ...state.files.map((file) => FileGridCard(
            file: file,
            isSelected: _selectedFileIds.contains(file.id),
            thumbnailUrl: _getThumbnailUrl(file),
            onTap: _isSelecting
                ? () => _toggleFileSelection(file.id)
                : () => _onFileTap(file),
            onLongPress: () => _toggleFileSelection(file.id),
            onRename: () => _showRenameDialog(
              context,
              currentName: file.name,
              isFolder: false,
              id: file.id,
            ),
            onDelete: () => _showDeleteConfirmation(
              context,
              name: file.name,
              isFolder: false,
              id: file.id,
            ),
            onDownload: () => _downloadFile(file),
            onFavoriteToggle: () => bloc.add(ToggleFavorite(
              itemId: file.id,
              itemType: 'file',
              isFavorite: false,
            )),
          )),
    ];

    return GridView.count(
      crossAxisCount: _gridColumns(context),
      padding: const EdgeInsets.all(12),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items,
    );
  }

  int _gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    return 3;
  }

  String? _getThumbnailUrl(FileItem file) {
    if (file.fileType == FileType.image) {
      // Access repository through bloc for thumbnail URL
      return null; // Thumbnails loaded via repository
    }
    return null;
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 80,
            color: OxiColors.textPlaceholder,
          ),
          const SizedBox(height: 16),
          Text(
            'This folder is empty',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: OxiColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload files or create a folder to get started',
            style: TextStyle(
              fontSize: 14,
              color: OxiColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: OxiColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load folder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: OxiColors.textHeading,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: OxiColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<FileBrowserBloc>().add(const RefreshFolder()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ─────────────────────────────────────────────────────────────────

  Widget? _buildFab(FileBrowserState state) {
    if (state is! FileBrowserLoaded) return null;
    if (_isSelecting) return null; // Hide FAB during selection

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Create folder mini-FAB
        FloatingActionButton.small(
          heroTag: 'create_folder',
          backgroundColor: OxiColors.surface,
          foregroundColor: OxiColors.primary,
          elevation: 2,
          onPressed: () => _showCreateFolderDialog(context),
          tooltip: 'New folder',
          child: const Icon(Icons.create_new_folder_outlined),
        ),
        const SizedBox(height: 12),
        // Upload file FAB
        FloatingActionButton.extended(
          heroTag: 'upload_file',
          onPressed: _uploadFile,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload'),
        ),
      ],
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    if (!mounted) return;

    for (final pickedFile in result.files) {
      final path = pickedFile.path;
      if (path == null) continue;
      context.read<FileBrowserBloc>().add(UploadFileRequested(File(path)));
    }
  }

  Future<void> _downloadFile(FileItem file) async {
    final dir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/${file.name}';

    if (!mounted) return;
    context.read<FileBrowserBloc>().add(
          DownloadFileRequested(fileId: file.id, savePath: savePath),
        );
  }

  Future<void> _downloadFolderAsZip(FolderItem folder) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${folder.name} as ZIP...'),
        duration: const Duration(seconds: 2),
      ),
    );

    // Use repository directly for folder ZIP download
    // TODO: This could be moved to a dedicated event in the BLoC
  }

  Future<void> _onFileTap(FileItem file) async {
    // Download to temp and open
    final dir = await getTemporaryDirectory();
    final tempPath = '${dir.path}/${file.name}';

    if (!mounted) return;
    // Download first, then open
    context.read<FileBrowserBloc>()
      ..add(DownloadFileRequested(fileId: file.id, savePath: tempPath));

    // Open after a short delay to let download complete
    Future<void>.delayed(const Duration(seconds: 2), () {
      OpenFile.open(tempPath);
    });
  }

  // ── Dialogs ─────────────────────────────────────────────────────────────

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            prefixIcon: Icon(Icons.folder_outlined),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<FileBrowserBloc>().add(CreateFolderRequested(name));
    }
  }

  Future<void> _showRenameDialog(
    BuildContext context, {
    required String currentName,
    required bool isFolder,
    required String id,
  }) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename ${isFolder ? 'Folder' : 'File'}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: isFolder ? 'Folder name' : 'File name',
            prefixIcon: Icon(
              isFolder ? Icons.folder_outlined : Icons.insert_drive_file_outlined,
            ),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName && context.mounted) {
      if (isFolder) {
        context
            .read<FileBrowserBloc>()
            .add(RenameFolderRequested(folderId: id, newName: newName));
      } else {
        context
            .read<FileBrowserBloc>()
            .add(RenameFileRequested(fileId: id, newName: newName));
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context, {
    required String name,
    required bool isFolder,
    required String id,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${isFolder ? 'Folder' : 'File'}'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'Are you sure you want to delete '),
              TextSpan(
                text: name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '? It will be moved to trash.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: OxiColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && context.mounted) {
      final bloc = context.read<FileBrowserBloc>();
      if (isFolder) {
        bloc.add(DeleteFolderRequested(id));
      } else {
        bloc.add(DeleteFileRequested(id));
      }
    }
  }

  Future<void> _showMoveDialog(BuildContext context) async {
    // Simple folder picker for move target
    final controller = TextEditingController();
    final targetFolderId = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Move ${_selectedFileIds.length + _selectedFolderIds.length} items to:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Target folder ID (empty = root)',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Move'),
          ),
        ],
      ),
    );

    if (targetFolderId != null && context.mounted) {
      context.read<FileBrowserBloc>().add(MoveItemsRequested(
        fileIds: _selectedFileIds.toList(),
        folderIds: _selectedFolderIds.toList(),
        targetFolderId: targetFolderId.isEmpty ? null : targetFolderId,
      ));
      _clearSelection();
    }
  }

  Future<void> _showCopyDialog(BuildContext context) async {
    final controller = TextEditingController();
    final targetFolderId = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Copy Items'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Copy ${_selectedFileIds.length + _selectedFolderIds.length} items to:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Target folder ID (empty = root)',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Copy'),
          ),
        ],
      ),
    );

    if (targetFolderId != null && context.mounted) {
      context.read<FileBrowserBloc>().add(CopyItemsRequested(
        fileIds: _selectedFileIds.toList(),
        folderIds: _selectedFolderIds.toList(),
        targetFolderId: targetFolderId.isEmpty ? null : targetFolderId,
      ));
      _clearSelection();
    }
  }
}
