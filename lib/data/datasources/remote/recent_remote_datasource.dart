import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';

class RecentRemoteDatasource {
  final Dio _dio;

  RecentRemoteDatasource(this._dio);

  Future<List<FileResponseDto>> listRecent() async {
    try {
      final response = await _dio.get(ApiEndpoints.recent);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> recordAccess(String itemType, String itemId) async {
    try {
      await _dio.post(ApiEndpoints.recentItem(itemType, itemId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> clearRecent() async {
    try {
      await _dio.delete(ApiEndpoints.recentClear);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> removeFromRecent(String itemType, String itemId) async {
    try {
      await _dio.delete(ApiEndpoints.recentItem(itemType, itemId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
