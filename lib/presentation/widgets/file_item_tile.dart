import 'package:flutter/material.dart';
import 'package:oxicloud_desktop/domain/entities/file_item.dart';

class FileItemTile extends StatelessWidget {
  final FileItem file;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const FileItemTile({
    super.key,
    required this.file,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        file.isDirectory ? Icons.folder : _getFileIcon(file.mimeType),
        color: file.isDirectory ? Colors.amber : Colors.blue,
      ),
      title: Text(file.name),
      subtitle: Text(
        file.isDirectory
            ? 'Carpeta'
            : '${_formatFileSize(file.size)} • ${_formatDate(file.lastModified)}',
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;

    if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else if (mimeType.startsWith('text/')) {
      return Icons.description;
    } else if (mimeType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (mimeType.contains('zip') || mimeType.contains('rar')) {
      return Icons.archive;
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 