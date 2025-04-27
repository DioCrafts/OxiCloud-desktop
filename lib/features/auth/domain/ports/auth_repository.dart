import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/features/auth/domain/models/user.dart';

abstract class AuthRepository {
  Future<Either<String, User>> login(String username, String password);
  Future<Either<String, User>> register(String username, String email, String password);
  Future<Either<String, void>> logout();
  Future<Either<String, User>> getCurrentUser();
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword);
  Future<Either<String, void>> requestPasswordReset(String email);
  Future<Either<String, void>> resetPassword(String token, String newPassword);
  Future<Either<String, void>> verifyEmail(String token);
  Future<Either<String, void>> resendVerificationEmail(String email);
} 