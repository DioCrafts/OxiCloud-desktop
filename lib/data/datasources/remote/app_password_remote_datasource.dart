import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

class AppPasswordDto {
  final String id;
  final String name;
  final String prefix;
  final String createdAt;
  final String? lastUsed;

  const AppPasswordDto({
    required this.id,
    required this.name,
    required this.prefix,
    required this.createdAt,
    this.lastUsed,
  });

  factory AppPasswordDto.fromJson(Map<String, dynamic> json) {
    return AppPasswordDto(
      id: json['id'] as String,
      name: json['name'] as String,
      prefix: json['prefix'] as String,
      createdAt: json['created_at'] as String,
      lastUsed: json['last_used'] as String?,
    );
  }
}

class AppPasswordCreateResult {
  final String id;
  final String name;
  final String password; // Only returned once at creation time

  const AppPasswordCreateResult({
    required this.id,
    required this.name,
    required this.password,
  });

  factory AppPasswordCreateResult.fromJson(Map<String, dynamic> json) {
    return AppPasswordCreateResult(
      id: json['id'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
    );
  }
}

class AppPasswordRemoteDatasource {
  final Dio _dio;

  AppPasswordRemoteDatasource(this._dio);

  /// Create a new app password. Returns the plain-text password (shown once).
  Future<AppPasswordCreateResult> create(String name) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.appPasswords,
        data: {'name': name},
      );
      return AppPasswordCreateResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// List all app passwords (prefix only, no plain-text).
  Future<List<AppPasswordDto>> list() async {
    try {
      final response = await _dio.get(ApiEndpoints.appPasswords);
      return (response.data as List<dynamic>)
          .map((e) => AppPasswordDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Revoke (delete) an app password.
  Future<void> revoke(String id) async {
    try {
      await _dio.delete(ApiEndpoints.appPassword(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
