import 'package:dartz/dartz.dart';

import '../entities/sync_folder.dart';
import '../repositories/sync_repository.dart';

/// Get remote folders use case (for selective sync)
class GetRemoteFoldersUseCase {
  final SyncRepository _repository;

  GetRemoteFoldersUseCase(this._repository);

  Future<Either<SyncFailure, List<SyncFolder>>> call() async {
    return _repository.getRemoteFolders();
  }
}

/// Select folders to sync use case
class SelectFoldersUseCase {
  final SyncRepository _repository;

  SelectFoldersUseCase(this._repository);

  Future<Either<SyncFailure, void>> call(List<String> folderIds) async {
    return _repository.setSyncFolders(folderIds);
  }
}

/// Get selected folders use case
class GetSelectedFoldersUseCase {
  final SyncRepository _repository;

  GetSelectedFoldersUseCase(this._repository);

  Future<Either<SyncFailure, List<String>>> call() async {
    return _repository.getSyncFolders();
  }
}
