import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/photos_repository.dart';
import '../datasources/remote/photos_remote_datasource.dart';
import '../mappers/file_mapper.dart';

class PhotosRepositoryImpl implements PhotosRepository {
  final PhotosRemoteDatasource _remote;

  PhotosRepositoryImpl({required PhotosRemoteDatasource remote})
      : _remote = remote;

  @override
  Future<({List<FileEntity> photos, int? nextCursor})> listPhotos({
    int? before,
    int limit = 200,
  }) async {
    final result = await _remote.listPhotos(before: before, limit: limit);
    final photos = FileMapper.fromDtoList(result.photos);
    return (photos: photos, nextCursor: result.nextCursor);
  }
}
