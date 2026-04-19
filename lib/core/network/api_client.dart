import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../auth/secure_storage.dart';
import '../config/app_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/retry_interceptor.dart';

class ApiClient {
  late final Dio dio;
  final AppConfig config;
  final SecureStorage secureStorage;
  final Logger _logger = Logger();

  ApiClient({
    required this.config,
    required this.secureStorage,
    Future<bool> Function()? onTokenRefresh,
    void Function()? onForceLogout,
  }) {
    dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        dio: dio,
        onTokenRefresh: onTokenRefresh,
        onForceLogout: onForceLogout,
      ),
      RetryInterceptor(dio: dio, maxRetries: config.maxRetries),
      if (config.isDebug) AppLoggingInterceptor(logger: _logger),
    ]);
  }

  void updateBaseUrl(String serverUrl) {
    dio.options.baseUrl = '$serverUrl/api';
  }
}
