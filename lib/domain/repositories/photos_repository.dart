import '../entities/file_entity.dart';

abstract class PhotosRepository {
  /// List media files (images/videos) sorted by capture date.
  /// Returns paginated results with a cursor for the next page.
  Future<({List<FileEntity> photos, int? nextCursor})> listPhotos({
    int? before,
    int limit = 200,
  });
}
