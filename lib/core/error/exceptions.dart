class ServerException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ServerException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ServerException($statusCode): $message';
}

class UnauthorizedException extends ServerException {
  const UnauthorizedException([String message = 'Unauthorized'])
    : super(message, statusCode: 401);
}

class ForbiddenException extends ServerException {
  const ForbiddenException([String message = 'Forbidden'])
    : super(message, statusCode: 403);
}

class NotFoundException extends ServerException {
  const NotFoundException([String message = 'Not found'])
    : super(message, statusCode: 404);
}

class ConflictException extends ServerException {
  const ConflictException([String message = 'Conflict'])
    : super(message, statusCode: 409);
}

class QuotaExceededException extends ServerException {
  const QuotaExceededException([String message = 'Storage quota exceeded'])
    : super(message, statusCode: 507);
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}
