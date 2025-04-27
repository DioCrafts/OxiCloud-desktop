import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/core/usecases/usecase.dart';
import 'package:oxicloud_desktop_client/features/files/domain/ports/file_repository.dart';

class ShareItemUseCase implements UseCase<void, ShareItemParams> {
  final FileRepository repository;

  ShareItemUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ShareItemParams params) async {
    return await repository.shareItem(
      params.id,
      params.emails,
    );
  }
}

class ShareItemParams {
  final String id;
  final List<String> emails;

  ShareItemParams({
    required this.id,
    required this.emails,
  });
} 