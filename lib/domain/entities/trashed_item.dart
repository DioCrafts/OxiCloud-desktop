import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';

/// Represents an item that has been moved to trash
class TrashedItem {
  /// Unique identifier of the trashed item
  final String id;
  
  /// Original path before trashing
  final String originalPath;
  
  /// Name of the item
  final String name;
  
  /// Whether the item is a folder
  final bool isFolder;
  
  /// Size in bytes (0 for folders)
  final int size;
  
  /// MIME type (null for folders)
  final String? mimeType;
  
  /// When the item was trashed
  final DateTime trashedAt;
  
  /// When the item will be permanently deleted
  final DateTime expiresAt;
  
  /// Original item ID
  final String originalId;
  
  /// Create a TrashedItem
  const TrashedItem({
    required this.id,
    required this.originalPath,
    required this.name,
    required this.isFolder,
    required this.size,
    this.mimeType,
    required this.trashedAt,
    required this.expiresAt,
    required this.originalId,
  });
  
  /// Create a TrashedItem from a File
  factory TrashedItem.fromFile(File file, {
    required DateTime trashedAt,
    required DateTime expiresAt,
  }) {
    return TrashedItem(
      id: 'trashed_${file.id}',
      originalPath: file.path,
      name: file.name,
      isFolder: false,
      size: file.size,
      mimeType: file.mimeType,
      trashedAt: trashedAt,
      expiresAt: expiresAt,
      originalId: file.id,
    );
  }
  
  /// Create a TrashedItem from a Folder
  factory TrashedItem.fromFolder(Folder folder, {
    required DateTime trashedAt,
    required DateTime expiresAt,
  }) {
    return TrashedItem(
      id: 'trashed_${folder.id}',
      originalPath: folder.path,
      name: folder.name,
      isFolder: true,
      size: 0, // Folders don't have size initially
      trashedAt: trashedAt,
      expiresAt: expiresAt,
      originalId: folder.id,
    );
  }
  
  /// Create a TrashedItem from a StorageItem
  factory TrashedItem.fromStorageItem(StorageItem item, {
    required DateTime trashedAt,
    required DateTime expiresAt,
  }) {
    return TrashedItem(
      id: 'trashed_${item.id}',
      originalPath: item.path,
      name: item.name,
      isFolder: item.isFolder,
      size: item.size,
      mimeType: item.mimeType,
      trashedAt: trashedAt,
      expiresAt: expiresAt,
      originalId: item.id,
    );
  }
  
  /// Create a copy of this TrashedItem with the given fields replaced
  TrashedItem copyWith({
    String? id,
    String? originalPath,
    String? name,
    bool? isFolder,
    int? size,
    String? mimeType,
    DateTime? trashedAt,
    DateTime? expiresAt,
    String? originalId,
  }) {
    return TrashedItem(
      id: id ?? this.id,
      originalPath: originalPath ?? this.originalPath,
      name: name ?? this.name,
      isFolder: isFolder ?? this.isFolder,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      trashedAt: trashedAt ?? this.trashedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      originalId: originalId ?? this.originalId,
    );
  }
  
  /// Convert to a StorageItem
  StorageItem toStorageItem() {
    return StorageItem(
      id: id,
      name: name,
      path: originalPath,
      modifiedAt: trashedAt,
      isShared: false,
      isFavorite: false,
      type: isFolder ? ItemType.folder : ItemType.file,
      size: size,
      mimeType: mimeType,
    );
  }
  
  /// Days remaining before permanent deletion
  int get daysRemaining {
    final now = DateTime.now();
    return expiresAt.difference(now).inDays;
  }
  
  /// Check if the item is expired (should be permanently deleted)
  bool get isExpired {
    final now = DateTime.now();
    return now.isAfter(expiresAt);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrashedItem &&
          runtimeType == other.runtimeType &&
          id == other.id;
  
  @override
  int get hashCode => id.hashCode;
  
  @override
  String toString() => 'TrashedItem(id: $id, name: $name, isFolder: $isFolder)';
}