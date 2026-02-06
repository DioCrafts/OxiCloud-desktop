import 'package:dartz/dartz.dart';

import '../entities/user.dart';

/// Authentication repository interface (port)
abstract class AuthRepository {
  /// Login with credentials
  Future<Either<AuthFailure, User>> login(AuthCredentials credentials);

  /// Logout current user
  Future<Either<AuthFailure, void>> logout();

  /// Check if user is currently logged in
  Future<Either<AuthFailure, bool>> isLoggedIn();

  /// Get current user info
  Future<Either<AuthFailure, User?>> getCurrentUser();

  /// Get stored server URL
  Future<String?> getStoredServerUrl();

  /// Get stored username
  Future<String?> getStoredUsername();
}

/// Authentication failures
abstract class AuthFailure {
  final String message;
  const AuthFailure(this.message);
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure() : super('Invalid username or password');
}

class ServerUnreachableFailure extends AuthFailure {
  const ServerUnreachableFailure(String message)
      : super('Server unreachable: $message');
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure(String message) : super('Network error: $message');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(String message) : super(message);
}
