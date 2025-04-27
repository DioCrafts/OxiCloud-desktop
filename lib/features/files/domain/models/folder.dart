import 'package:json_annotation/json_annotation.dart';

part 'folder.g.dart';

@JsonSerializable()
class Folder {
  final String id;
  final String name;
  final String path;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentId;
  final bool isFavorite;
  final bool isShared;
  final int itemCount;

  const Folder({
    required this.id,
    required this.name,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.isFavorite = false,
    this.isShared = false,
    this.itemCount = 0,
  });

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
  Map<String, dynamic> toJson() => _$FolderToJson(this);
} 