import 'package:equatable/equatable.dart';

class FolderEntity extends Equatable {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final String? ownerId;
  final bool isRoot;
  final DateTime createdAt;
  final DateTime modifiedAt;

  const FolderEntity({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    this.ownerId,
    this.isRoot = false,
    required this.createdAt,
    required this.modifiedAt,
  });

  FolderEntity copyWith({String? name, String? parentId}) {
    return FolderEntity(
      id: id,
      name: name ?? this.name,
      path: path,
      parentId: parentId ?? this.parentId,
      ownerId: ownerId,
      isRoot: isRoot,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, path, parentId, isRoot];
}
