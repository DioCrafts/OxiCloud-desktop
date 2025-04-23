import 'package:oxicloud_desktop/domain/entities/file.dart' as file_entity;
import 'package:oxicloud_desktop/domain/entities/folder.dart';

/// Type of storage item
enum ItemType {
  /// File item
  file,
  
  /// Folder item
  folder,
}

/// Represents an item in the storage (file or folder)
class StorageItem {
  /// Item ID
  final String id;
  
  /// Item name
  final String name;
  
  /// Item path
  final String path;
  
  /// Last modification timestamp
  final DateTime modifiedAt;
  
  /// Whether the item is shared
  final bool isShared;
  
  /// Whether the item is marked as favorite
  final bool isFavorite;
  
  /// Type of the item (file or folder)
  final ItemType type;
  
  /// Size in bytes (0 for folders)
  final int size;
  
  /// MIME type (null for folders)
  final String? mimeType;
  
  /// Whether the item is available offline
  final bool isAvailableOffline;
  
  /// Creates a storage item
  const StorageItem({
    required this.id,
    required this.name,
    required this.path,
    required this.modifiedAt,
    required this.isShared,
    required this.isFavorite,
    required this.type,
    this.size = 0,
    this.mimeType,
    this.isAvailableOffline = false,
  });
  
  /// Creates a storage item from a file
  factory StorageItem.fromFile(file_entity.File file) {
    return StorageItem(
      id: file.id,
      name: file.name,
      path: file.path,
      modifiedAt: file.modifiedAt,
      isShared: file.isShared,
      isFavorite: file.isFavorite,
      type: ItemType.file,
      size: file.size,
      mimeType: file.mimeType,
      isAvailableOffline: file.isAvailableOffline,
    );
  }
  
  /// Creates a storage item from a folder
  factory StorageItem.fromFolder(Folder folder) {
    return StorageItem(
      id: folder.id,
      name: folder.name,
      path: folder.path,
      modifiedAt: folder.modifiedAt,
      isShared: folder.isShared,
      isFavorite: folder.isFavorite,
      type: ItemType.folder,
      isAvailableOffline: folder.isAvailableOffline,
    );
  }
  
  /// Check if item is a file
  bool get isFile => type == ItemType.file;
  
  /// Check if item is a folder
  bool get isFolder => type == ItemType.folder;
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StorageItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;
  
  @override
  int get hashCode => id.hashCode ^ type.hashCode;
  
  @override
  String toString() => 'StorageItem(id: $id, name: $name, type: $type)';
}