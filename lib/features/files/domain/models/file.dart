import 'package:json_annotation/json_annotation.dart';

part 'file.g.dart';

@JsonSerializable()
class File {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentId;
  final bool isFavorite;
  final bool isShared;
  final String? thumbnailUrl;
  final String? downloadUrl;

  const File({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    required this.createdAt,
    required this.updatedAt,
    this.parentId,
    this.isFavorite = false,
    this.isShared = false,
    this.thumbnailUrl,
    this.downloadUrl,
  });

  factory File.fromJson(Map<String, dynamic> json) => _$FileFromJson(json);
  Map<String, dynamic> toJson() => _$FileToJson(this);
} 