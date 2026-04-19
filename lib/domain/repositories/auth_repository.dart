import '../entities/auth_tokens_entity.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Check if system has an admin configured.
  Future<({bool adminExists, bool registrationEnabled})> getStatus();

  /// Initial admin setup.
  Future<(UserEntity, AuthTokens)?> setup({
    required String username,
    required String email,
    required String password,
  });

  /// Login with username and password.
  Future<(UserEntity, AuthTokens)> login({
    required String username,
    required String password,
  });

  /// Register a new user.
  Future<(UserEntity, AuthTokens)> register({
    required String username,
    required String email,
    required String password,
  });

  /// Refresh the access token.
  Future<AuthTokens> refreshToken(String refreshToken);

  /// Get the current user profile.
  Future<UserEntity> getCurrentUser();

  /// Change password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Logout (invalidate session server-side).
  Future<void> logout();
}
