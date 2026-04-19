import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';

class PhotosRemoteDatasource {
  final Dio _dio;

  PhotosRemoteDatasource(this._dio);

  /// Fetches media files (images/videos) sorted by capture date.
  /// Returns the file list and the cursor for the next page (or null).
  Future<({List<FileResponseDto> photos, int? nextCursor})> listPhotos({
    int? before,
    int limit = 200,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.photos,
        queryParameters: {'limit': limit, if (before != null) 'before': before},
      );
      final list = response.data as List<dynamic>;
      final photos = list
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();

      int? nextCursor;
      final cursorHeader = response.headers.value('X-Next-Cursor');
      if (cursorHeader != null) {
        nextCursor = int.tryParse(cursorHeader);
      }

      return (photos: photos, nextCursor: nextCursor);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
