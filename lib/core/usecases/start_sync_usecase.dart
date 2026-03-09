import 'package:dartz/dartz.dart';

import '../entities/sync_status.dart';
import '../repositories/sync_repository.dart';

/// Start sync use case
class StartSyncUseCase {
  StartSyncUseCase(this._repository);

  final SyncRepository _repository;

  Future<Either<SyncFailure, void>> call() async {
    return _repository.startSync();
  }
}

/// Stop sync use case
class StopSyncUseCase {
  StopSyncUseCase(this._repository);

  final SyncRepository _repository;

  Future<Either<SyncFailure, void>> call() async {
    return _repository.stopSync();
  }
}

/// Sync now use case
class SyncNowUseCase {
  SyncNowUseCase(this._repository);

  final SyncRepository _repository;

  Future<Either<SyncFailure, SyncResult>> call() async {
    return _repository.syncNow();
  }
}

/// Get sync status use case
class GetSyncStatusUseCase {
  GetSyncStatusUseCase(this._repository);

  final SyncRepository _repository;

  Future<Either<SyncFailure, SyncStatus>> call() async {
    return _repository.getSyncStatus();
  }

  /// Stream of sync status updates
  Stream<SyncStatus> get statusStream => _repository.syncStatusStream;
}
