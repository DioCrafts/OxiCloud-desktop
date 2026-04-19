import 'package:dio/dio.dart';
import '../../auth/secure_storage.dart';
import '../../config/constants.dart';
import '../api_endpoints.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage secureStorage;
  final Dio dio;
  final Future<bool> Function()? onTokenRefresh;
  final void Function()? onForceLogout;

  bool _isRefreshing = false;
  final List<_RetryRequest> _pendingRequests = [];

  AuthInterceptor({
    required this.secureStorage,
    required this.dio,
    this.onTokenRefresh,
    this.onForceLogout,
  });

  // Paths that don't need auth tokens
  static const _publicPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.refresh,
    ApiEndpoints.setup,
    ApiEndpoints.authStatus,
    ApiEndpoints.oidcProviders,
    ApiEndpoints.oidcAuthorize,
    ApiEndpoints.oidcCallback,
    ApiEndpoints.oidcExchange,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for public endpoints and share URLs
    final path = options.path;
    if (_publicPaths.contains(path) || path.startsWith('/s/')) {
      return handler.next(options);
    }

    final token = await secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Don't retry auth endpoints themselves
    final path = err.requestOptions.path;
    if (path == ApiEndpoints.refresh || path == ApiEndpoints.login) {
      onForceLogout?.call();
      return handler.next(err);
    }

    if (_isRefreshing) {
      // Queue this request to retry after refresh completes
      _pendingRequests.add(_RetryRequest(err.requestOptions, handler));
      return;
    }

    _isRefreshing = true;

    try {
      final success = await onTokenRefresh?.call() ?? false;
      if (success) {
        // Retry the original request
        final token = await secureStorage.getAccessToken();
        err.requestOptions.headers['Authorization'] = 'Bearer $token';
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);

        // Retry all queued requests
        for (final pending in _pendingRequests) {
          pending.options.headers['Authorization'] = 'Bearer $token';
          final resp = await dio.fetch(pending.options);
          pending.handler.resolve(resp);
        }
      } else {
        onForceLogout?.call();
        handler.next(err);
        for (final pending in _pendingRequests) {
          pending.handler.next(err);
        }
      }
    } catch (e) {
      onForceLogout?.call();
      handler.next(err);
      for (final pending in _pendingRequests) {
        pending.handler.next(err);
      }
    } finally {
      _pendingRequests.clear();
      _isRefreshing = false;
    }
  }
}

class _RetryRequest {
  final RequestOptions options;
  final ErrorInterceptorHandler handler;

  _RetryRequest(this.options, this.handler);
}
