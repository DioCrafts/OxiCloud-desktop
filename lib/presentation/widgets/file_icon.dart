import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class FileIcon extends StatelessWidget {
  final String? mimeType;
  final String? extension;
  final double size;

  const FileIcon({super.key, this.mimeType, this.extension, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve();
    return Icon(icon, size: size, color: color);
  }

  (IconData, Color) _resolve() {
    final mime = mimeType ?? '';

    if (mime.startsWith('image/')) return (Icons.image, AppColors.fileImage);
    if (mime.startsWith('video/'))
      return (Icons.video_file, AppColors.fileVideo);
    if (mime.startsWith('audio/'))
      return (Icons.audio_file, AppColors.fileAudio);
    if (mime.contains('pdf'))
      return (Icons.picture_as_pdf, Colors.red.shade700);
    if (mime.contains('zip') || mime.contains('tar') || mime.contains('rar')) {
      return (Icons.folder_zip, AppColors.fileArchive);
    }
    if (mime.contains('spreadsheet') || mime.contains('excel')) {
      return (Icons.table_chart, Colors.green.shade700);
    }
    if (mime.contains('presentation') || mime.contains('powerpoint')) {
      return (Icons.slideshow, Colors.orange.shade700);
    }
    if (mime.contains('document') ||
        mime.contains('word') ||
        mime.contains('text/')) {
      return (Icons.description, AppColors.fileDocument);
    }

    final ext = extension?.toLowerCase() ?? '';
    if ({
      'dart',
      'py',
      'js',
      'ts',
      'go',
      'rs',
      'java',
      'kt',
      'c',
      'cpp',
      'h',
    }.contains(ext)) {
      return (Icons.code, AppColors.fileCode);
    }
    if ({'json', 'yaml', 'yml', 'toml', 'xml', 'html', 'css'}.contains(ext)) {
      return (Icons.data_object, AppColors.fileCode);
    }

    return (Icons.insert_drive_file, AppColors.fileOther);
  }
}
