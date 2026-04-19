import 'package:json_annotation/json_annotation.dart';

part 'search_dtos.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class SearchResultResponseDto {
  final String id;
  final String name;
  final String path;
  final String type;
  final String? mimeType;
  final int? size;
  final double? relevanceScore;
  final DateTime? modifiedAt;

  const SearchResultResponseDto({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.mimeType,
    this.size,
    this.relevanceScore,
    this.modifiedAt,
  });

  factory SearchResultResponseDto.fromJson(Map<String, dynamic> json) =>
      _$SearchResultResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultResponseDtoToJson(this);
}
