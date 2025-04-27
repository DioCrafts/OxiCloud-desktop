import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/core/usecases/usecase.dart';
import 'package:oxicloud_desktop_client/features/sync/domain/ports/sync_repository.dart';

class StartBackgroundSyncUseCase implements UseCase<void, NoParams> {
  final SyncRepository repository;

  StartBackgroundSyncUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.startBackgroundSync();
  }
} 