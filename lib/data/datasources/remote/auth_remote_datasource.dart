import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/auth/auth_dtos.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<AuthStatusDto> getStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.authStatus);
      return AuthStatusDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AuthResponseDto> setup(SetupAdminRequestDto dto) async {
    try {
      final response = await _dio.post(ApiEndpoints.setup, data: dto.toJson());
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AuthResponseDto> login(LoginRequestDto dto) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: dto.toJson());
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AuthResponseDto> register(RegisterRequestDto dto) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: dto.toJson(),
      );
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AuthResponseDto> refreshToken(RefreshTokenRequestDto dto) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.refresh,
        data: dto.toJson(),
      );
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<UserResponseDto> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.me);
      return UserResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> changePassword(ChangePasswordRequestDto dto) async {
    try {
      await _dio.put(ApiEndpoints.changePassword, data: dto.toJson());
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
