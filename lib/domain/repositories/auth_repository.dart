import 'package:oxicloud_desktop/domain/entities/auth_token.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Login with username and password
  Future<AuthToken> login(String username, String password);
  
  /// Refresh authentication token
  Future<AuthToken> refreshToken(String refreshToken);
  
  /// Logout the current user
  Future<void> logout();
  
  /// Check if a user is currently logged in
  Future<bool> isLoggedIn();
  
  /// Get the current user information
  Future<User> getCurrentUser();
  
  /// Set the server URL for API requests
  Future<void> setServerUrl(String url);
  
  /// Get the current server URL
  Future<String?> getServerUrl();
}