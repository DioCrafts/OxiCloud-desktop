import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  const Failure(this.message, {this.statusCode, this.originalError});

  @override
  List<Object?> get props => [message, statusCode];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.statusCode, super.originalError});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class TokenExpiredFailure extends AuthFailure {
  const TokenExpiredFailure() : super('Session expired. Please log in again.');
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission denied']);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found']);
}

class ConflictFailure extends Failure {
  final String? localVersion;
  final String? remoteVersion;

  const ConflictFailure({
    String message = 'Sync conflict detected',
    this.localVersion,
    this.remoteVersion,
  }) : super(message);

  @override
  List<Object?> get props => [...super.props, localVersion, remoteVersion];
}

class StorageFullFailure extends Failure {
  const StorageFullFailure([super.message = 'Storage quota exceeded']);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors});

  @override
  List<Object?> get props => [...super.props, fieldErrors];
}
