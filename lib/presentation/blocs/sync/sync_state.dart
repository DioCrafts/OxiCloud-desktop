part of 'sync_bloc.dart';

// ============================================================================
// SYNC STATES
// ============================================================================

abstract class SyncState extends Equatable {
  const SyncState();

  @override
  List<Object?> get props => [];
}

class SyncInitial extends SyncState {
  const SyncInitial();
}

class SyncIdle extends SyncState {
  final SyncStatus? lastStatus;
  final List<SyncConflict> conflicts;

  const SyncIdle({this.lastStatus, this.conflicts = const []});

  @override
  List<Object?> get props => [lastStatus, conflicts];
}

class SyncInProgress extends SyncState {
  final SyncStatus status;

  const SyncInProgress(this.status);

  @override
  List<Object?> get props => [status];
}

class SyncPaused extends SyncState {
  final SyncStatus? lastStatus;

  const SyncPaused({this.lastStatus});

  @override
  List<Object?> get props => [lastStatus];
}

class SyncError extends SyncState {
  final String message;
  final SyncStatus? lastStatus;

  const SyncError({required this.message, this.lastStatus});

  @override
  List<Object?> get props => [message, lastStatus];
}

class RemoteFoldersLoaded extends SyncState {
  final List<SyncFolder> folders;
  final List<String> selectedFolderIds;

  const RemoteFoldersLoaded({
    required this.folders,
    required this.selectedFolderIds,
  });

  @override
  List<Object?> get props => [folders, selectedFolderIds];
}

class ConflictsLoaded extends SyncState {
  final List<SyncConflict> conflicts;

  const ConflictsLoaded(this.conflicts);

  @override
  List<Object?> get props => [conflicts];
}
