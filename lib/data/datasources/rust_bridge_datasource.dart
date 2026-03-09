import 'dart:async';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:oxicloud_app/src/rust/api/oxicloud.dart' as rust;
import 'package:oxicloud_app/src/rust/domain/entities/auth.dart';
import 'package:oxicloud_app/src/rust/domain/entities/config.dart';
import 'package:oxicloud_app/src/rust/domain/entities/sync_item.dart' as domain;
import 'package:path_provider/path_provider.dart';

/// Data source that bridges Flutter with native Rust code via FFI.
/// Uses flutter_rust_bridge generated bindings.
class RustBridgeDataSource {
  final Logger _logger = Logger();
  bool _initialized = false;

  /// Initialize the Rust core
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationSupportDirectory();
      final syncFolder = await _getDefaultSyncFolder();
      final dbPath = '${appDir.path}/oxicloud.db';

      _logger
        ..i('Initializing Rust core')
        ..i('Database path: $dbPath')
        ..i('Sync folder: $syncFolder');

      await rust.initialize(
        config: SyncConfig(
          syncFolder: syncFolder,
          databasePath: dbPath,
          syncIntervalSeconds: 300,
          maxUploadSpeedKbps: 0,
          maxDownloadSpeedKbps: 0,
          deltaSyncEnabled: true,
          deltaSyncMinSize: BigInt.from(1048576),
          pauseOnMetered: true,
          wifiOnly: false,
          watchFilesystem: true,
          ignorePatterns: const [],
          notificationsEnabled: true,
          launchAtStartup: false,
          minimizeToTray: true,
        ),
      );

