import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';

abstract class SyncRepository {
  Future<Either<Failure, void>> startBackgroundSync();
  Future<Either<Failure, void>> stopBackgroundSync();
  Future<Either<Failure, void>> syncNow();
  Future<Either<Failure, bool>> isSyncing();
  Future<Either<Failure, DateTime>> getLastSyncTime();
} 