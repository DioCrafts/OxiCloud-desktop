import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/core/usecases/usecase.dart';
import 'package:oxicloud_desktop_client/features/files/domain/models/file.dart';
import 'package:oxicloud_desktop_client/features/files/domain/ports/file_repository.dart';

class UploadFileUseCase implements UseCase<File, UploadFileParams> {
  final FileRepository repository;

  UploadFileUseCase(this.repository);

  @override
  Future<Either<Failure, File>> call(UploadFileParams params) async {
    return await repository.uploadFile(
      filePath: params.filePath,
      parentId: params.parentId,
      onProgress: params.onProgress,
    );
  }
}

class UploadFileParams {
  final String filePath;
  final String? parentId;
  final Function(double)? onProgress;

  UploadFileParams({
    required this.filePath,
    this.parentId,
    this.onProgress,
  });
} 