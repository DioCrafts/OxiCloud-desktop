import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AppLoggingInterceptor extends Interceptor {
  final Logger logger;

  AppLoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    logger.d(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    logger.e(
      '✕ ${err.response?.statusCode ?? 'ERR'} '
      '${err.requestOptions.method} ${err.requestOptions.uri}',
      error: err.message,
    );
    handler.next(err);
  }
}
