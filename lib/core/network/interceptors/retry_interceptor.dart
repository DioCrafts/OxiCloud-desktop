import 'dart:math';
import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  static const _retryCountKey = 'retry_count';

  // Only retry on network errors and 5xx server errors
  static const _retryableStatusCodes = {500, 502, 503, 504};

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final retryCount = (err.requestOptions.extra[_retryCountKey] as int?) ?? 0;

    if (!_shouldRetry(err) || retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Exponential backoff with jitter
    final delay = baseDelay * pow(2, retryCount);
    final jitter = Duration(
      milliseconds: Random().nextInt(delay.inMilliseconds ~/ 2),
    );
    await Future.delayed(delay + jitter);

    err.requestOptions.extra[_retryCountKey] = retryCount + 1;

    try {
      final response = await dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    // Network-level errors
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    // Server-side retryable errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && _retryableStatusCodes.contains(statusCode)) {
      return true;
    }
    return false;
  }
}
