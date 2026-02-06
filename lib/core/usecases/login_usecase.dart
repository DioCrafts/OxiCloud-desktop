import 'package:dartz/dartz.dart';

import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Login use case
class LoginUseCase {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

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
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  Future<Either<AuthFailure, void>> call() async {
    return _repository.logout();
  }
}

/// Check authentication status use case
class CheckAuthUseCase {
  final AuthRepository _repository;

  CheckAuthUseCase(this._repository);

  Future<Either<AuthFailure, User?>> call() async {
    final isLoggedIn = await _repository.isLoggedIn();
    
    return isLoggedIn.fold(
      (failure) => Left(failure),
      (loggedIn) async {
        if (!loggedIn) return const Right(null);
        return _repository.getCurrentUser();
      },
    );
  }
}
