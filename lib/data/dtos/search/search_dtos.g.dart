// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResultResponseDto _$SearchResultResponseDtoFromJson(
  Map<String, dynamic> json,
) => SearchResultResponseDto(
  id: json['id'] as String,
  name: json['name'] as String,
  path: json['path'] as String,
  type: json['type'] as String,
  mimeType: json['mime_type'] as String?,
  size: (json['size'] as num?)?.toInt(),
  relevanceScore: (json['relevance_score'] as num?)?.toDouble(),
  modifiedAt: json['modified_at'] == null
      ? null
      : DateTime.parse(json['modified_at'] as String),
);

Map<String, dynamic> _$SearchResultResponseDtoToJson(
  SearchResultResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'path': instance.path,
  'type': instance.type,
  'mime_type': instance.mimeType,
  'size': instance.size,
  'relevance_score': instance.relevanceScore,
  'modified_at': instance.modifiedAt?.toIso8601String(),
};
