import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../presentation/theme/oxicloud_colors.dart';

// =============================================================================
// File entity
// =============================================================================

class FileItem extends Equatable {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final String? folderId;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const FileItem({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.folderId,
    required this.createdAt,
    required this.modifiedAt,
  });

  /// File extension without dot, lowercase.
  String get extension =>
      name.contains('.') ? name.split('.').last.toLowerCase() : '';

  /// Semantic file type derived from MIME type or extension.
  FileType get fileType => FileTypeHelper.fromMime(mimeType, extension);

  /// Human-readable file size.
  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props =>
      [id, name, path, size, mimeType, folderId, createdAt, modifiedAt];
}

// =============================================================================
// Folder entity
// =============================================================================

class FolderItem extends Equatable {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isRoot;

  const FolderItem({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    required this.createdAt,
    required this.modifiedAt,
    this.isRoot = false,
  });

  @override
  List<Object?> get props =>
      [id, name, path, parentId, createdAt, modifiedAt, isRoot];
}

// =============================================================================
// Breadcrumb navigation item
// =============================================================================

class BreadcrumbItem extends Equatable {
  /// Folder id — `null` means root.
  final String? id;
  final String name;

  const BreadcrumbItem({this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

// =============================================================================
// View / sort helpers
// =============================================================================

enum ViewMode { list, grid }

enum SortMode {
  nameAsc,
  nameDesc,
  dateAsc,
  dateDesc,
  sizeAsc,
  sizeDesc,
}

// =============================================================================
// File type classification
// =============================================================================

enum FileType {
  image,
  video,
  audio,
  document,
  spreadsheet,
  presentation,
  pdf,
  archive,
  code,
  text,
  other,
}

class FileTypeHelper {
  const FileTypeHelper._();

  static FileType fromMime(String mime, [String ext = '']) {
    final m = mime.toLowerCase();
    if (m.startsWith('image/')) return FileType.image;
    if (m.startsWith('video/')) return FileType.video;
    if (m.startsWith('audio/')) return FileType.audio;
    if (m == 'application/pdf') return FileType.pdf;
    if (m.contains('zip') ||
        m.contains('tar') ||
        m.contains('gzip') ||
        m.contains('rar') ||
        m.contains('7z') ||
        m.contains('compressed')) {
      return FileType.archive;
    }
    if (m.contains('spreadsheet') || m.contains('excel') || m.contains('csv')) {
      return FileType.spreadsheet;
    }
    if (m.contains('presentation') || m.contains('powerpoint')) {
      return FileType.presentation;
    }
    if (m.contains('document') ||
        m.contains('word') ||
        m.contains('msword') ||
        m.contains('opendocument.text')) {
      return FileType.document;
    }
    if (m.startsWith('text/')) {
      return _fromExtension(ext) ?? FileType.text;
    }
    if (m == 'application/json' ||
        m == 'application/javascript' ||
        m == 'application/xml' ||
        m == 'application/x-yaml') {
      return FileType.code;
    }
    return _fromExtension(ext) ?? FileType.other;
  }

  static FileType? _fromExtension(String ext) {
    const codeExts = {
      'dart', 'rs', 'py', 'js', 'ts', 'jsx', 'tsx', 'java', 'kt', 'c',
      'cpp', 'h', 'go', 'rb', 'php', 'swift', 'sh', 'bat', 'ps1', 'yml',
      'yaml', 'toml', 'json', 'xml', 'html', 'css', 'scss', 'sql',
    };
    if (codeExts.contains(ext)) return FileType.code;
    const docExts = {'doc', 'docx', 'odt', 'rtf'};
    if (docExts.contains(ext)) return FileType.document;
    const sheetExts = {'xls', 'xlsx', 'ods', 'csv'};
    if (sheetExts.contains(ext)) return FileType.spreadsheet;
    const presExts = {'ppt', 'pptx', 'odp'};
    if (presExts.contains(ext)) return FileType.presentation;
    return null;
  }

  /// Icon for the file type.
  static IconData icon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image_outlined;
      case FileType.video:
        return Icons.videocam_outlined;
      case FileType.audio:
        return Icons.audiotrack_outlined;
      case FileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case FileType.document:
        return Icons.description_outlined;
      case FileType.spreadsheet:
        return Icons.table_chart_outlined;
      case FileType.presentation:
        return Icons.slideshow_outlined;
      case FileType.archive:
        return Icons.archive_outlined;
      case FileType.code:
        return Icons.code_outlined;
      case FileType.text:
        return Icons.text_snippet_outlined;
      case FileType.other:
        return Icons.insert_drive_file_outlined;
    }
  }

  /// Color for the file type — matches server frontend palette.
  static Color color(FileType type) {
    switch (type) {
      case FileType.image:
        return const Color(0xFF48BB78); // green
      case FileType.video:
        return const Color(0xFFED64A6); // pink
      case FileType.audio:
        return const Color(0xFF9F7AEA); // purple
      case FileType.pdf:
        return const Color(0xFFE53E3E); // red
      case FileType.document:
        return const Color(0xFF4299E1); // blue
      case FileType.spreadsheet:
        return const Color(0xFF38A169); // emerald
      case FileType.presentation:
        return OxiColors.primary; // coral
      case FileType.archive:
        return const Color(0xFFD69E2E); // amber
      case FileType.code:
        return const Color(0xFF667EEA); // indigo
      case FileType.text:
        return const Color(0xFF718096); // gray
      case FileType.other:
        return OxiColors.textSecondary;
    }
  }
}
