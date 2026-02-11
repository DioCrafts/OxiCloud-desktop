import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/entities/user.dart';
import '../../core/repositories/auth_repository.dart';
import '../datasources/api_client.dart';
import '../datasources/rust_bridge_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final RustBridgeDataSource _rustDataSource;
  final ApiClient? _apiClient;
  static const _serverUrlKey = 'server_url';
  static const _usernameKey = 'username';
  static const _passwordKey = 'password';
  static const _accessTokenKey = 'access_token';

  AuthRepositoryImpl(this._rustDataSource, [this._apiClient]);

  @override
  Future<Either<AuthFailure, User>> login(AuthCredentials credentials) async {
    try {
      final result = await _rustDataSource.login(
        credentials.serverUrl,
        credentials.username,
        credentials.password,
      );

      if (!result.success) {
        return const Left(InvalidCredentialsFailure());
      }

      // Store credentials for auto-login + API token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlKey, credentials.serverUrl);
      await prefs.setString(_usernameKey, credentials.username);
      await prefs.setString(_passwordKey, credentials.password);
      await prefs.setString(_accessTokenKey, result.accessToken);

      // Configure the HTTP API client with the token
      _apiClient?.updateCredentials(credentials.serverUrl, result.accessToken);

      final user = User(
        id: result.userId,
        username: result.username,
        serverUrl: credentials.serverUrl,
        serverInfo: ServerInfo(
          url: result.serverInfo.url,
          version: result.serverInfo.version,
          name: result.serverInfo.name,
          webdavUrl: result.serverInfo.webdavUrl,
          quotaTotal: result.serverInfo.quotaTotal,
          quotaUsed: result.serverInfo.quotaUsed,
          supportsDeltaSync: result.serverInfo.supportsDeltaSync,
          supportsChunkedUpload: result.serverInfo.supportsChunkedUpload,
        ),
      );

      return Right(user);
    } catch (e) {
      if (e.toString().contains('Network') || 
          e.toString().contains('Connection')) {
        return Left(ServerUnreachableFailure(e.toString()));
      }
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      await _rustDataSource.logout();
      return const Right(null);
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, bool>> isLoggedIn() async {
    try {
      final result = await _rustDataSource.isLoggedIn();
      return Right(result);
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, User?>> getCurrentUser() async {
    try {
      final serverInfo = await _rustDataSource.getServerInfo();
      if (serverInfo == null) {
        return const Right(null);
      }

      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString(_usernameKey) ?? '';

      final user = User(
        id: 'current-user',
        username: username,
        serverUrl: serverInfo.url,
        serverInfo: ServerInfo(
          url: serverInfo.url,
          version: serverInfo.version,
          name: serverInfo.name,
          webdavUrl: serverInfo.webdavUrl,
          quotaTotal: serverInfo.quotaTotal,
          quotaUsed: serverInfo.quotaUsed,
          supportsDeltaSync: serverInfo.supportsDeltaSync,
          supportsChunkedUpload: serverInfo.supportsChunkedUpload,
        ),
      );

      return Right(user);
    } catch (e) {
      return Left(UnknownAuthFailure(e.toString()));
    }
  }

  @override
  Future<String?> getStoredServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverUrlKey);
  }

  @override
  Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }
}
