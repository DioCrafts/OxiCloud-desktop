// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrashItemResponseDto _$TrashItemResponseDtoFromJson(
  Map<String, dynamic> json,
) => TrashItemResponseDto(
  id: json['id'] as String,
  name: json['name'] as String,
  itemType: json['item_type'] as String,
  originalPath: json['original_path'] as String,
  size: (json['size'] as num?)?.toInt(),
  deletedAt: DateTime.parse(json['deleted_at'] as String),
);

Map<String, dynamic> _$TrashItemResponseDtoToJson(
  TrashItemResponseDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'item_type': instance.itemType,
  'original_path': instance.originalPath,
  'size': instance.size,
  'deleted_at': instance.deletedAt.toIso8601String(),
};
