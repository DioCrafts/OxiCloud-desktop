import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Login use case
class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User>> call(AuthCredentials credentials) async {
    // Validate credentials first
    final validationError = credentials.validate();
    if (validationError != null) {
      return Left(UnknownAuthFailure(validationError));
    }

    return _repository.login(credentials);
  }
}

/// Logout use case
class LogoutUseCase {
  LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, void>> call() async {
    return _repository.logout();
  }
}

/// Check authentication status use case
class CheckAuthUseCase {
  CheckAuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<AuthFailure, User?>> call() async {
    final isLoggedIn = await _repository.isLoggedIn();
    
    return isLoggedIn.fold(
      Left.new,
      (loggedIn) async {
        if (!loggedIn) return const Right(null);
        return _repository.getCurrentUser();
      },
    );
  }
}
