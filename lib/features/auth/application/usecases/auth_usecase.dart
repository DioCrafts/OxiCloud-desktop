import 'package:dartz/dartz.dart';

import '../../domain/models/user.dart';
import '../../domain/ports/auth_repository.dart';

class AuthUseCase {
  final AuthRepository _repository;

  AuthUseCase(this._repository);

  Future<Either<String, User>> login(String username, String password) {
    return _repository.login(username, password);
  }

  Future<Either<String, User>> register(String username, String email, String password) {
    return _repository.register(username, email, password);
  }

  Future<Either<String, void>> logout() {
    return _repository.logout();
  }

  Future<Either<String, User>> getCurrentUser() {
    return _repository.getCurrentUser();
  }

  Future<Either<String, void>> changePassword(String currentPassword, String newPassword) {
    return _repository.changePassword(currentPassword, newPassword);
  }

  Future<Either<String, void>> requestPasswordReset(String email) {
    return _repository.requestPasswordReset(email);
  }

  Future<Either<String, void>> resetPassword(String token, String newPassword) {
    return _repository.resetPassword(token, newPassword);
  }

  Future<Either<String, void>> verifyEmail(String token) {
    return _repository.verifyEmail(token);
  }

  Future<Either<String, void>> resendVerificationEmail(String email) {
    return _repository.resendVerificationEmail(email);
  }
} 