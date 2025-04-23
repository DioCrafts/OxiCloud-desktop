import 'dart:io';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';

/// HTTP client for communication with OxiCloud API
class OxiHttpClient {
  late final Dio _dio;
  final AppConfig _appConfig;
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('OxiHttpClient');
  
  /// Create an HTTP client
  OxiHttpClient(this._appConfig, this._secureStorage) {
    _dio = Dio(BaseOptions(
      baseUrl: _appConfig.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Accept-Encoding': 'gzip, deflate',
      },
    ));
    
    _setupInterceptors();
  }
  
  /// Setup request interceptors
  void _setupInterceptors() {
    // Authentication interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _secureStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          // Try to refresh token and retry
          if (await _refreshToken()) {
            // Clone the original request
            final options = e.requestOptions;
            final token = await _secureStorage.getToken();
            options.headers['Authorization'] = 'Bearer $token';
            
            try {
              // Retry with new token
              final response = await _dio.fetch(options);
              return handler.resolve(response);
            } on DioException catch (retryError) {
              return handler.reject(retryError);
            }
          }
        }
        return handler.next(e);
      },
    ));
    
    // Logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) {
        _logger.fine(log.toString());
      },
    ));
    
    // Retry interceptor
    _dio.interceptors.add(_RetryInterceptor(
      dio: _dio,
      logger: _logger,
      retries: 3,
    ));
  }
  
  /// Refresh the authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null) {
        return false;
      }
      
      // Create a new Dio instance without the auth interceptor to avoid cycles
      final refreshDio = Dio(BaseOptions(
        baseUrl: _appConfig.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
      ));
      
      final response = await refreshDio.post(
        '/refresh',
        data: {'refreshToken': refreshToken},
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final newToken = response.data['token'] as String?;
        final newRefreshToken = response.data['refreshToken'] as String?;
        
        if (newToken != null && newRefreshToken != null) {
          await _secureStorage.saveToken(newToken);
          await _secureStorage.saveRefreshToken(newRefreshToken);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      _logger.warning('Token refresh failed: $e');
      return false;
    }
  }
  
  /// Perform a GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      _logger.warning('GET request failed: $path, $e');
      rethrow;
    }
  }
  
  /// Perform a POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      _logger.warning('POST request failed: $path, $e');
      rethrow;
    }
  }
  
  /// Perform a PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      _logger.warning('PUT request failed: $path, $e');
      rethrow;
    }
  }
  
  /// Perform a DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      _logger.warning('DELETE request failed: $path, $e');
      rethrow;
    }
  }
  
  /// Download a file
  Future<Response> download(
    String url,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool deleteOnError = true,
  }) async {
    try {
      final response = await _dio.download(
        url,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        deleteOnError: deleteOnError,
      );
      return response;
    } catch (e) {
      _logger.warning('Download failed: $url, $e');
      rethrow;
    }
  }
  
  /// Set the base URL
  void setBaseUrl(String url) {
    _dio.options.baseUrl = url;
  }
}

/// Retry interceptor for automatically retrying failed requests
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  final Logger logger;
  final int retries;
  
  _RetryInterceptor({
    required this.dio,
    required this.logger,
    this.retries = 3,
  });
  
  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    int attempt = err.requestOptions.extra['attempt'] ?? 0;
    
    // Don't retry on client errors or if max retries reached
    if (err.response?.statusCode != null && 
        err.response!.statusCode! >= 400 &&
        err.response!.statusCode! < 500 &&
        err.response!.statusCode! != 408) {
      return handler.next(err);
    }
    
    // Don't retry on cancel
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }
    
    if (attempt < retries) {
      attempt++;
      
      // Calculate backoff delay
      final delay = Duration(milliseconds: 1000 * (1 << (attempt - 1)));
      
      logger.info('Retrying request to ${err.requestOptions.path} (Attempt $attempt of $retries) after ${delay.inMilliseconds}ms');
      
      await Future.delayed(delay);
      
      try {
        // Clone the original request and add attempt count
        final options = Options(
          method: err.requestOptions.method,
          headers: err.requestOptions.headers,
        );
        options.extra = {...err.requestOptions.extra, 'attempt': attempt};
        
        final response = await dio.request<dynamic>(
          err.requestOptions.path,
          data: err.requestOptions.data,
          queryParameters: err.requestOptions.queryParameters,
          options: options,
        );
        
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      }
    }
    
    return handler.next(err);
  }
}