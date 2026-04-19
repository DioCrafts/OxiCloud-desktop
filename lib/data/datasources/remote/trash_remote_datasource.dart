import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/trash/trash_dtos.dart';

class TrashRemoteDatasource {
  final Dio _dio;

  TrashRemoteDatasource(this._dio);

  Future<List<TrashItemResponseDto>> listTrash() async {
    try {
      final response = await _dio.get(ApiEndpoints.trash);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => TrashItemResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> restoreItem(String id) async {
    try {
      await _dio.post(ApiEndpoints.trashRestore(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> permanentlyDelete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.trashDelete(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> emptyTrash() async {
    try {
      await _dio.delete(ApiEndpoints.trashEmpty);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
