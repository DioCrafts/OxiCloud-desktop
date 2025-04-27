import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/core/usecases/usecase.dart';
import 'package:oxicloud_desktop_client/features/files/domain/ports/file_repository.dart';

class TrashItemUseCase implements UseCase<void, TrashItemParams> {
  final FileRepository repository;

  TrashItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(TrashItemParams params) async {
    return await repository.trashItem(
      params.id,
      params.isFile,
    );
  }
}

class TrashItemParams {
  final String id;
  final bool isFile;

  TrashItemParams({
    required this.id,
    required this.isFile,
  });
} 