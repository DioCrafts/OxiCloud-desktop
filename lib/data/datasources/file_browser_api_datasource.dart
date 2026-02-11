import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import 'api_client.dart';

/// Raw REST calls to OxiCloud server for file / folder operations.
///
/// Returns decoded JSON maps; mapping to domain entities is done by
/// [FileBrowserMapper].
class FileBrowserApiDataSource {
  final ApiClient _apiClient;
  final Logger _logger = Logger();

  FileBrowserApiDataSource(this._apiClient);

  Dio get _dio => _apiClient.dio;

  // ── Folders ─────────────────────────────────────────────────────────────

  /// List root folders.
  Future<List<Map<String, dynamic>>> listRootFolders() async {
    final response = await _dio.get<List<dynamic>>('api/folders/');
    return List<Map<String, dynamic>>.from(response.data!);
  }

  /// List sub-folders of [parentId].
  Future<List<Map<String, dynamic>>> listSubFolders(String parentId) async {
    final response = await _dio.get<List<dynamic>>('api/folders/$parentId/contents');
    return List<Map<String, dynamic>>.from(response.data!);
  }

  /// Get single folder by [id].
  Future<Map<String, dynamic>> getFolder(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('api/folders/$id');
    return response.data!;
  }

  /// Create a folder.
  Future<Map<String, dynamic>> createFolder(
    String name,
    String? parentId,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'api/folders/',
      data: {'name': name, 'parent_id': parentId},
    );
    return response.data!;
  }

  /// Rename a folder.
  Future<Map<String, dynamic>> renameFolder(String id, String name) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'api/folders/$id/rename',
      data: {'name': name},
    );
    return response.data!;
  }

  /// Delete a folder (moves to trash).
  Future<void> deleteFolder(String id) async {
    await _dio.delete<void>('api/folders/$id');
  }

  // ── Files ───────────────────────────────────────────────────────────────

  /// List files in [folderId] (pass `null` for root).
  Future<List<Map<String, dynamic>>> listFiles(String? folderId) async {
    final queryParams = <String, dynamic>{};
    if (folderId != null) {
      queryParams['folder_id'] = folderId;
    }
    final response = await _dio.get<List<dynamic>>(
      'api/files/',
      queryParameters: queryParams,
    );
    return List<Map<String, dynamic>>.from(response.data!);
  }

  /// Upload a file via multipart.
  Future<Map<String, dynamic>> uploadFile(File file, String? folderId) async {
    final formData = FormData.fromMap({
      if (folderId != null) 'folder_id': folderId,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>('api/files/upload', data: formData);
    return response.data!;
  }

  /// Rename a file.
  Future<Map<String, dynamic>> renameFile(String id, String name) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'api/files/$id/rename',
      data: {'name': name},
    );
    return response.data!;
  }

  /// Delete a file (moves to trash).
  Future<void> deleteFile(String id) async {
    await _dio.delete<void>('api/files/$id');
  }

  /// Download a file to [savePath].
  Future<void> downloadFile(String id, String savePath) async {
    await _dio.download('api/files/$id', savePath);
    _logger.i('Downloaded file $id → $savePath');
  }
}
