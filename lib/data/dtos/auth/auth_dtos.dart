import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

@JsonSerializable()
class LoginRequestDto {
  final String username;
  final String password;

  const LoginRequestDto({required this.username, required this.password});

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}

@JsonSerializable()
class RegisterRequestDto {
  final String username;
  final String email;
  final String password;

  const RegisterRequestDto({
    required this.username,
    required this.email,
    required this.password,
  });

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);
}

@JsonSerializable()
class SetupAdminRequestDto {
  final String username;
  final String email;
  final String password;

  const SetupAdminRequestDto({
    required this.username,
    required this.email,
    required this.password,
  });

  factory SetupAdminRequestDto.fromJson(Map<String, dynamic> json) =>
      _$SetupAdminRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$SetupAdminRequestDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthResponseDto {
  final UserResponseDto user;
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthResponseDto({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class UserResponseDto {
  final String id;
  final String username;
  final String? email;
  final String? role;
  final int? storageQuotaBytes;
  final int? storageUsedBytes;

  const UserResponseDto({
    required this.id,
    required this.username,
    this.email,
    this.role,
    this.storageQuotaBytes,
    this.storageUsedBytes,
  });

  factory UserResponseDto.fromJson(Map<String, dynamic> json) =>
      _$UserResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserResponseDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class RefreshTokenRequestDto {
  final String refreshToken;

  const RefreshTokenRequestDto({required this.refreshToken});

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RefreshTokenRequestDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ChangePasswordRequestDto {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  factory ChangePasswordRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ChangePasswordRequestDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ChangePasswordRequestDtoToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthStatusDto {
  final bool adminExists;
  final bool registrationEnabled;

  const AuthStatusDto({
    required this.adminExists,
    this.registrationEnabled = true,
  });

  factory AuthStatusDto.fromJson(Map<String, dynamic> json) =>
      _$AuthStatusDtoFromJson(json);
}
