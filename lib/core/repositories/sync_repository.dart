import 'package:dartz/dartz.dart';

import '../entities/sync_folder.dart';
import '../entities/sync_status.dart';

/// Sync repository interface (port)
abstract class SyncRepository {
  /// Start automatic synchronization
  Future<Either<SyncFailure, void>> startSync();

  /// Stop automatic synchronization
  Future<Either<SyncFailure, void>> stopSync();

  /// Trigger immediate sync
  Future<Either<SyncFailure, SyncResult>> syncNow();

  /// Get current sync status
  Future<Either<SyncFailure, SyncStatus>> getSyncStatus();

  /// Stream of sync status updates
  Stream<SyncStatus> get syncStatusStream;

  /// Get pending items
  Future<Either<SyncFailure, List<SyncItem>>> getPendingItems();

  /// Get sync history
  Future<Either<SyncFailure, List<SyncHistoryEntry>>> getSyncHistory(int limit);

  // ============================================================================
  // Selective Sync
  // ============================================================================

  /// Get available remote folders
  Future<Either<SyncFailure, List<SyncFolder>>> getRemoteFolders();

  /// Set folders to sync
  Future<Either<SyncFailure, void>> setSyncFolders(List<String> folderIds);

  /// Get currently selected sync folders
  Future<Either<SyncFailure, List<String>>> getSyncFolders();

  // ============================================================================
  // Conflicts
  // ============================================================================

  /// Get conflicts
  Future<Either<SyncFailure, List<SyncConflict>>> getConflicts();

  /// Resolve a conflict
  Future<Either<SyncFailure, void>> resolveConflict(
    String conflictId,
    ConflictResolution resolution,
  );

  // ============================================================================
  // Configuration
  // ============================================================================

  /// Get current sync configuration
  Future<Either<SyncFailure, SyncConfig>> getConfig();

  /// Update sync configuration
  Future<Either<SyncFailure, void>> updateConfig(SyncConfig config);
}

/// Sync failures
abstract class SyncFailure {
  final String message;
  const SyncFailure(this.message);
}

class NotInitializedFailure extends SyncFailure {
  const NotInitializedFailure() : super('Sync engine not initialized');
}

class NotAuthenticatedFailure extends SyncFailure {
  const NotAuthenticatedFailure() : super('Not authenticated');
}

class NetworkSyncFailure extends SyncFailure {
  const NetworkSyncFailure(String message) : super('Network error: $message');
}

class StorageSyncFailure extends SyncFailure {
  const StorageSyncFailure(String message) : super('Storage error: $message');
}

class UnknownSyncFailure extends SyncFailure {
  const UnknownSyncFailure(String message) : super(message);
}

/// Sync history entry
class SyncHistoryEntry {
  final String id;
  final DateTime timestamp;
  final String operation;
  final String itemPath;
  final SyncDirection direction;
  final SyncItemStatus status;
  final String? errorMessage;

  const SyncHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.operation,
    required this.itemPath,
    required this.direction,
    required this.status,
    this.errorMessage,
  });
}

/// Sync configuration
class SyncConfig {
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

  const SyncConfig({
    required this.syncFolder,
    this.syncIntervalSeconds = 300,
    this.maxUploadSpeedKbps = 0,
    this.maxDownloadSpeedKbps = 0,
    this.deltaSyncEnabled = true,
    this.pauseOnMetered = true,
    this.wifiOnly = false,
    this.watchFilesystem = true,
    this.ignorePatterns = const [],
    this.notificationsEnabled = true,
    this.launchAtStartup = false,
    this.minimizeToTray = true,
  });

  SyncConfig copyWith({
    String? syncFolder,
    int? syncIntervalSeconds,
    int? maxUploadSpeedKbps,
    int? maxDownloadSpeedKbps,
    bool? deltaSyncEnabled,
    bool? pauseOnMetered,
    bool? wifiOnly,
    bool? watchFilesystem,
    List<String>? ignorePatterns,
    bool? notificationsEnabled,
    bool? launchAtStartup,
    bool? minimizeToTray,
  }) {
    return SyncConfig(
      syncFolder: syncFolder ?? this.syncFolder,
      syncIntervalSeconds: syncIntervalSeconds ?? this.syncIntervalSeconds,
      maxUploadSpeedKbps: maxUploadSpeedKbps ?? this.maxUploadSpeedKbps,
      maxDownloadSpeedKbps: maxDownloadSpeedKbps ?? this.maxDownloadSpeedKbps,
      deltaSyncEnabled: deltaSyncEnabled ?? this.deltaSyncEnabled,
      pauseOnMetered: pauseOnMetered ?? this.pauseOnMetered,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      watchFilesystem: watchFilesystem ?? this.watchFilesystem,
      ignorePatterns: ignorePatterns ?? this.ignorePatterns,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
    );
  }
}
