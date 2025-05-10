import 'dart:io';
import 'package:file_picker/file_picker.dart' as picker;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/file_item.dart';
import 'package:oxicloud_desktop/presentation/providers/file_explorer_provider.dart';
import 'package:path/path.dart' as path;
import 'package:oxicloud_desktop/presentation/widgets/file_item_tile.dart';
import 'package:oxicloud_desktop/presentation/widgets/loading_indicator.dart';
import 'package:oxicloud_desktop/presentation/widgets/error_view.dart';

class FileExplorerView extends ConsumerWidget {
  const FileExplorerView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filesAsync = ref.watch(fileExplorerProvider);
    final currentPath = ref.watch(currentPathProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentPath),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(fileExplorerProvider.notifier).loadFiles(),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => _showCreateFolderDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _pickAndUploadFiles(context, ref),
          ),
        ],
      ),
      body: filesAsync.when(
        data: (files) => _buildFileList(context, ref, files),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorView(
          error: error.toString(),
          onRetry: () => ref.read(fileExplorerProvider.notifier).loadFiles(),
        ),
      ),
    );
  }

  Widget _buildFileList(BuildContext context, WidgetRef ref, List<FileItem> files) {
    if (files.isEmpty) {
      return const Center(
        child: Text('No hay archivos en esta ubicación'),
      );
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return DragTarget<FileItem>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            if (file.isDirectory) {
              final destinationPath = path.join(
                ref.read(currentPathProvider),
                file.name,
              );
              ref.read(fileExplorerProvider.notifier).moveFile(details.data, destinationPath);
            }
          },
          builder: (context, candidateFiles, rejectedFiles) {
            return FileItemTile(
              file: file,
              onTap: () {
                if (file.isDirectory) {
                  ref.read(fileExplorerProvider.notifier).navigateTo(file.path);
                } else {
                  // TODO: Implementar vista previa de archivo
                }
              },
              onLongPress: () => _showFileOptions(context, ref, file),
            );
          },
        );
      },
    );
  }

  void _showFileOptions(BuildContext context, WidgetRef ref, FileItem file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Renombrar'),
            onTap: () {
              Navigator.pop(context);
              _showRenameDialog(context, ref, file);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Eliminar'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(context, ref, file);
            },
          ),
          if (!file.isDirectory) ...[
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Descargar'),
              onTap: () {
                Navigator.pop(context);
                _downloadFile(context, ref, file);
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickAndUploadFiles(BuildContext context, WidgetRef ref) async {
    final result = await picker.FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: picker.FileType.any,
    );
    
    if (result != null) {
      final files = result.files.map((file) => File(file.path!)).toList();
      await ref.read(fileExplorerProvider.notifier).uploadFiles(files);
    }
  }

  Future<void> _downloadFile(BuildContext context, WidgetRef ref, FileItem file) async {
    final directory = await picker.FilePicker.platform.getDirectoryPath();
    if (directory != null) {
      await ref.read(fileExplorerProvider.notifier).downloadFile(
        file,
        path.join(directory, file.name),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo descargado correctamente')),
        );
      }
    }
  }

  void _showCreateFolderDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva carpeta'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nombre de la carpeta',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(fileExplorerProvider.notifier).createFolder(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, FileItem file) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(fileExplorerProvider.notifier).renameFile(file, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Renombrar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar'),
        content: Text('¿Estás seguro de que quieres eliminar ${file.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(fileExplorerProvider.notifier).deleteFile(file);
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  String getFileIcon(String? mimeType) {
    if (mimeType == null) return 'assets/icons/file.png';

    if (mimeType.startsWith('image/')) {
      return 'assets/icons/image.png';
    } else if (mimeType.startsWith('video/')) {
      return 'assets/icons/video.png';
    } else if (mimeType.startsWith('audio/')) {
      return 'assets/icons/audio.png';
    } else if (mimeType.startsWith('text/')) {
      return 'assets/icons/document.png';
    } else if (mimeType.contains('pdf')) {
      return 'assets/icons/pdf.png';
    } else if (mimeType.contains('zip') || mimeType.contains('rar')) {
      return 'assets/icons/archive.png';
    } else {
      return 'assets/icons/file.png';
    }
  }
} 