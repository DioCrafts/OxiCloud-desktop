// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FolderResponseDto _$FolderResponseDtoFromJson(Map<String, dynamic> json) =>
    FolderResponseDto(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      parentId: json['parent_id'] as String?,
      ownerId: json['owner_id'] as String?,
      isRoot: json['is_root'] as bool?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      modifiedAt: json['modified_at'] == null
          ? null
          : DateTime.parse(json['modified_at'] as String),
    );

Map<String, dynamic> _$FolderResponseDtoToJson(FolderResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'path': instance.path,
      'parent_id': instance.parentId,
      'owner_id': instance.ownerId,
      'is_root': instance.isRoot,
      'created_at': instance.createdAt?.toIso8601String(),
      'modified_at': instance.modifiedAt?.toIso8601String(),
    };

CreateFolderRequestDto _$CreateFolderRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateFolderRequestDto(
  name: json['name'] as String,
  parentId: json['parent_id'] as String?,
);

Map<String, dynamic> _$CreateFolderRequestDtoToJson(
  CreateFolderRequestDto instance,
) => <String, dynamic>{'name': instance.name, 'parent_id': instance.parentId};

FolderContentsResponseDto _$FolderContentsResponseDtoFromJson(
  Map<String, dynamic> json,
) => FolderContentsResponseDto(
  folders: (json['folders'] as List<dynamic>)
      .map((e) => FolderResponseDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  files: json['files'] as List<dynamic>,
);

Map<String, dynamic> _$FolderContentsResponseDtoToJson(
  FolderContentsResponseDto instance,
) => <String, dynamic>{'folders': instance.folders, 'files': instance.files};
