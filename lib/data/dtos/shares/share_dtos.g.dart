// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShareResponseDto _$ShareResponseDtoFromJson(Map<String, dynamic> json) =>
    ShareResponseDto(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String?,
      itemType: json['item_type'] as String,
      token: json['token'] as String,
      url: json['url'] as String,
      hasPassword: json['has_password'] as bool? ?? false,
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.parse(json['expires_at'] as String),
      permissions: SharePermissionsDto.fromJson(
        json['permissions'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      createdBy: json['created_by'] as String,
      accessCount: (json['access_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ShareResponseDtoToJson(ShareResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'item_id': instance.itemId,
      'item_name': instance.itemName,
      'item_type': instance.itemType,
      'token': instance.token,
      'url': instance.url,
      'has_password': instance.hasPassword,
      'expires_at': instance.expiresAt?.toIso8601String(),
      'permissions': instance.permissions,
      'created_at': instance.createdAt.toIso8601String(),
      'created_by': instance.createdBy,
      'access_count': instance.accessCount,
    };

SharePermissionsDto _$SharePermissionsDtoFromJson(Map<String, dynamic> json) =>
    SharePermissionsDto(
      read: json['read'] as bool? ?? true,
      write: json['write'] as bool? ?? false,
      reshare: json['reshare'] as bool? ?? false,
    );

Map<String, dynamic> _$SharePermissionsDtoToJson(
  SharePermissionsDto instance,
) => <String, dynamic>{
  'read': instance.read,
  'write': instance.write,
  'reshare': instance.reshare,
};

CreateShareRequestDto _$CreateShareRequestDtoFromJson(
  Map<String, dynamic> json,
) => CreateShareRequestDto(
  itemId: json['item_id'] as String,
  itemType: json['item_type'] as String,
  itemName: json['item_name'] as String?,
  password: json['password'] as String?,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  permissions: json['permissions'] == null
      ? null
      : SharePermissionsDto.fromJson(
          json['permissions'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$CreateShareRequestDtoToJson(
  CreateShareRequestDto instance,
) => <String, dynamic>{
  'item_id': instance.itemId,
  'item_type': instance.itemType,
  'item_name': instance.itemName,
  'password': instance.password,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'permissions': instance.permissions,
};

UpdateShareRequestDto _$UpdateShareRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdateShareRequestDto(
  password: json['password'] as String?,
  expiresAt: json['expires_at'] == null
      ? null
      : DateTime.parse(json['expires_at'] as String),
  permissions: json['permissions'] == null
      ? null
      : SharePermissionsDto.fromJson(
          json['permissions'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$UpdateShareRequestDtoToJson(
  UpdateShareRequestDto instance,
) => <String, dynamic>{
  'password': instance.password,
  'expires_at': instance.expiresAt?.toIso8601String(),
  'permissions': instance.permissions,
};
