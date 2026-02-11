part of 'sync_bloc.dart';

// ============================================================================
// SYNC EVENTS
// ============================================================================

abstract class SyncEvent extends Equatable {
  const SyncEvent();

  @override
  List<Object?> get props => [];
}

class SyncStarted extends SyncEvent {
  const SyncStarted();
}

class SyncStopped extends SyncEvent {
  const SyncStopped();
}

class SyncNowRequested extends SyncEvent {
  const SyncNowRequested();
}

class SyncStatusUpdated extends SyncEvent {
  final SyncStatus status;

  const SyncStatusUpdated(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadRemoteFolders extends SyncEvent {
  const LoadRemoteFolders();
}

class UpdateSyncFolders extends SyncEvent {
  final List<String> folderIds;

  const UpdateSyncFolders(this.folderIds);

  @override
  List<Object?> get props => [folderIds];
}

class LoadConflicts extends SyncEvent {
  const LoadConflicts();
}

class ResolveConflictRequested extends SyncEvent {
  final String conflictId;
  final ConflictResolution resolution;

  const ResolveConflictRequested({
    required this.conflictId,
    required this.resolution,
  });

  @override
  List<Object?> get props => [conflictId, resolution];
}
