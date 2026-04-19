// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

RegisterRequestDto _$RegisterRequestDtoFromJson(Map<String, dynamic> json) =>
    RegisterRequestDto(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$RegisterRequestDtoToJson(RegisterRequestDto instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
    };

SetupAdminRequestDto _$SetupAdminRequestDtoFromJson(
  Map<String, dynamic> json,
) => SetupAdminRequestDto(
  username: json['username'] as String,
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$SetupAdminRequestDtoToJson(
  SetupAdminRequestDto instance,
) => <String, dynamic>{
  'username': instance.username,
  'email': instance.email,
  'password': instance.password,
};

AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    AuthResponseDto(
      user: UserResponseDto.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
    );

Map<String, dynamic> _$AuthResponseDtoToJson(AuthResponseDto instance) =>
    <String, dynamic>{
      'user': instance.user,
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'expires_in': instance.expiresIn,
    };

UserResponseDto _$UserResponseDtoFromJson(Map<String, dynamic> json) =>
    UserResponseDto(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      role: json['role'] as String?,
      storageQuotaBytes: (json['storage_quota_bytes'] as num?)?.toInt(),
      storageUsedBytes: (json['storage_used_bytes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UserResponseDtoToJson(UserResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'role': instance.role,
      'storage_quota_bytes': instance.storageQuotaBytes,
      'storage_used_bytes': instance.storageUsedBytes,
    };

RefreshTokenRequestDto _$RefreshTokenRequestDtoFromJson(
  Map<String, dynamic> json,
) => RefreshTokenRequestDto(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshTokenRequestDtoToJson(
  RefreshTokenRequestDto instance,
) => <String, dynamic>{'refresh_token': instance.refreshToken};

ChangePasswordRequestDto _$ChangePasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => ChangePasswordRequestDto(
  currentPassword: json['current_password'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$ChangePasswordRequestDtoToJson(
  ChangePasswordRequestDto instance,
) => <String, dynamic>{
  'current_password': instance.currentPassword,
  'new_password': instance.newPassword,
};

AuthStatusDto _$AuthStatusDtoFromJson(Map<String, dynamic> json) =>
    AuthStatusDto(
      adminExists: json['admin_exists'] as bool,
      registrationEnabled: json['registration_enabled'] as bool? ?? true,
    );

Map<String, dynamic> _$AuthStatusDtoToJson(AuthStatusDto instance) =>
    <String, dynamic>{
      'admin_exists': instance.adminExists,
      'registration_enabled': instance.registrationEnabled,
    };
