import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../providers.dart';
import '../../../../domain/entities/file_entity.dart';
import '../../../../domain/entities/folder_entity.dart';
import '../../../core/theme/responsive.dart';
import '../../widgets/breadcrumb_bar.dart';
import '../../widgets/context_menu.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/file_icon.dart';
import '../../shell/adaptive_shell.dart';
import '../../shell/desktop/desktop_toolbar.dart';
import '../../shell/desktop/drag_drop_overlay.dart';
import '../../shell/mobile/mobile_upload_sheet.dart';

// --- State ---

class FileBrowserState {
  final List<FolderEntity> folders;
  final List<FileEntity> files;
  final bool loading;
  final String? error;
  final String? currentFolderId;
  final List<({String id, String name})> breadcrumbs;

  const FileBrowserState({
    this.folders = const [],
    this.files = const [],
    this.loading = false,
    this.error,
    this.currentFolderId,
    this.breadcrumbs = const [],
  });

  FileBrowserState copyWith({
    List<FolderEntity>? folders,
    List<FileEntity>? files,
    bool? loading,
    String? error,
    String? currentFolderId,
    List<({String id, String name})>? breadcrumbs,
  }) {
    return FileBrowserState(
      folders: folders ?? this.folders,
      files: files ?? this.files,
      loading: loading ?? this.loading,
      error: error,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
    );
  }
}

// --- Notifier ---

class FileBrowserNotifier extends Notifier<FileBrowserState> {
  @override
  FileBrowserState build() => const FileBrowserState();

