import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';
import '../../dtos/folders/folder_dtos.dart';

class FolderRemoteDatasource {
  final Dio _dio;

  FolderRemoteDatasource(this._dio);

  Future<List<FolderResponseDto>> listRootFolders() async {
    try {
      final response = await _dio.get(ApiEndpoints.folders);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => FolderResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FolderResponseDto> getFolder(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.folderById(id));
      return FolderResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<({List<FolderResponseDto> folders, List<FileResponseDto> files})>
      listFolderContents(String folderId) async {
    try {
      final response = await _dio.get(ApiEndpoints.folderListing(folderId));
      final data = response.data as Map<String, dynamic>;

      final folders = (data['folders'] as List<dynamic>? ?? [])
          .map((e) => FolderResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
      final files = (data['files'] as List<dynamic>? ?? [])
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();

      return (folders: folders, files: files);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FolderResponseDto> createFolder(CreateFolderRequestDto dto) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.folders, data: dto.toJson());
      return FolderResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FolderResponseDto> renameFolder(String id, String newName) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.folderRename(id),
        data: {'name': newName},
      );
      return FolderResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<FolderResponseDto> moveFolder(
      String id, String? newParentId) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.folderMove(id),
        data: {'parent_id': newParentId},
      );
      return FolderResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> deleteFolder(String id) async {
    try {
      await _dio.delete(ApiEndpoints.folderById(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<ResponseBody> downloadFolderZip(String id) async {
    try {
      final response = await _dio.get<ResponseBody>(
        ApiEndpoints.folderDownload(id),
        options: Options(responseType: ResponseType.stream),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
