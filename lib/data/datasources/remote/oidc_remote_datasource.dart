import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// OIDC provider info returned by the server.
class OidcProviderInfo {
  final bool enabled;
  final String? providerName;
  final String? authorizeEndpoint;
  final bool passwordLoginEnabled;

  const OidcProviderInfo({
    required this.enabled,
    this.providerName,
    this.authorizeEndpoint,
    this.passwordLoginEnabled = true,
  });

  factory OidcProviderInfo.fromJson(Map<String, dynamic> json) {
    return OidcProviderInfo(
      enabled: json['enabled'] as bool? ?? false,
      providerName: json['provider_name'] as String?,
      authorizeEndpoint: json['authorize_endpoint'] as String?,
      passwordLoginEnabled: json['password_login_enabled'] as bool? ?? true,
    );
  }
}

/// Token exchange result.
class OidcTokenResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final Map<String, dynamic>? user;

  const OidcTokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  factory OidcTokenResult.fromJson(Map<String, dynamic> json) {
    return OidcTokenResult(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
      user: json['user'] as Map<String, dynamic>?,
    );
  }
}

class OidcRemoteDatasource {
  final Dio _dio;

  OidcRemoteDatasource(this._dio);

  /// Get OIDC provider status and info.
  Future<OidcProviderInfo> getProviders() async {
    try {
      final response = await _dio.get(ApiEndpoints.oidcProviders);
      return OidcProviderInfo.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Get the authorization URL the user should be redirected to.
  /// Returns the redirect URL from the Location header or response.
  Future<String> getAuthorizeUrl() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.oidcAuthorize,
        options: Options(
          followRedirects: false,
          validateStatus: (s) => s != null && s < 400,
        ),
      );
      // 302 redirect — get the Location header
      if (response.statusCode == 302) {
        return response.headers.value('location')!;
      }
      // Fallback: URL in response body
      return response.data['url'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 302) {
        return e.response!.headers.value('location')!;
      }
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Exchange an authorization code for tokens.
  Future<OidcTokenResult> exchangeCode(String code) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.oidcExchange,
        data: {'code': code},
      );
      return OidcTokenResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
