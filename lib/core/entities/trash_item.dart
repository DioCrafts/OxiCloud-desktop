import 'package:equatable/equatable.dart';

/// A file or folder that has been moved to the trash.
class TrashItem extends Equatable {
  final String id;
  final String originalId;

  /// `"file"` or `"folder"`.
  final String itemType;
  final String name;
  final String originalPath;
  final DateTime trashedAt;
  final int daysUntilDeletion;

  const TrashItem({
    required this.id,
    required this.originalId,
    required this.itemType,
    required this.name,
    required this.originalPath,
    required this.trashedAt,
    required this.daysUntilDeletion,
  });

  bool get isFile => itemType == 'file';
  bool get isFolder => itemType == 'folder';

  @override
  List<Object?> get props => [
        id,
        originalId,
        itemType,
        name,
        originalPath,
        trashedAt,
        daysUntilDeletion,
      ];
}
