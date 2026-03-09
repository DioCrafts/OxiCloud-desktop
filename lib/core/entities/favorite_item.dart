import 'package:equatable/equatable.dart';

/// Favorite item entity
class FavoriteItem extends Equatable {
  const FavoriteItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.path,
    required this.addedAt,
  });

  final String id;
  final String itemId;
  final String itemType; // 'file' or 'folder'
  final String name;
  final String path;
  final DateTime addedAt;

  bool get isFile => itemType == 'file';
  bool get isFolder => itemType == 'folder';

  @override
  List<Object?> get props => [id, itemId, itemType, name, path, addedAt];
}

/// Recent item entity
class RecentItem extends Equatable {
  const RecentItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.name,
    required this.path,
    required this.accessedAt,
    this.mimeType,
    this.size,
  });

  final String id;
  final String itemId;
  final String itemType; // 'file' or 'folder'
  final String name;
  final String path;
  final String? mimeType;
  final int? size;
  final DateTime accessedAt;

  bool get isFile => itemType == 'file';
  bool get isFolder => itemType == 'folder';

  @override
  List<Object?> get props => [id, itemId, itemType, name, path, accessedAt];
}
