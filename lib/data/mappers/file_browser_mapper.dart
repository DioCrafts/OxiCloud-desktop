import '../../core/entities/file_item.dart';

/// Maps raw JSON maps from the OxiCloud REST API to domain entities.
class FileBrowserMapper {
  const FileBrowserMapper._();

  // ── Folder ──────────────────────────────────────────────────────────────

  static FolderItem folderFromJson(Map<String, dynamic> json) {
    return FolderItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String? ?? '',
      parentId: json['parent_id'] as String?,
      createdAt: _parseTimestamp(json['created_at']),
      modifiedAt: _parseTimestamp(json['modified_at']),
      isRoot: json['is_root'] as bool? ?? false,
    );
  }

  static List<FolderItem> foldersFromJson(List<Map<String, dynamic>> list) {
    return list.map(folderFromJson).toList();
  }

  // ── File ────────────────────────────────────────────────────────────────

  static FileItem fileFromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String? ?? '',
      size: _parseInt(json['size']),
      mimeType: json['mime_type'] as String? ?? 'application/octet-stream',
      folderId: json['folder_id'] as String?,
      createdAt: _parseTimestamp(json['created_at']),
      modifiedAt: _parseTimestamp(json['modified_at']),
    );
  }

  static List<FileItem> filesFromJson(List<Map<String, dynamic>> list) {
    return list.map(fileFromJson).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Parse a unix timestamp (seconds) — handles both int and double.
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
    }
    // Try parsing as ISO string
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Parse an integer that might arrive as a different numeric type.
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
