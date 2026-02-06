import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../core/entities/sync_folder.dart';
import '../../core/entities/sync_status.dart';
import '../../core/repositories/sync_repository.dart';
import '../datasources/rust_bridge_datasource.dart';

/// Implementation of SyncRepository
class SyncRepositoryImpl implements SyncRepository {
  final RustBridgeDataSource _rustDataSource;
  final _statusController = StreamController<SyncStatus>.broadcast();
  Timer? _statusPollingTimer;

  SyncRepositoryImpl(this._rustDataSource);

  @override
  Future<Either<SyncFailure, void>> startSync() async {
    try {
      await _rustDataSource.startSync();
      _startStatusPolling();
      return const Right(null);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, void>> stopSync() async {
    try {
      await _rustDataSource.stopSync();
      _stopStatusPolling();
      return const Right(null);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, SyncResult>> syncNow() async {
    try {
      final result = await _rustDataSource.syncNow();
      
      return Right(SyncResult(
        success: result.success,
        itemsUploaded: result.itemsUploaded,
        itemsDownloaded: result.itemsDownloaded,
        itemsDeleted: result.itemsDeleted,
        conflicts: result.conflicts,
        errors: result.errors,
        duration: Duration(milliseconds: result.durationMs),
      ));
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, SyncStatus>> getSyncStatus() async {
    try {
      final status = await _rustDataSource.getSyncStatus();
      
      return Right(SyncStatus(
        isSyncing: status.isSyncing,
        currentOperation: status.currentOperation,
        progressPercent: status.progressPercent,
        itemsSynced: status.itemsSynced,
        itemsTotal: status.itemsTotal,
        lastSyncTime: status.lastSyncTime != null 
            ? DateTime.fromMillisecondsSinceEpoch(status.lastSyncTime! * 1000)
            : null,
        nextSyncTime: status.nextSyncTime != null 
            ? DateTime.fromMillisecondsSinceEpoch(status.nextSyncTime! * 1000)
            : null,
      ));
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Stream<SyncStatus> get syncStatusStream => _statusController.stream;

  @override
  Future<Either<SyncFailure, List<SyncItem>>> getPendingItems() async {
    // TODO: Implement when Rust bindings are ready
    return const Right([]);
  }

  @override
  Future<Either<SyncFailure, List<SyncHistoryEntry>>> getSyncHistory(int limit) async {
    // TODO: Implement when Rust bindings are ready
    return const Right([]);
  }

  @override
  Future<Either<SyncFailure, List<SyncFolder>>> getRemoteFolders() async {
    try {
      final folders = await _rustDataSource.getRemoteFolders();
      
      return Right(folders.map((f) => SyncFolder(
        id: f.id,
        name: f.name,
        path: f.path,
        sizeBytes: f.sizeBytes,
        itemCount: f.itemCount,
        isSelected: f.isSelected,
      )).toList());
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, void>> setSyncFolders(List<String> folderIds) async {
    try {
      await _rustDataSource.setSyncFolders(folderIds);
      return const Right(null);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, List<String>>> getSyncFolders() async {
    try {
      final folders = await _rustDataSource.getSyncFolders();
      return Right(folders);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, List<SyncConflict>>> getConflicts() async {
    try {
      final conflicts = await _rustDataSource.getConflicts();
      
      return Right(conflicts.map((c) => SyncConflict(
        id: c.id,
        itemPath: c.itemPath,
        localModified: DateTime.fromMillisecondsSinceEpoch(c.localModified * 1000),
        remoteModified: DateTime.fromMillisecondsSinceEpoch(c.remoteModified * 1000),
        localSize: c.localSize,
        remoteSize: c.remoteSize,
        type: _parseConflictType(c.conflictType),
      )).toList());
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, void>> resolveConflict(
    String conflictId,
    ConflictResolution resolution,
  ) async {
    try {
      await _rustDataSource.resolveConflict(
        conflictId,
        _serializeResolution(resolution),
      );
      return const Right(null);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, SyncConfig>> getConfig() async {
    try {
      final config = await _rustDataSource.getConfig();
      
      return Right(SyncConfig(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ));
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  @override
  Future<Either<SyncFailure, void>> updateConfig(SyncConfig config) async {
    try {
      await _rustDataSource.updateConfig(SyncConfigDto(
        syncFolder: config.syncFolder,
        syncIntervalSeconds: config.syncIntervalSeconds,
        maxUploadSpeedKbps: config.maxUploadSpeedKbps,
        maxDownloadSpeedKbps: config.maxDownloadSpeedKbps,
        deltaSyncEnabled: config.deltaSyncEnabled,
        pauseOnMetered: config.pauseOnMetered,
        wifiOnly: config.wifiOnly,
        watchFilesystem: config.watchFilesystem,
        ignorePatterns: config.ignorePatterns,
        notificationsEnabled: config.notificationsEnabled,
        launchAtStartup: config.launchAtStartup,
        minimizeToTray: config.minimizeToTray,
      ));
      return const Right(null);
    } catch (e) {
      return Left(UnknownSyncFailure(e.toString()));
    }
  }

  // ============================================================================
  // PRIVATE HELPERS
  // ============================================================================

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) async {
        final result = await getSyncStatus();
        result.fold(
          (failure) {},
          (status) => _statusController.add(status),
        );
      },
    );
  }

  void _stopStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = null;
  }

  ConflictType _parseConflictType(String type) {
    switch (type) {
      case 'BothModified':
        return ConflictType.bothModified;
      case 'DeletedLocally':
        return ConflictType.deletedLocally;
      case 'DeletedRemotely':
        return ConflictType.deletedRemotely;
      case 'TypeMismatch':
        return ConflictType.typeMismatch;
      default:
        return ConflictType.bothModified;
    }
  }

  String _serializeResolution(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'KeepLocal';
      case ConflictResolution.keepRemote:
        return 'KeepRemote';
      case ConflictResolution.keepBoth:
        return 'KeepBoth';
      case ConflictResolution.skip:
        return 'Skip';
    }
  }

  void dispose() {
    _stopStatusPolling();
    _statusController.close();
  }
}
