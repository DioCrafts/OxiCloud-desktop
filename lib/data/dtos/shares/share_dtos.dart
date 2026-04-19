import 'package:json_annotation/json_annotation.dart';

part 'share_dtos.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ShareResponseDto {
  final String id;
  final String itemId;
  final String? itemName;
  final String itemType;
  final String token;
  final String url;
  final bool hasPassword;
  final DateTime? expiresAt;
  final SharePermissionsDto permissions;
  final DateTime createdAt;
  final String createdBy;
  final int accessCount;

  const ShareResponseDto({
    required this.id,
    required this.itemId,
    this.itemName,
    required this.itemType,
    required this.token,
    required this.url,
    this.hasPassword = false,
    this.expiresAt,
    required this.permissions,
    required this.createdAt,
    required this.createdBy,
    this.accessCount = 0,
  });

  factory ShareResponseDto.fromJson(Map<String, dynamic> json) =>
      _$ShareResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ShareResponseDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class SharePermissionsDto {
  final bool read;
  final bool write;
  final bool reshare;

  const SharePermissionsDto({
    this.read = true,
    this.write = false,
    this.reshare = false,
  });

  factory SharePermissionsDto.fromJson(Map<String, dynamic> json) =>
      _$SharePermissionsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SharePermissionsDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class CreateShareRequestDto {
  final String itemId;
  final String itemType;
  final String? itemName;
  final String? password;
  final DateTime? expiresAt;
  final SharePermissionsDto? permissions;

  const CreateShareRequestDto({
    required this.itemId,
    required this.itemType,
    this.itemName,
    this.password,
    this.expiresAt,
    this.permissions,
  });

  factory CreateShareRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateShareRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CreateShareRequestDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UpdateShareRequestDto {
  final String? password;
  final DateTime? expiresAt;
  final SharePermissionsDto? permissions;

  const UpdateShareRequestDto({
    this.password,
    this.expiresAt,
    this.permissions,
  });

  factory UpdateShareRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdateShareRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateShareRequestDtoToJson(this);
}
