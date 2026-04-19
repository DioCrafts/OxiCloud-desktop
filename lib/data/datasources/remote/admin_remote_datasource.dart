import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

// --- DTOs ---

class AdminDashboard {
  final int totalUsers;
  final int activeUsers;
  final int totalFiles;
  final int totalFolders;
  final int totalStorageBytes;
  final String serverVersion;
  final String storageBackend;

  const AdminDashboard({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalFiles,
    required this.totalFolders,
    required this.totalStorageBytes,
    required this.serverVersion,
    required this.storageBackend,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    return AdminDashboard(
      totalUsers: json['total_users'] as int? ?? 0,
      activeUsers: json['active_users'] as int? ?? 0,
      totalFiles: json['total_files'] as int? ?? 0,
      totalFolders: json['total_folders'] as int? ?? 0,
      totalStorageBytes: json['total_storage_bytes'] as int? ?? 0,
      serverVersion: json['server_version'] as String? ?? 'unknown',
      storageBackend: json['storage_backend'] as String? ?? 'local',
    );
  }
}

class AdminUser {
  final String id;
  final String username;
  final String? email;
  final String role;
  final bool isActive;
  final int? quotaBytes;
  final int? usedBytes;
  final String createdAt;
  final String? lastLogin;

  const AdminUser({
    required this.id,
    required this.username,
    this.email,
    required this.role,
    required this.isActive,
    this.quotaBytes,
    this.usedBytes,
    required this.createdAt,
    this.lastLogin,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      quotaBytes: json['quota_bytes'] as int?,
      usedBytes: json['used_bytes'] as int?,
      createdAt: json['created_at'] as String,
      lastLogin: json['last_login'] as String?,
    );
  }
}

class OidcSettings {
  final bool enabled;
  final String? providerName;
  final String? clientId;
  final String? discoveryUrl;
  final bool autoRegister;
  final bool passwordLoginEnabled;

  const OidcSettings({
    required this.enabled,
    this.providerName,
    this.clientId,
    this.discoveryUrl,
    this.autoRegister = false,
    this.passwordLoginEnabled = true,
  });

  factory OidcSettings.fromJson(Map<String, dynamic> json) {
    return OidcSettings(
      enabled: json['enabled'] as bool? ?? false,
      providerName: json['provider_name'] as String?,
      clientId: json['client_id'] as String?,
      discoveryUrl: json['discovery_url'] as String?,
      autoRegister: json['auto_register'] as bool? ?? false,
      passwordLoginEnabled: json['password_login_enabled'] as bool? ?? true,
    );
  }
}

class StorageSettings {
  final String backend;
  final Map<String, dynamic>? config;

  const StorageSettings({required this.backend, this.config});

  factory StorageSettings.fromJson(Map<String, dynamic> json) {
    return StorageSettings(
      backend: json['backend'] as String,
      config: json['config'] as Map<String, dynamic>?,
    );
  }
}

class MigrationStatus {
  final String status; // idle, in_progress, paused, completed, failed
  final int totalFiles;
  final int migratedFiles;
  final int failedFiles;
  final double progressPercent;
  final String? error;

  const MigrationStatus({
    required this.status,
    required this.totalFiles,
    required this.migratedFiles,
    required this.failedFiles,
    required this.progressPercent,
    this.error,
  });

  factory MigrationStatus.fromJson(Map<String, dynamic> json) {
    return MigrationStatus(
      status: json['status'] as String? ?? 'idle',
      totalFiles: json['total_files'] as int? ?? 0,
      migratedFiles: json['migrated_files'] as int? ?? 0,
      failedFiles: json['failed_files'] as int? ?? 0,
      progressPercent:
          (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      error: json['error'] as String?,
    );
  }
}

// --- Datasource ---

class AdminRemoteDatasource {
  final Dio _dio;

  AdminRemoteDatasource(this._dio);

  // Dashboard
  Future<AdminDashboard> getDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminDashboard);
      return AdminDashboard.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Users
  Future<List<AdminUser>> getUsers() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminUsers);
      return (response.data as List<dynamic>)
          .map((e) => AdminUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AdminUser> getUser(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.adminUser(id));
      return AdminUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<AdminUser> createUser({
    required String username,
    required String password,
    String? email,
    String role = 'user',
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.adminUsers, data: {
        'username': username,
        'password': password,
        if (email != null) 'email': email,
        'role': role,
      });
      return AdminUser.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(ApiEndpoints.adminUser(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> setUserRole(String id, String role) async {
    try {
      await _dio.put(ApiEndpoints.adminUserRole(id), data: {'role': role});
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> setUserActive(String id, bool active) async {
    try {
      await _dio.put(ApiEndpoints.adminUserActive(id),
          data: {'active': active});
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> setUserQuota(String id, int? quotaBytes) async {
    try {
      await _dio.put(ApiEndpoints.adminUserQuota(id),
          data: {'quota_bytes': quotaBytes});
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> setUserPassword(String id, String password) async {
    try {
      await _dio.put(ApiEndpoints.adminUserPassword(id),
          data: {'password': password});
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Registration settings
  Future<Map<String, dynamic>> getRegistrationSettings() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminRegistration);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> updateRegistrationSettings(
      Map<String, dynamic> settings) async {
    try {
      await _dio.put(ApiEndpoints.adminRegistration, data: settings);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // OIDC settings
  Future<OidcSettings> getOidcSettings() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminOidc);
      return OidcSettings.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> updateOidcSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.put(ApiEndpoints.adminOidc, data: settings);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<Map<String, dynamic>> testOidcConnection() async {
    try {
      final response = await _dio.post(ApiEndpoints.adminOidcTest);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Storage settings
  Future<StorageSettings> getStorageSettings() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminStorage);
      return StorageSettings.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> updateStorageSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.put(ApiEndpoints.adminStorage, data: settings);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<Map<String, dynamic>> testStorageConnection() async {
    try {
      final response = await _dio.post(ApiEndpoints.adminStorageTest);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<String> generateEncryptionKey() async {
    try {
      final response =
          await _dio.post(ApiEndpoints.adminStorageGenerateKey);
      return response.data['key'] as String;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Migration
  Future<MigrationStatus> getMigrationStatus() async {
    try {
      final response = await _dio.get(ApiEndpoints.adminMigration);
      return MigrationStatus.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> startMigration(Map<String, dynamic> config) async {
    try {
      await _dio.post(ApiEndpoints.adminMigrationStart, data: config);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> pauseMigration() async {
    try {
      await _dio.post(ApiEndpoints.adminMigrationPause);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> resumeMigration() async {
    try {
      await _dio.post(ApiEndpoints.adminMigrationResume);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> completeMigration() async {
    try {
      await _dio.post(ApiEndpoints.adminMigrationComplete);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<Map<String, dynamic>> verifyMigration() async {
    try {
      final response = await _dio.post(ApiEndpoints.adminMigrationVerify);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Audio
  Future<void> reextractAudioMetadata() async {
    try {
      await _dio.post(ApiEndpoints.adminAudioReextract);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
