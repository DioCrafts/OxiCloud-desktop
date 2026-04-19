import 'package:json_annotation/json_annotation.dart';

part 'file_dto.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class FileResponseDto {
  final String id;
  final String name;
  final String path;
  final int size;
  final String mimeType;
  final String? folderId;
  final String? ownerId;
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final String? sizeFormatted;
  final String? iconClass;

  const FileResponseDto({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.mimeType,
    this.folderId,
    this.ownerId,
    this.createdAt,
    this.modifiedAt,
    this.sizeFormatted,
    this.iconClass,
  });

  factory FileResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FileResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$FileResponseDtoToJson(this);
}
