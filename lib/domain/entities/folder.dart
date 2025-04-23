import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

/// Represents a folder in the system
class Folder {
  /// Unique folder identifier
  final String id;
  
  /// Folder name (without path)
  final String name;
  
  /// Full path in the storage
  final String path;
  
  /// Last modification timestamp
  final DateTime modifiedAt;
  
  /// Whether the folder is shared
  final bool isShared;
  
  /// Whether the folder is marked as favorite
  final bool isFavorite;
  
  /// Parent folder ID (null for root)
  final String? parentId;
  
  /// ETag for synchronization
  final String? etag;
  
  /// Whether the folder is synced locally
  final bool isSynced;
  
  /// Whether the folder should be kept available offline
  final bool isAvailableOffline;
  
  /// Creates a folder entity
  const Folder({
    required this.id,
    required this.name,
    required this.path,
    required this.modifiedAt,
    this.isShared = false,
    this.isFavorite = false,
    this.parentId,
    this.etag,
    this.isSynced = false,
    this.isAvailableOffline = false,
  });
  
  /// Creates a copy of this folder with the given fields replaced
  Folder copyWith({
    String? id,
    String? name,
    String? path,
    DateTime? modifiedAt,
    bool? isShared,
    bool? isFavorite,
    String? parentId,
    String? etag,
    bool? isSynced,
    bool? isAvailableOffline,
  }) {
    return Folder(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isShared: isShared ?? this.isShared,
      isFavorite: isFavorite ?? this.isFavorite,
      parentId: parentId ?? this.parentId,
      etag: etag ?? this.etag,
      isSynced: isSynced ?? this.isSynced,
      isAvailableOffline: isAvailableOffline ?? this.isAvailableOffline,
    );
  }
  
  /// Get parent folder path
  String get parentPath => p.dirname(path);
  
  /// Check if this is the root folder
  bool get isRoot => parentId == null || path == '/';
  
  /// Format last modified date
  String get formattedModifiedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final folderDate = DateTime(
      modifiedAt.year,
      modifiedAt.month,
      modifiedAt.day,
    );
    
    if (folderDate == today) {
      return 'Today ${DateFormat.Hm().format(modifiedAt)}';
    } else if (folderDate == yesterday) {
      return 'Yesterday ${DateFormat.Hm().format(modifiedAt)}';
    } else if (now.difference(modifiedAt).inDays < 7) {
      return DateFormat.E().format(modifiedAt) + ' ' + DateFormat.Hm().format(modifiedAt);
    } else {
      return DateFormat.yMMMd().format(modifiedAt);
    }
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Folder &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'Folder(id: $id, name: $name, path: $path)';
}