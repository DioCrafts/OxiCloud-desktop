import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/sync_folder.dart';
import '../../../core/entities/sync_status.dart';
import '../../../core/repositories/sync_repository.dart';

part 'sync_event.dart';
part 'sync_state.dart';

// ============================================================================
// BLOC
// ============================================================================

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final SyncRepository _syncRepository;
  StreamSubscription<SyncStatus>? _statusSubscription;

  SyncBloc(this._syncRepository) : super(const SyncInitial()) {
    on<SyncStarted>(_onSyncStarted);
    on<SyncStopped>(_onSyncStopped);
    on<SyncNowRequested>(_onSyncNowRequested);
    on<SyncStatusUpdated>(_onSyncStatusUpdated);
    on<LoadRemoteFolders>(_onLoadRemoteFolders);
    on<UpdateSyncFolders>(_onUpdateSyncFolders);
    on<LoadConflicts>(_onLoadConflicts);
    on<ResolveConflictRequested>(_onResolveConflict);

    _statusSubscription = _syncRepository.syncStatusStream.listen(
      (status) => add(SyncStatusUpdated(status)),
    );
  }

  Future<void> _onSyncStarted(
    SyncStarted event,
    Emitter<SyncState> emit,
  ) async {
    final result = await _syncRepository.startSync();

    result.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (_) => emit(const SyncInProgress(SyncStatus(
        isSyncing: true,
        progressPercent: 0,
        itemsSynced: 0,
        itemsTotal: 0,
      ))),
    );
  }

  Future<void> _onSyncStopped(
    SyncStopped event,
    Emitter<SyncState> emit,
  ) async {
    final result = await _syncRepository.stopSync();

    result.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (_) => emit(const SyncPaused()),
    );
  }

  Future<void> _onSyncNowRequested(
    SyncNowRequested event,
    Emitter<SyncState> emit,
  ) async {
    emit(const SyncInProgress(SyncStatus(
      isSyncing: true,
      currentOperation: 'Syncing...',
      progressPercent: 0,
      itemsSynced: 0,
      itemsTotal: 0,
    )));

    final result = await _syncRepository.syncNow();

    await result.fold(
      (failure) async {
        emit(SyncError(message: _mapFailure(failure)));
      },
      (syncResult) async {
        // Check for conflicts
        final conflictsResult = await _syncRepository.getConflicts();
        final conflicts = conflictsResult.fold(
          (_) => <SyncConflict>[],
          (c) => c,
        );

        emit(SyncIdle(
          lastStatus: SyncStatus(
            isSyncing: false,
            progressPercent: 100,
            itemsSynced: syncResult.itemsUploaded + syncResult.itemsDownloaded,
            itemsTotal: syncResult.itemsUploaded + syncResult.itemsDownloaded,
            lastSyncTime: DateTime.now(),
          ),
          conflicts: conflicts,
        ));
      },
    );
  }

  void _onSyncStatusUpdated(
    SyncStatusUpdated event,
    Emitter<SyncState> emit,
  ) {
    if (event.status.isSyncing) {
      emit(SyncInProgress(event.status));
    } else {
      emit(SyncIdle(lastStatus: event.status));
    }
  }

  Future<void> _onLoadRemoteFolders(
    LoadRemoteFolders event,
    Emitter<SyncState> emit,
  ) async {
    final foldersResult = await _syncRepository.getRemoteFolders();
    final selectedResult = await _syncRepository.getSyncFolders();

    foldersResult.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (folders) {
        final selected = selectedResult.fold(
          (_) => <String>[],
          (s) => s,
        );
        emit(RemoteFoldersLoaded(
          folders: folders,
          selectedFolderIds: selected,
        ));
      },
    );
  }

  Future<void> _onUpdateSyncFolders(
    UpdateSyncFolders event,
    Emitter<SyncState> emit,
  ) async {
    final result = await _syncRepository.setSyncFolders(event.folderIds);

    result.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (_) => add(const LoadRemoteFolders()),
    );
  }

  Future<void> _onLoadConflicts(
    LoadConflicts event,
    Emitter<SyncState> emit,
  ) async {
    final result = await _syncRepository.getConflicts();

    result.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (conflicts) => emit(ConflictsLoaded(conflicts)),
    );
  }

  Future<void> _onResolveConflict(
    ResolveConflictRequested event,
    Emitter<SyncState> emit,
  ) async {
    final result = await _syncRepository.resolveConflict(
      event.conflictId,
      event.resolution,
    );

    result.fold(
      (failure) => emit(SyncError(message: _mapFailure(failure))),
      (_) => add(const LoadConflicts()),
    );
  }

  String _mapFailure(SyncFailure failure) {
    if (failure is NetworkSyncFailure) {
      return 'Network error: ${failure.message}';
    } else if (failure is StorageSyncFailure) {
      return 'Storage error: ${failure.message}';
    } else if (failure is UnknownSyncFailure) {
      return 'Error: ${failure.message}';
    }
    return 'Unknown error';
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
