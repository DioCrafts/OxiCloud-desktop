import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/entities/auth_token.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';
import 'package:oxicloud_desktop/infrastructure/services/http_client.dart';

/// Adapter for authentication API
class AuthAdapter implements AuthRepository {
  final OxiHttpClient _httpClient;
  final SecureStorage _secureStorage;
  final Logger _logger = LoggingManager.getLogger('AuthAdapter');
  
  /// Create an AuthAdapter
  AuthAdapter(this._httpClient, this._secureStorage);
  
  @override
  Future<AuthToken> login(String username, String password) async {
    try {
      final response = await _httpClient.post(
        '/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      
      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String;
      
      // Save credentials
      await _secureStorage.saveUsername(username);
      await _secureStorage.saveToken(token);
      await _secureStorage.saveRefreshToken(refreshToken);
      
      return AuthToken(
        token: token,
        refreshToken: refreshToken,
      );
    } catch (e) {
      _logger.warning('Login failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<AuthToken> refreshToken(String refreshToken) async {
    try {
      final response = await _httpClient.post(
        '/refresh',
        data: {
          'refreshToken': refreshToken,
        },
      );
      
      final data = response.data as Map<String, dynamic>;
      
      final token = data['token'] as String;
      final newRefreshToken = data['refreshToken'] as String;
      
      // Save new tokens
      await _secureStorage.saveToken(token);
      await _secureStorage.saveRefreshToken(newRefreshToken);
      
      return AuthToken(
        token: token,
        refreshToken: newRefreshToken,
      );
    } catch (e) {
      _logger.warning('Token refresh failed: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> logout() async {
    try {
      // Try to notify server about logout
      await _httpClient.post('/logout');
    } catch (e) {
      _logger.warning('Server logout failed: $e');
      // Continue with local logout even if server logout fails
    }
    
    // Clear local credentials
    await _secureStorage.clearCredentials();
  }
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    return token != null;
  }
  
  @override
  Future<User> getCurrentUser() async {
    try {
      final response = await _httpClient.get('/me');
      final data = response.data as Map<String, dynamic>;
      
      return User(
        id: data['id'] as String,
        username: data['username'] as String,
        displayName: data['displayName'] as String? ?? data['username'] as String,
        email: data['email'] as String?,
        isAdmin: data['isAdmin'] as bool? ?? false,
        quotaBytes: data['quotaBytes'] as int? ?? 0,
        usedBytes: data['usedBytes'] as int? ?? 0,
      );
    } catch (e) {
      _logger.warning('Failed to get current user: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> setServerUrl(String url) async {
    // Ensure URL ends with a slash
    final normalizedUrl = url.endsWith('/') ? url : '$url/';
    
    await _secureStorage.saveServerUrl(normalizedUrl);
    _httpClient.setBaseUrl(normalizedUrl);
  }
  
  @override
  Future<String?> getServerUrl() async {
    return _secureStorage.getServerUrl();
  }
}