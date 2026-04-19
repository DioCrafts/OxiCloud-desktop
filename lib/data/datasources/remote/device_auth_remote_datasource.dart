import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// Device authorization response (RFC 8628).
class DeviceAuthResponse {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final String? verificationUriComplete;
  final int expiresIn;
  final int interval;

  const DeviceAuthResponse({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    this.verificationUriComplete,
    required this.expiresIn,
    required this.interval,
  });

  factory DeviceAuthResponse.fromJson(Map<String, dynamic> json) {
    return DeviceAuthResponse(
      deviceCode: json['device_code'] as String,
      userCode: json['user_code'] as String,
      verificationUri: json['verification_uri'] as String,
      verificationUriComplete: json['verification_uri_complete'] as String?,
      expiresIn: json['expires_in'] as int,
      interval: json['interval'] as int? ?? 5,
    );
  }
}

/// Token poll result.
class DeviceTokenResult {
  final String? accessToken;
  final String? refreshToken;
  final int? expiresIn;
  final String?
  error; // "authorization_pending", "slow_down", "expired_token", "access_denied"

  bool get isPending => error == 'authorization_pending';
  bool get isSlowDown => error == 'slow_down';
  bool get isExpired => error == 'expired_token';
  bool get isDenied => error == 'access_denied';
  bool get isSuccess => accessToken != null;

  const DeviceTokenResult({
    this.accessToken,
    this.refreshToken,
    this.expiresIn,
    this.error,
  });

  factory DeviceTokenResult.fromJson(Map<String, dynamic> json) {
    return DeviceTokenResult(
      accessToken: json['access_token'] as String?,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
      error: json['error'] as String?,
    );
  }
}

/// Device info for management.
class DeviceInfo {
  final String id;
  final String name;
  final String? platform;
  final String createdAt;
  final String? lastUsed;

  const DeviceInfo({
    required this.id,
    required this.name,
    this.platform,
    required this.createdAt,
    this.lastUsed,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      platform: json['platform'] as String?,
      createdAt: json['created_at'] as String,
      lastUsed: json['last_used'] as String?,
    );
  }
}

class DeviceAuthRemoteDatasource {
  final Dio _dio;

  DeviceAuthRemoteDatasource(this._dio);

  /// Start a device authorization flow. Returns device code + user code.
  Future<DeviceAuthResponse> authorize({String? deviceName}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceAuthorize,
        data: {if (deviceName != null) 'device_name': deviceName},
      );
      return DeviceAuthResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Poll for a token (the device keeps calling this).
  Future<DeviceTokenResult> pollToken(String deviceCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceToken,
        data: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
          'device_code': deviceCode,
        },
      );
      return DeviceTokenResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // 400 with error field is expected during polling
      if (e.response?.statusCode == 400 && e.response?.data is Map) {
        return DeviceTokenResult.fromJson(
          e.response!.data as Map<String, dynamic>,
        );
      }
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Verify a user code (called by the logged-in user in browser/app).
  Future<Map<String, dynamic>> verify(String userCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.deviceVerify,
        data: {'user_code': userCode},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// List all authorized devices.
  Future<List<DeviceInfo>> listDevices() async {
    try {
      final response = await _dio.get(ApiEndpoints.deviceDevices);
      return (response.data as List<dynamic>)
          .map((e) => DeviceInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Revoke a device.
  Future<void> revokeDevice(String deviceId) async {
    try {
      await _dio.delete(ApiEndpoints.deviceRevoke(deviceId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
