import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/shares/share_dtos.dart';

class ShareRemoteDatasource {
  final Dio _dio;

  ShareRemoteDatasource(this._dio);

  Future<ShareResponseDto> createShare(CreateShareRequestDto dto) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.shares, data: dto.toJson());
      return ShareResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<List<ShareResponseDto>> listShares() async {
    try {
      final response = await _dio.get(ApiEndpoints.shares);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ShareResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<ShareResponseDto> getShare(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.shareById(id));
      return ShareResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<ShareResponseDto> updateShare(
      String id, UpdateShareRequestDto dto) async {
    try {
      final response =
          await _dio.put(ApiEndpoints.shareById(id), data: dto.toJson());
      return ShareResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> deleteShare(String id) async {
    try {
      await _dio.delete(ApiEndpoints.shareById(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