      _initialized = true;
      _logger.i('Rust core initialized successfully');
    } on Exception catch (e) {
      _logger.e('Failed to initialize Rust core: $e');
      rethrow;
    }
  }

  /// Shutdown the Rust core gracefully
  Future<void> shutdown() async {
    if (!_initialized) return;
    try {
      await rust.shutdown();
      _initialized = false;
    } on Exception catch (e) {
      _logger.e('Error during Rust core shutdown: $e');
    }
  }

  Future<String> _getDefaultSyncFolder() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return '${dir.path}/OxiCloud';
    } else {
      final home = Platform.environment['HOME'] ??
          Platform.environment['USERPROFILE'] ?? '.';
      return '$home/OxiCloud';
    }
  }

  // ===========================================================================
  // AUTHENTICATION
  // ===========================================================================

  Future<AuthResultDto> login(String serverUrl, String username, String password) async {
    _ensureInitialized();
    try {
      final result = await rust.login(
        serverUrl: serverUrl, username: username, password: password,
      );
      return AuthResultDto(
        success: result.success,
        userId: result.userId,
        username: result.username,
        accessToken: result.accessToken,
        serverInfo: _mapServerInfo(result.serverInfo),
      );
    } on Exception catch (e) {
      _logger.e('Login failed: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    _ensureInitialized();
    await rust.logout();
  }

  Future<bool> isLoggedIn() async {
    _ensureInitialized();
    try { return await rust.isLoggedIn(); } on Exception catch (_) { return false; }
  }

  Future<ServerInfoDto?> getServerInfo() async {
    _ensureInitialized();
    try {
      final info = await rust.getServerInfo();
      return info != null ? _mapServerInfo(info) : null;
    } on Exception catch (_) { return null; }
  }

  // ===========================================================================
  // SYNCHRONIZATION
  // ===========================================================================

  Future<void> startSync() async { _ensureInitialized(); await rust.startSync(); }
  Future<void> stopSync() async { _ensureInitialized(); await rust.stopSync(); }

  Future<SyncResultDto> syncNow() async {
    _ensureInitialized();
    final r = await rust.syncNow();
    return SyncResultDto(
      success: r.success, itemsUploaded: r.itemsUploaded,
      itemsDownloaded: r.itemsDownloaded, itemsDeleted: r.itemsDeleted,
      conflicts: r.conflicts, errors: r.errors,
      durationMs: r.durationMs.toInt(),
    );
  }

  Future<SyncStatusDto> getSyncStatus() async {
    _ensureInitialized();
    try {
      final s = await rust.getSyncStatus();
      return SyncStatusDto(
        isSyncing: s.isSyncing, currentOperation: s.currentOperation,
        progressPercent: s.progressPercent, itemsSynced: s.itemsSynced,
        itemsTotal: s.itemsTotal, lastSyncTime: s.lastSyncTime,
        nextSyncTime: s.nextSyncTime,
      );
    } on Exception catch (_) {
      return SyncStatusDto(isSyncing: false, progressPercent: 0, itemsSynced: 0, itemsTotal: 0);
    }
  }

  Future<List<RemoteFolderDto>> getRemoteFolders() async {
    _ensureInitialized();
    try {
      final folders = await rust.getRemoteFolders();
      return folders.map((f) => RemoteFolderDto(
        id: f.id, name: f.name, path: f.path,
        sizeBytes: f.sizeBytes.toInt(), itemCount: f.itemCount,
        isSelected: f.isSelected,
      )).toList();
    } on Exception catch (_) { return []; }
  }

  Future<void> setSyncFolders(List<String> ids) async {
    _ensureInitialized();
    await rust.setSyncFolders(folderIds: ids);
  }

  Future<List<String>> getSyncFolders() async {
    _ensureInitialized();
    try { return await rust.getSyncFolders(); } on Exception catch (_) { return []; }
  }

  Future<List<SyncConflictDto>> getConflicts() async {
    _ensureInitialized();
    try {
      final conflicts = await rust.getConflicts();
      return conflicts.map((c) => SyncConflictDto(
        id: c.id, itemPath: c.itemPath,
        localModified: c.localModified, remoteModified: c.remoteModified,
        localSize: c.localSize.toInt(), remoteSize: c.remoteSize.toInt(),
        conflictType: _mapConflictType(c.conflictType),
      )).toList();
    } on Exception catch (_) { return []; }
  }

  Future<void> resolveConflict(String conflictId, String resolution) async {
    _ensureInitialized();
    await rust.resolveConflict(
      conflictId: conflictId,
      resolution: _mapResolution(resolution),
    );
  }

  // ===========================================================================
  // PENDING ITEMS & HISTORY
  // ===========================================================================

  Future<List<SyncItemDto>> getPendingItems() async {
    _ensureInitialized();
    try {
      final items = await rust.getPendingItems();
      return items.map((i) => SyncItemDto(
        id: i.id,
        path: i.path,
        name: i.name,
        isDirectory: i.isDirectory,
        size: i.size.toInt(),
        status: _mapSyncStatus(i.status),
        direction: _mapSyncDirection(i.direction),
        localModified: i.localModified,
        remoteModified: i.remoteModified,
      )).toList();
    } on Exception catch (_) { return []; }
  }

  Future<List<SyncHistoryEntryDto>> getSyncHistory(int limit) async {
    _ensureInitialized();
    try {
      final entries = await rust.getSyncHistory(limit: limit);
      return entries.map((e) => SyncHistoryEntryDto(
        id: e.id,
        timestamp: e.timestamp,
        operation: e.operation,
        itemPath: e.itemPath,
        direction: e.direction,
        status: e.status,
        errorMessage: e.errorMessage,
      )).toList();
    } on Exception catch (_) { return []; }
  }

  String _mapSyncStatus(domain.SyncStatus status) {
    if (status is domain.SyncStatus_Synced) return 'synced';
    if (status is domain.SyncStatus_Pending) return 'pending';
    if (status is domain.SyncStatus_Syncing) return 'syncing';
    if (status is domain.SyncStatus_Conflict) return 'conflict';
    if (status is domain.SyncStatus_Error) return 'error';
    if (status is domain.SyncStatus_Ignored) return 'ignored';
    return 'pending';
  }

  String _mapSyncDirection(domain.SyncDirection direction) {
    switch (direction) {
      case domain.SyncDirection.upload: return 'upload';
      case domain.SyncDirection.download: return 'download';
      case domain.SyncDirection.none: return 'none';
    }
  }

  // ===========================================================================
  // CONFIGURATION
  // ===========================================================================

  Future<void> updateConfig(SyncConfigDto config) async {
    _ensureInitialized();
    final appDir = await getApplicationSupportDirectory();
    final dbPath = '${appDir.path}/oxicloud.db';
    await rust.updateConfig(
      config: SyncConfig(
        syncFolder: config.syncFolder,
        databasePath: dbPath,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        deltaSyncMinSize: BigInt.from(1048576),
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ),
    );
  }

  Future<SyncConfigDto> getConfig() async {
    _ensureInitialized();
    try {
      final c = await rust.getConfig();
      return SyncConfigDto(
        syncFolder: c.syncFolder,
        syncIntervalSeconds: c.syncIntervalSeconds,
        maxUploadSpeedKbps: c.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: c.maxDownloadSpeedKbps,
        deltaSyncEnabled: c.deltaSyncEnabled,
        pauseOnMetered: c.pauseOnMetered,
        wifiOnly: c.wifiOnly,
        watchFilesystem: c.watchFilesystem,
        ignorePatterns: c.ignorePatterns,
        notificationsEnabled: c.notificationsEnabled,
        launchAtStartup: c.launchAtStartup,
        minimizeToTray: c.minimizeToTray,
      );
    } on Exception catch (_) {
      return SyncConfigDto(
        syncFolder: await _getDefaultSyncFolder(),
        syncIntervalSeconds: 300, maxUploadSpeedKbps: 0, maxDownloadSpeedKbps: 0,
        deltaSyncEnabled: true, pauseOnMetered: true, wifiOnly: false,
        watchFilesystem: true, ignorePatterns: const [],
        notificationsEnabled: true, launchAtStartup: false, minimizeToTray: true,
      );
    }
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  void _ensureInitialized() {
    if (!_initialized) throw StateError('RustBridgeDataSource not initialized');
  }

  ServerInfoDto _mapServerInfo(ServerInfo info) => ServerInfoDto(
    url: info.url, version: info.version, name: info.name,
    webdavUrl: info.webdavUrl,
    quotaTotal: info.quotaTotal.toInt(), quotaUsed: info.quotaUsed.toInt(),
    supportsDeltaSync: info.supportsDeltaSync,
    supportsChunkedUpload: info.supportsChunkedUpload,
  );

  String _mapConflictType(domain.ConflictType type) {
    switch (type) {
      case domain.ConflictType.bothModified: return 'both_modified';
      case domain.ConflictType.deletedLocally: return 'deleted_locally';
      case domain.ConflictType.deletedRemotely: return 'deleted_remotely';
      case domain.ConflictType.typeMismatch: return 'type_mismatch';
    }
  }

  domain.ConflictResolution _mapResolution(String r) {
    switch (r) {
      case 'keep_local': return domain.ConflictResolution.keepLocal;
      case 'keep_remote': return domain.ConflictResolution.keepRemote;
      case 'keep_both': return domain.ConflictResolution.keepBoth;
      default: return domain.ConflictResolution.skip;
    }
  }
}

// =============================================================================
// DTOs
// =============================================================================

class AuthResultDto {
  AuthResultDto({
    required this.success,
    required this.userId,
    required this.username,
    required this.accessToken,
    required this.serverInfo,
  });

  final bool success;
  final String userId;
  final String username;
  final String accessToken;
  final ServerInfoDto serverInfo;
}

class ServerInfoDto {
  ServerInfoDto({
    required this.url,
    required this.version,
    required this.name,
    required this.webdavUrl,
    required this.quotaTotal,
    required this.quotaUsed,
    required this.supportsDeltaSync,
    required this.supportsChunkedUpload,
  });

  final String url;
  final String version;
  final String name;
  final String webdavUrl;
  final int quotaTotal;
  final int quotaUsed;
  final bool supportsDeltaSync;
  final bool supportsChunkedUpload;
}

class SyncStatusDto {
  SyncStatusDto({
    required this.isSyncing,
    required this.progressPercent,
    required this.itemsSynced,
    required this.itemsTotal,
    this.currentOperation,
    this.lastSyncTime,
    this.nextSyncTime,
  });

  final bool isSyncing;
  final String? currentOperation;
  final double progressPercent;
  final int itemsSynced;
  final int itemsTotal;
  final int? lastSyncTime;
  final int? nextSyncTime;
}

class SyncResultDto {
  SyncResultDto({
    required this.success,
    required this.itemsUploaded,
    required this.itemsDownloaded,
    required this.itemsDeleted,
    required this.conflicts,
    required this.errors,
    required this.durationMs,
  });

  final bool success;
  final int itemsUploaded;
  final int itemsDownloaded;
  final int itemsDeleted;
  final int conflicts;
  final int durationMs;
  final List<String> errors;
}

class RemoteFolderDto {
  RemoteFolderDto({
    required this.id,
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.itemCount,
    required this.isSelected,
  });

  final String id;
  final String name;
  final String path;
  final int sizeBytes;
  final int itemCount;
  final bool isSelected;
}

class SyncConflictDto {
  SyncConflictDto({
    required this.id,
    required this.itemPath,
    required this.conflictType,
    required this.localModified,
    required this.remoteModified,
    required this.localSize,
    required this.remoteSize,
  });

  final String id;
  final String itemPath;
  final String conflictType;
  final int localModified;
  final int remoteModified;
  final int localSize;
  final int remoteSize;
}

class SyncConfigDto {
  SyncConfigDto({
    required this.syncFolder,
    required this.syncIntervalSeconds,
    required this.maxUploadSpeedKbps,
    required this.maxDownloadSpeedKbps,
    required this.deltaSyncEnabled,
    required this.pauseOnMetered,
    required this.wifiOnly,
    required this.watchFilesystem,
    required this.ignorePatterns,
    required this.notificationsEnabled,
    required this.launchAtStartup,
    required this.minimizeToTray,
  });

  final String syncFolder;
  final int syncIntervalSeconds;
  final int maxUploadSpeedKbps;
  final int maxDownloadSpeedKbps;
  final bool deltaSyncEnabled;
  final bool pauseOnMetered;
  final bool wifiOnly;
  final bool watchFilesystem;
  final List<String> ignorePatterns;
  final bool notificationsEnabled;
  final bool launchAtStartup;
  final bool minimizeToTray;
}

class SyncItemDto {
  SyncItemDto({
    required this.id,
    required this.path,
    required this.name,
    required this.status,
    required this.direction,
    required this.isDirectory,
    required this.size,
    this.localModified,
    this.remoteModified,
  });

  final String id;
  final String path;
  final String name;
  final String status;
  final String direction;
  final bool isDirectory;
  final int size;
  final DateTime? localModified;
  final DateTime? remoteModified;
}

class SyncHistoryEntryDto {
  final String id, operation, itemPath, direction, status;
  final int timestamp;
  final String? errorMessage;
  SyncHistoryEntryDto({required this.id, required this.timestamp,
    required this.operation, required this.itemPath, required this.direction,
    required this.status, this.errorMessage});
}
