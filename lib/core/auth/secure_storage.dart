import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  // Tokens
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: Constants.keyAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: Constants.keyAccessToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: Constants.keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: Constants.keyRefreshToken);

  Future<void> saveTokenExpiry(DateTime expiry) => _storage.write(
    key: Constants.keyTokenExpiry,
    value: expiry.toIso8601String(),
  );

  Future<DateTime?> getTokenExpiry() async {
    final raw = await _storage.read(key: Constants.keyTokenExpiry);
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  // Server
  Future<void> saveServerUrl(String url) =>
      _storage.write(key: Constants.keyServerUrl, value: url);

  Future<String?> getServerUrl() => _storage.read(key: Constants.keyServerUrl);

  // User
  Future<void> saveUserId(String id) =>
      _storage.write(key: Constants.keyUserId, value: id);

  Future<String?> getUserId() => _storage.read(key: Constants.keyUserId);

  // Session management
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    if (token == null) return false;
    final expiry = await getTokenExpiry();
    if (expiry == null) return true; // assume valid if no expiry stored
    return expiry.isAfter(DateTime.now());
  }

  Future<void> clearSession() async {
    await _storage.delete(key: Constants.keyAccessToken);
    await _storage.delete(key: Constants.keyRefreshToken);
    await _storage.delete(key: Constants.keyTokenExpiry);
    await _storage.delete(key: Constants.keyUserId);
  }

  Future<void> clearAll() => _storage.deleteAll();
}
