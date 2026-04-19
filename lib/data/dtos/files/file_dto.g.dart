// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileResponseDto _$FileResponseDtoFromJson(Map<String, dynamic> json) =>
    FileResponseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      size: (json['size'] as num).toInt(),
      mimeType: json['mime_type'] as String,
      folderId: json['folder_id'] as String?,
      ownerId: json['owner_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] == null
          ? null
          : DateTime.parse(json['modified_at'] as String),
      sizeFormatted: json['size_formatted'] as String?,
      iconClass: json['icon_class'] as String?,
    );

Map<String, dynamic> _$FileResponseDtoToJson(FileResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'size': instance.size,
      'mime_type': instance.mimeType,
      'folder_id': instance.folderId,
      'owner_id': instance.ownerId,
      'created_at': instance.createdAt?.toIso8601String(),
      'modified_at': instance.modifiedAt?.toIso8601String(),
      'size_formatted': instance.sizeFormatted,
      'icon_class': instance.iconClass,
    };
