import 'package:json_annotation/json_annotation.dart';

part 'folder_dtos.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FolderResponseDto {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final String? ownerId;
  final bool? isRoot;
  final DateTime? createdAt;
  final DateTime? modifiedAt;

  const FolderResponseDto({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    this.ownerId,
    this.isRoot,
    this.createdAt,
    this.modifiedAt,
  });

  factory FolderResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FolderResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FolderResponseDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateFolderRequestDto {
  final String name;
  final String? parentId;

  const CreateFolderRequestDto({required this.name, this.parentId});

  factory CreateFolderRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateFolderRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateFolderRequestDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class FolderContentsResponseDto {
  final List<FolderResponseDto> folders;
  final List<dynamic> files; // uses FileResponseDto

  const FolderContentsResponseDto({required this.folders, required this.files});

  factory FolderContentsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FolderContentsResponseDtoFromJson(json);
}
