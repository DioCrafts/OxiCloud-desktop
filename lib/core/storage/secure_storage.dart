import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';

/// Secure storage for sensitive information
class SecureStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _serverUrlKey = 'server_url';
  static const String _usernameKey = 'username';
  
  final FlutterSecureStorage _storage;
  final Logger _logger = LoggingManager.getLogger('SecureStorage');
  
  /// Create a SecureStorage instance
  SecureStorage() : _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    mOptions: MacOsOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
    lOptions: LinuxOptions(
      encryptionAlgorithm: LinuxEncryptionAlgorithm.aes256Gcm,
    ),
    wOptions: WindowsOptions(
      useProtectedUserDataPath: true,
    ),
  );
  
  /// Save auth token
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (e) {
      _logger.severe('Failed to save auth token', e);
      rethrow;
    }
  }
  
  /// Get auth token
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      _logger.severe('Failed to get auth token', e);
      return null;
    }
  }
  
  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      _logger.severe('Failed to save refresh token', e);
      rethrow;
    }
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      _logger.severe('Failed to get refresh token', e);
      return null;
    }
  }
  
  /// Save server URL
  Future<void> saveServerUrl(String url) async {
    try {
      await _storage.write(key: _serverUrlKey, value: url);
    } catch (e) {
      _logger.severe('Failed to save server URL', e);
      rethrow;
    }
  }
  
  /// Get server URL
  Future<String?> getServerUrl() async {
    try {
      return await _storage.read(key: _serverUrlKey);
    } catch (e) {
      _logger.severe('Failed to get server URL', e);
      return null;
    }
  }
  
  /// Save username
  Future<void> saveUsername(String username) async {
    try {
      await _storage.write(key: _usernameKey, value: username);
    } catch (e) {
      _logger.severe('Failed to save username', e);
      rethrow;
    }
  }
  
  /// Get username
  Future<String?> getUsername() async {
    try {
      return await _storage.read(key: _usernameKey);
    } catch (e) {
      _logger.severe('Failed to get username', e);
      return null;
    }
  }
  
  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshTokenKey);
      await _storage.delete(key: _usernameKey);
      // Don't clear server URL as it's a configuration setting
    } catch (e) {
      _logger.severe('Failed to clear credentials', e);
      rethrow;
    }
  }
  
  /// Clear everything in secure storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      _logger.severe('Failed to clear all secure storage', e);
      rethrow;
    }
  }
}