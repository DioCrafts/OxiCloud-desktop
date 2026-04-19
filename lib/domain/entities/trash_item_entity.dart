import 'package:equatable/equatable.dart';

class TrashItemEntity extends Equatable {
  final String id;
  final String name;
  final String itemType; // 'file' or 'folder'
  final String originalPath;
  final int? size;
  final DateTime deletedAt;

  const TrashItemEntity({
    required this.id,
    required this.name,
    required this.itemType,
    required this.originalPath,
    this.size,
    required this.deletedAt,
  });

  bool get isFile => itemType == 'file';
  bool get isFolder => itemType == 'folder';

  @override
  List<Object?> get props => [id, name, itemType, deletedAt];
}
