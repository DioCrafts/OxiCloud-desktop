import 'package:dio/dio.dart';
import '../error/exceptions.dart';
import '../error/failures.dart';

class ErrorHandler {
  ErrorHandler._();

  static Failure mapExceptionToFailure(Object error) {
    if (error is ServerException) {
      return _mapServerException(error);
    }
    if (error is CacheException) {
      return CacheFailure(error.message);
    }
    if (error is NetworkException) {
      return NetworkFailure(error.message);
    }
    if (error is DioException) {
      return _mapDioException(error);
    }
    return ServerFailure('Unexpected error: $error');
  }

  static ServerException mapDioToServerException(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final message = _extractMessage(data) ?? error.message ?? 'Unknown error';

    return switch (statusCode) {
      401 => UnauthorizedException(message),
      403 => ForbiddenException(message),
      404 => NotFoundException(message),
      409 => ConflictException(message),
      507 => QuotaExceededException(message),
      _ => ServerException(message, statusCode: statusCode, data: data),
    };
  }

  static Failure _mapServerException(ServerException e) {
    return switch (e) {
      UnauthorizedException() => const AuthFailure(),
      ForbiddenException() => PermissionFailure(e.message),
      NotFoundException() => NotFoundFailure(e.message),
      QuotaExceededException() => StorageFullFailure(e.message),
      _ => ServerFailure(e.message, statusCode: e.statusCode),
    };
  }

  static Failure _mapDioException(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure();
    }
    if (error.response != null) {
      final serverEx = mapDioToServerException(error);
      return _mapServerException(serverEx);
    }
    return ServerFailure(error.message ?? 'Network error');
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String?;
    }
    if (data is String && data.isNotEmpty) return data;
    return null;
  }
}
