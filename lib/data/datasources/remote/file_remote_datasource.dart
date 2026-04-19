import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';

class FileRemoteDatasource {
  final Dio _dio;

  FileRemoteDatasource(this._dio);

  Future<List<FileResponseDto>> listFiles({String? folderId}) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.files,
        queryParameters: {if (folderId != null) 'folder_id': folderId},
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FileResponseDto> getFile(String id) async {
    try {
      final response = await _dio.get('${ApiEndpoints.fileMetadata(id)}');
      return FileResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FileResponseDto> uploadFile({
    required String name,
    required String? folderId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String mimeType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromStream(
          () => fileStream,
          fileSize,
          filename: name,
          contentType: DioMediaType.parse(mimeType),
        ),
        if (folderId != null) 'folder_id': folderId,
      });
      final response = await _dio.post(
        ApiEndpoints.fileUpload,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return FileResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<ResponseBody> downloadFile(String id) async {
    try {
      final response = await _dio.get<ResponseBody>(
        ApiEndpoints.fileById(id),
        options: Options(responseType: ResponseType.stream),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> downloadFileToPath(String id, String savePath) async {
    try {
      await _dio.download(ApiEndpoints.fileById(id), savePath);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> deleteFile(String id) async {
    try {
      await _dio.delete(ApiEndpoints.fileById(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FileResponseDto> renameFile(String id, String newName) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.fileRename(id),
        data: {'name': newName},
      );
      return FileResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FileResponseDto> moveFile(String id, String targetFolderId) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.fileMove(id),
        data: {'folder_id': targetFolderId},
      );
      return FileResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<Uint8List> getThumbnail(String id, {String size = '256'}) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.fileThumbnail(id, size),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
