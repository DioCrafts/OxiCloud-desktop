import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';

class FavoritesRemoteDatasource {
  final Dio _dio;

  FavoritesRemoteDatasource(this._dio);

  Future<List<FileResponseDto>> listFavorites() async {
    try {
      final response = await _dio.get(ApiEndpoints.favorites);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> addFavorite(String itemType, String itemId) async {
    try {
      await _dio.post(ApiEndpoints.favorite(itemType, itemId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> removeFavorite(String itemType, String itemId) async {
    try {
      await _dio.delete(ApiEndpoints.favorite(itemType, itemId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> batchAddFavorites(
      List<({String itemType, String itemId})> items) async {
    try {
      await _dio.post(
        ApiEndpoints.favoritesBatch,
        data: items
            .map((i) => {'item_type': i.itemType, 'item_id': i.itemId})
            .toList(),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