  Future<void> loadFolder(String? folderId) async {
    state = state.copyWith(loading: true, error: null, currentFolderId: folderId);

    try {
      if (folderId == null) {
        final folders = await ref.read(folderRepositoryProvider).listRootFolders();
        final files = await ref.read(fileRepositoryProvider).listFiles();
        state = state.copyWith(
          folders: folders,
          files: files,
          loading: false,
          breadcrumbs: [],
        );
      } else {
        final contents =
            await ref.read(folderRepositoryProvider).listFolderContents(folderId);
        state = state.copyWith(
          folders: contents.folders,
          files: contents.files,
          loading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> createFolder(String name) async {
    try {
      await ref
          .read(folderRepositoryProvider)
          .createFolder(name: name, parentId: state.currentFolderId);
      await loadFolder(state.currentFolderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteFile(String id) async {
    await ref.read(fileRepositoryProvider).deleteFile(id);
    await loadFolder(state.currentFolderId);
  }

  Future<void> deleteFolder(String id) async {
    await ref.read(folderRepositoryProvider).deleteFolder(id);
    await loadFolder(state.currentFolderId);
  }

  /// Upload a file from its local path.
  Future<void> uploadFileFromPath(String filePath) async {
    final file = File(filePath);
    final name = file.uri.pathSegments.last;
    final size = await file.length();
    final mimeType = lookupMimeType(filePath) ?? 'application/octet-stream';

    await ref.read(fileRepositoryProvider).uploadFile(
          name: name,
          folderId: state.currentFolderId,
          fileStream: file.openRead(),
          fileSize: size,
          mimeType: mimeType,
        );
    await loadFolder(state.currentFolderId);
  }

  /// Upload multiple files by path. Returns count of successful uploads.
  Future<int> uploadFilesFromPaths(List<String> paths) async {
    int success = 0;
    for (final path in paths) {
      try {
        await uploadFileFromPath(path);
        success++;
      } catch (e) {
        state = state.copyWith(error: 'Failed to upload ${File(path).uri.pathSegments.last}: $e');
      }
    }
    return success;
  }

  /// Download a file to the local downloads directory and return the path.
  Future<String> downloadFileToLocal(String fileId, String fileName) async {
    final dir = await getDownloadsDirectory() ?? await getTemporaryDirectory();
    final savePath = '${dir.path}/$fileName';
    await ref.read(fileRepositoryProvider).downloadFileToPath(fileId, savePath);
    return savePath;
  }

  /// Toggle favorite status for a file.
  Future<void> toggleFavorite(FileEntity file) async {
    final favRepo = ref.read(favoritesRepositoryProvider);
    if (file.isFavorite) {
      await favRepo.removeFavorite('file', file.id);
    } else {
      await favRepo.addFavorite('file', file.id);
    }
    await loadFolder(state.currentFolderId);
  }
}

final fileBrowserProvider =
    NotifierProvider<FileBrowserNotifier, FileBrowserState>(FileBrowserNotifier.new);

// --- Page ---

class FileBrowserPage extends ConsumerStatefulWidget {
  final String? folderId;

  const FileBrowserPage({super.key, this.folderId});

  @override
  ConsumerState<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends ConsumerState<FileBrowserPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(fileBrowserProvider.notifier).loadFolder(widget.folderId));
  }

  @override
  void didUpdateWidget(covariant FileBrowserPage old) {
    super.didUpdateWidget(old);
    if (old.folderId != widget.folderId) {
      ref.read(fileBrowserProvider.notifier).loadFolder(widget.folderId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileBrowserProvider);
    final isDesktop = Responsive.isDesktop(context);
    final totalItems = state.folders.length + state.files.length;

    final breadcrumbs = <BreadcrumbItem>[
      BreadcrumbItem(
        label: 'Home',
        onTap: () => context.go('/files'),
      ),
      ...state.breadcrumbs.map(
        (b) => BreadcrumbItem(
          label: b.name,
          onTap: () => context.go('/files/${b.id}'),
        ),
      ),
    ];

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else {
      body = _buildContent(state, isDesktop);
    }

    // Desktop: wrap with toolbar + drag-drop
    if (isDesktop) {
      body = Column(
        children: [
          DesktopToolbar(
            breadcrumbs: breadcrumbs,
            onRefresh: () => ref
                .read(fileBrowserProvider.notifier)
                .loadFolder(widget.folderId),
            onNewFolder: () => _createFolder(context),
            onUpload: _uploadFiles,
          ),
          Expanded(
            child: DragDropOverlay(
              onFilesDropped: _handleDroppedFiles,
              child: body,
            ),
          ),
        ],
      );
    }

    return AdaptiveShell(
      currentPath: widget.folderId != null
          ? '/files/${widget.folderId}'
          : '/files',
      title: 'Files',
      itemCount: totalItems,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref
              .read(fileBrowserProvider.notifier)
              .loadFolder(widget.folderId),
        ),
      ],
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => MobileUploadSheet.show(
                context: context,
                onUploadFile: _uploadFiles,
                onTakePhoto: () {},
                onCreateFolder: () => _createFolder(context),
              ),
              child: const Icon(Icons.add),
            ),
      child: body,
    );
  }

  Widget _buildContent(FileBrowserState state, bool isDesktop) {
    if (state.folders.isEmpty && state.files.isEmpty) {
      return EmptyState(
        icon: Icons.folder_open,
        title: 'This folder is empty',
        subtitle: isDesktop
            ? 'Drag files here or use the toolbar to upload'
            : 'Tap + to add files or folders',
      );
    }

    final folderWidgets = state.folders.map((f) => _FolderTile(
          folder: f,
          onTap: () => context.go('/files/${f.id}'),
          onContextMenu: (pos) => _showFolderContextMenu(context, f, pos),
        ));
    final fileWidgets = state.files.map((f) => _FileTile(
          file: f,
          onContextMenu: (pos) => _showFileContextMenu(context, f, pos),
        ));
    final items = [...folderWidgets, ...fileWidgets];

    if (isDesktop) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length,
        itemBuilder: (_, i) => items[i],
      );
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => items[i],
    );
  }

  Future<void> _createFolder(BuildContext context) async {
    final name = await AppDialogs.showTextInput(
      context: context,
      title: 'New Folder',
      hint: 'Folder name',
      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
    );
    if (name != null && name.isNotEmpty) {
      ref.read(fileBrowserProvider.notifier).createFolder(name);
    }
  }

  void _uploadFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return;

      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      if (paths.isEmpty) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uploading ${paths.length} file(s)…')),
        );
      }

      final count =
          await ref.read(fileBrowserProvider.notifier).uploadFilesFromPaths(paths);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$count file(s) uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }

  void _handleDroppedFiles(List<String> paths) async {
    if (paths.isEmpty) return;

    // Filter out directories — only upload files
    final filePaths = <String>[];
    for (final p in paths) {
      if (FileSystemEntity.isFileSync(p)) {
        filePaths.add(p);
      }
    }
    if (filePaths.isEmpty) return;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploading ${filePaths.length} dropped file(s)…')),
      );
    }

    final count =
        await ref.read(fileBrowserProvider.notifier).uploadFilesFromPaths(filePaths);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count file(s) uploaded successfully')),
      );
    }
  }

  void _showFolderContextMenu(
      BuildContext context, FolderEntity folder, Offset pos) {
    AppContextMenu.show(
      context: context,
      position: pos,
      items: [
        ContextMenuItem(
          icon: Icons.open_in_new,
          label: 'Open',
          onTap: () => context.go('/files/${folder.id}'),
        ),
        ContextMenuItem(
          icon: Icons.edit,
          label: 'Rename',
          onTap: () async {
            final name = await AppDialogs.showTextInput(
              context: context,
              title: 'Rename Folder',
              initialValue: folder.name,
            );
            if (name != null && name.isNotEmpty) {
              await ref
                  .read(folderRepositoryProvider)
                  .renameFolder(folder.id, name);
              ref
                  .read(fileBrowserProvider.notifier)
                  .loadFolder(widget.folderId);
            }
          },
        ),
        ContextMenuItem(
          icon: Icons.delete,
          label: 'Delete',
          isDanger: true,
          onTap: () async {
            final confirm = await AppDialogs.showConfirm(
              context: context,
              title: 'Delete "${folder.name}"?',
              message: 'This will delete the folder and all its contents.',
              isDanger: true,
            );
            if (confirm) {
              ref.read(fileBrowserProvider.notifier).deleteFolder(folder.id);
            }
          },
        ),
      ],
    );
  }

  void _showFileContextMenu(
      BuildContext context, FileEntity file, Offset pos) {
    AppContextMenu.show(
      context: context,
      position: pos,
      items: [
        ContextMenuItem(
          icon: Icons.download,
          label: 'Download',
          onTap: () async {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading "${file.name}"…')),
              );
              final path = await ref
                  .read(fileBrowserProvider.notifier)
                  .downloadFileToLocal(file.id, file.name);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Saved to $path'),
                  action: SnackBarAction(
                    label: 'Open',
                    onPressed: () => OpenFilex.open(path),
                  ),
                ),
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download failed: $e')),
                );
              }
            }
          },
        ),
        ContextMenuItem(
          icon: Icons.edit,
          label: 'Rename',
          onTap: () async {
            final name = await AppDialogs.showTextInput(
              context: context,
              title: 'Rename File',
              initialValue: file.name,
            );
            if (name != null && name.isNotEmpty) {
              await ref.read(fileRepositoryProvider).renameFile(file.id, name);
              ref
                  .read(fileBrowserProvider.notifier)
                  .loadFolder(widget.folderId);
            }
          },
        ),
        ContextMenuItem(
          icon: file.isFavorite ? Icons.star : Icons.star_outline,
          label: file.isFavorite ? 'Remove favorite' : 'Add to favorites',
          onTap: () async {
            try {
              await ref
                  .read(fileBrowserProvider.notifier)
                  .toggleFavorite(file);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(file.isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update favorite: $e')),
                );
              }
            }
          },
        ),
        ContextMenuItem(
          icon: Icons.delete,
          label: 'Delete',
          isDanger: true,
          onTap: () async {
            final confirm = await AppDialogs.showConfirm(
              context: context,
              title: 'Delete "${file.name}"?',
              isDanger: true,
            );
            if (confirm) {
              ref.read(fileBrowserProvider.notifier).deleteFile(file.id);
            }
          },
        ),
      ],
    );
  }
}

class _FolderTile extends StatelessWidget {
  final FolderEntity folder;
  final VoidCallback onTap;
  final void Function(Offset) onContextMenu;

  const _FolderTile({
    required this.folder,
    required this.onTap,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (d) => onContextMenu(d.globalPosition),
      onLongPressStart: (d) => onContextMenu(d.globalPosition),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder, size: 48, color: Colors.amber.shade700),
                const SizedBox(height: 8),
                Text(folder.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final FileEntity file;
  final void Function(Offset) onContextMenu;

  const _FileTile({required this.file, required this.onContextMenu});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: (d) => onContextMenu(d.globalPosition),
      onLongPressStart: (d) => onContextMenu(d.globalPosition),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FileIcon(mimeType: file.mimeType, extension: file.extension, size: 48),
              const SizedBox(height: 8),
              Text(file.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center),
              Text(file.sizeFormatted,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
