import 'package:json_annotation/json_annotation.dart';

part 'trash_dtos.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class TrashItemResponseDto {
  final String id;
  final String name;
  final String itemType;
  final String originalPath;
  final int? size;
  final DateTime deletedAt;

  const TrashItemResponseDto({
    required this.id,
    required this.name,
    required this.itemType,
    required this.originalPath,
    this.size,
    required this.deletedAt,
  });

  factory TrashItemResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TrashItemResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TrashItemResponseDtoToJson(this);
}
