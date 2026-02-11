import '../../core/entities/sync_folder.dart';
import '../../core/entities/sync_status.dart';
import '../../core/repositories/sync_repository.dart';
import '../datasources/rust_bridge_datasource.dart';

/// Mappers between Sync DTOs (data layer) and domain entities.
///
/// Centralizes conversion logic that was previously scattered
/// across repository implementations.
class SyncMapper {
  const SyncMapper._();

  /// Maps [SyncStatusDto] → domain [SyncStatus]
  static SyncStatus fromSyncStatusDto(SyncStatusDto dto) {
    return SyncStatus(
      isSyncing: dto.isSyncing,
      currentOperation: dto.currentOperation,
      progressPercent: dto.progressPercent,
      itemsSynced: dto.itemsSynced,
      itemsTotal: dto.itemsTotal,
      lastSyncTime: dto.lastSyncTime != null
          ? DateTime.fromMillisecondsSinceEpoch(dto.lastSyncTime!)
          : null,
      nextSyncTime: dto.nextSyncTime != null
          ? DateTime.fromMillisecondsSinceEpoch(dto.nextSyncTime!)
          : null,
    );
  }

  /// Maps [SyncResultDto] → domain [SyncResult]
  static SyncResult fromSyncResultDto(SyncResultDto dto) {
    return SyncResult(
      success: dto.success,
      itemsUploaded: dto.itemsUploaded,
      itemsDownloaded: dto.itemsDownloaded,
      itemsDeleted: dto.itemsDeleted,
      conflicts: dto.conflicts,
      errors: dto.errors,
      duration: Duration(milliseconds: dto.durationMs),
    );
  }

  /// Maps [RemoteFolderDto] → domain [SyncFolder]
  static SyncFolder fromRemoteFolderDto(RemoteFolderDto dto) {
    return SyncFolder(
      id: dto.id,
      name: dto.name,
      path: dto.path,
      sizeBytes: dto.sizeBytes,
      itemCount: dto.itemCount,
      isSelected: dto.isSelected,
    );
  }

  /// Maps list of [RemoteFolderDto] → list of domain [SyncFolder]
  static List<SyncFolder> fromRemoteFolderDtoList(List<RemoteFolderDto> dtos) {
    return dtos.map(fromRemoteFolderDto).toList();
  }

  /// Maps [SyncConflictDto] → domain [SyncConflict]
  static SyncConflict fromSyncConflictDto(SyncConflictDto dto) {
    return SyncConflict(
      id: dto.id,
      itemPath: dto.itemPath,
      localModified: DateTime.fromMillisecondsSinceEpoch(dto.localModified),
      remoteModified: DateTime.fromMillisecondsSinceEpoch(dto.remoteModified),
      localSize: dto.localSize,
      remoteSize: dto.remoteSize,
      type: _mapConflictType(dto.conflictType),
    );
  }

  /// Maps [SyncConfigDto] → domain [SyncConfig]
  static SyncConfig fromSyncConfigDto(SyncConfigDto dto) {
    return SyncConfig(
      syncFolder: dto.syncFolder,
      syncIntervalSeconds: dto.syncIntervalSeconds,
      maxUploadSpeedKbps: dto.maxUploadSpeedKbps,
      maxDownloadSpeedKbps: dto.maxDownloadSpeedKbps,
      deltaSyncEnabled: dto.deltaSyncEnabled,
      pauseOnMetered: dto.pauseOnMetered,
      wifiOnly: dto.wifiOnly,
      watchFilesystem: dto.watchFilesystem,
      ignorePatterns: dto.ignorePatterns,
      notificationsEnabled: dto.notificationsEnabled,
      launchAtStartup: dto.launchAtStartup,
      minimizeToTray: dto.minimizeToTray,
    );
  }

  /// Maps domain [SyncConfig] → [SyncConfigDto]
  static SyncConfigDto toSyncConfigDto(SyncConfig config) {
    return SyncConfigDto(
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
    );
  }

  /// Maps domain [ConflictResolution] → string for Rust bridge
  static String conflictResolutionToString(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'keep_local';
      case ConflictResolution.keepRemote:
        return 'keep_remote';
      case ConflictResolution.keepBoth:
        return 'keep_both';
      case ConflictResolution.skip:
        return 'skip';
    }
  }

  static ConflictType _mapConflictType(String type) {
    switch (type) {
      case 'both_modified':
        return ConflictType.bothModified;
      case 'deleted_locally':
        return ConflictType.deletedLocally;
      case 'deleted_remotely':
        return ConflictType.deletedRemotely;
      case 'type_mismatch':
        return ConflictType.typeMismatch;
      default:
        return ConflictType.bothModified;
    }
  }
}
