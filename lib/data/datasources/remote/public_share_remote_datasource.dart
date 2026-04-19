import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// Info about a publicly shared item.
class PublicShareInfo {
  final String id;
  final String itemType;
  final String name;
  final int? size;
  final bool passwordProtected;
  final String? expiresAt;

  const PublicShareInfo({
    required this.id,
    required this.itemType,
    required this.name,
    this.size,
    required this.passwordProtected,
    this.expiresAt,
  });

  factory PublicShareInfo.fromJson(Map<String, dynamic> json) {
    return PublicShareInfo(
      id: json['id'] as String,
      itemType: json['item_type'] as String? ?? 'file',
      name: json['name'] as String? ?? 'Shared item',
      size: json['size'] as int?,
      passwordProtected: json['password_protected'] as bool? ?? false,
      expiresAt: json['expires_at'] as String?,
    );
  }
}

class PublicShareRemoteDatasource {
  final Dio _dio;

  PublicShareRemoteDatasource(this._dio);

  /// Get info about a public share by token.
  Future<PublicShareInfo> getShareInfo(String token) async {
    try {
      final response = await _dio.get(ApiEndpoints.publicShareAccess(token));
      return PublicShareInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Verify password for a password-protected share.
  Future<bool> verifyPassword(String token, String password) async {
    try {
      await _dio.post(
        ApiEndpoints.publicShareVerify(token),
        data: {'password': password},
      );
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return false;
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Download the shared file.
  Future<void> download(String token, String savePath) async {
    try {
      await _dio.download(ApiEndpoints.publicShareDownload(token), savePath);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
