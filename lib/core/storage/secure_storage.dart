import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/storage/linux_secure_storage.dart';

/// Secure storage for sensitive information
class SecureStorage {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _serverUrlKey = 'server_url';
  static const String _usernameKey = 'username';
  
  final FlutterSecureStorage? _storage;
  final LinuxSecureStorage? _linuxStorage;
  final Logger _logger = LoggingManager.getLogger('SecureStorage');
  final bool _useLinuxFallback;
  bool _isInitialized = false;
  
  /// Create a SecureStorage instance
  SecureStorage() : 
    _useLinuxFallback = Platform.isLinux,
    _storage = Platform.isLinux ? null : const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock,
      ),
      wOptions: WindowsOptions(),
    ),
    _linuxStorage = Platform.isLinux ? LinuxSecureStorage() : null;
  
  /// Initialize storage
  Future<void> initialize() async {
    if (_useLinuxFallback && _linuxStorage != null && !_isInitialized) {
      await _linuxStorage!.initialize();
      _isInitialized = true;
      _logger.info('Using Linux fallback secure storage');
    }
  }
  
  /// Ensure initialization before any operation
  Future<void> _ensureInitialized() async {
    if (_useLinuxFallback && !_isInitialized) {
      await initialize();
    }
  }
  
  /// Save auth token
  Future<void> saveToken(String token) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: _tokenKey, value: token);
      } else {
        await _storage?.write(key: _tokenKey, value: token);
      }
    } catch (e) {
      _logger.severe('Failed to save auth token', e);
      rethrow;
    }
  }
  
  /// Get auth token
  Future<String?> getToken() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        return await _linuxStorage?.read(key: _tokenKey);
      } else {
        return await _storage?.read(key: _tokenKey);
      }
    } catch (e) {
      _logger.severe('Failed to get auth token', e);
      return null;
    }
  }
  
  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: _refreshTokenKey, value: token);
      } else {
        await _storage?.write(key: _refreshTokenKey, value: token);
      }
    } catch (e) {
      _logger.severe('Failed to save refresh token', e);
      rethrow;
    }
  }
  
  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        return await _linuxStorage?.read(key: _refreshTokenKey);
      } else {
        return await _storage?.read(key: _refreshTokenKey);
      }
    } catch (e) {
      _logger.severe('Failed to get refresh token', e);
      return null;
    }
  }
  
  /// Save server URL
  Future<void> saveServerUrl(String url) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: _serverUrlKey, value: url);
      } else {
        await _storage?.write(key: _serverUrlKey, value: url);
      }
    } catch (e) {
      _logger.severe('Failed to save server URL', e);
      rethrow;
    }
  }
  
  /// Get server URL
  Future<String?> getServerUrl() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        return await _linuxStorage?.read(key: _serverUrlKey);
      } else {
        return await _storage?.read(key: _serverUrlKey);
      }
    } catch (e) {
      _logger.severe('Failed to get server URL', e);
      return null;
    }
  }
  
  /// Save username
  Future<void> saveUsername(String username) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: _usernameKey, value: username);
      } else {
        await _storage?.write(key: _usernameKey, value: username);
      }
    } catch (e) {
      _logger.severe('Failed to save username', e);
      rethrow;
    }
  }
  
  /// Get username
  Future<String?> getUsername() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        return await _linuxStorage?.read(key: _usernameKey);
      } else {
        return await _storage?.read(key: _usernameKey);
      }
    } catch (e) {
      _logger.severe('Failed to get username', e);
      return null;
    }
  }
  
  /// Clear all stored credentials
  Future<void> clearCredentials() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.delete(key: _tokenKey);
        await _linuxStorage?.delete(key: _refreshTokenKey);
        await _linuxStorage?.delete(key: _usernameKey);
      } else {
        await _storage?.delete(key: _tokenKey);
        await _storage?.delete(key: _refreshTokenKey);
        await _storage?.delete(key: _usernameKey);
      }
      // Don't clear server URL as it's a configuration setting
    } catch (e) {
      _logger.severe('Failed to clear credentials', e);
      rethrow;
    }
  }
  
  /// Clear everything in secure storage
  Future<void> clearAll() async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.deleteAll();
      } else {
        await _storage?.deleteAll();
      }
    } catch (e) {
      _logger.severe('Failed to clear all secure storage', e);
      rethrow;
    }
  }
  
  /// Get a boolean value
  Future<bool?> getBool(String key) async {
    try {
      await _ensureInitialized();
      String? value;
      if (_useLinuxFallback) {
        value = await _linuxStorage?.read(key: key);
      } else {
        value = await _storage?.read(key: key);
      }
      if (value == null) return null;
      return value.toLowerCase() == 'true';
    } catch (e) {
      _logger.severe('Failed to get boolean value for key: $key', e);
      return null;
    }
  }
  
  /// Set a boolean value
  Future<void> setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: key, value: value.toString());
      } else {
        await _storage?.write(key: key, value: value.toString());
      }
    } catch (e) {
      _logger.severe('Failed to set boolean value for key: $key', e);
      rethrow;
    }
  }
  
  /// Get a string value
  Future<String?> getString(String key) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        return await _linuxStorage?.read(key: key);
      } else {
        return await _storage?.read(key: key);
      }
    } catch (e) {
      _logger.severe('Failed to get string value for key: $key', e);
      return null;
    }
  }
  
  /// Set a string value
  Future<void> setString(String key, String value) async {
    try {
      await _ensureInitialized();
      if (_useLinuxFallback) {
        await _linuxStorage?.write(key: key, value: value);
      } else {
        await _storage?.write(key: key, value: value);
      }
    } catch (e) {
      _logger.severe('Failed to set string value for key: $key', e);
      rethrow;
    }
  }
}