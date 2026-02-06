import 'package:equatable/equatable.dart';

/// Overall sync status
class SyncStatus extends Equatable {
  final bool isSyncing;
  final String? currentOperation;
  final double progressPercent;
  final int itemsSynced;
  final int itemsTotal;
  final DateTime? lastSyncTime;
  final DateTime? nextSyncTime;
  final int pendingUploads;
  final int pendingDownloads;
  final int conflicts;
  final int errors;

  const SyncStatus({
    required this.isSyncing,
    this.currentOperation,
    required this.progressPercent,
    required this.itemsSynced,
    required this.itemsTotal,
    this.lastSyncTime,
    this.nextSyncTime,
    this.pendingUploads = 0,
    this.pendingDownloads = 0,
    this.conflicts = 0,
    this.errors = 0,
  });

  /// Create initial/empty status
  factory SyncStatus.initial() {
    return const SyncStatus(
      isSyncing: false,
      progressPercent: 0,
      itemsSynced: 0,
      itemsTotal: 0,
    );
  }

  /// Whether there are pending operations
  bool get hasPending => pendingUploads > 0 || pendingDownloads > 0;

  /// Whether sync is healthy (no errors or conflicts)
  bool get isHealthy => errors == 0 && conflicts == 0;

  /// Status text for display
  String get statusText {
    if (isSyncing) {
      return currentOperation ?? 'Syncing...';
    }
    if (!isHealthy) {
      if (conflicts > 0) return '$conflicts conflict(s)';
      if (errors > 0) return '$errors error(s)';
    }
    if (hasPending) {
      return '${pendingUploads + pendingDownloads} pending';
    }
    return 'Up to date';
  }

  /// Last sync formatted
  String get lastSyncFormatted {
    if (lastSyncTime == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSyncTime!);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${lastSyncTime!.day}/${lastSyncTime!.month}/${lastSyncTime!.year}';
  }

  @override
  List<Object?> get props => [
        isSyncing,
        currentOperation,
        progressPercent,
        itemsSynced,
        itemsTotal,
        lastSyncTime,
        nextSyncTime,
        pendingUploads,
        pendingDownloads,
        conflicts,
        errors,
      ];
}

/// Sync result after a sync operation
class SyncResult extends Equatable {
  final bool success;
  final int itemsUploaded;
  final int itemsDownloaded;
  final int itemsDeleted;
  final int conflicts;
  final List<String> errors;
  final Duration duration;

  const SyncResult({
    required this.success,
    required this.itemsUploaded,
    required this.itemsDownloaded,
    required this.itemsDeleted,
    required this.conflicts,
    required this.errors,
    required this.duration,
  });

  /// Total items synced
  int get totalSynced => itemsUploaded + itemsDownloaded + itemsDeleted;

  /// Summary text
  String get summary {
    if (!success && errors.isNotEmpty) {
      return 'Sync failed: ${errors.first}';
    }

    final parts = <String>[];
    if (itemsUploaded > 0) parts.add('$itemsUploaded uploaded');
    if (itemsDownloaded > 0) parts.add('$itemsDownloaded downloaded');
    if (itemsDeleted > 0) parts.add('$itemsDeleted deleted');
    if (conflicts > 0) parts.add('$conflicts conflicts');

    if (parts.isEmpty) return 'Everything up to date';
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        success,
        itemsUploaded,
        itemsDownloaded,
        itemsDeleted,
        conflicts,
        errors,
        duration,
      ];
}

/// Sync conflict
class SyncConflict extends Equatable {
  final String id;
  final String itemPath;
  final DateTime localModified;
  final DateTime remoteModified;
  final int localSize;
  final int remoteSize;
  final ConflictType type;

  const SyncConflict({
    required this.id,
    required this.itemPath,
    required this.localModified,
    required this.remoteModified,
    required this.localSize,
    required this.remoteSize,
    required this.type,
  });

  /// File name from path
  String get fileName => itemPath.split('/').last;

  @override
  List<Object?> get props => [
        id,
        itemPath,
        localModified,
        remoteModified,
        localSize,
        remoteSize,
        type,
      ];
}

/// Conflict type
enum ConflictType {
  bothModified,
  deletedLocally,
  deletedRemotely,
  typeMismatch,
}

/// Conflict resolution choice
enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
  skip,
}
