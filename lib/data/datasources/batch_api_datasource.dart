import 'api_client.dart';

/// API data source for batch operations matching OxiCloud server's /api/batch/*
class BatchApiDataSource {
  BatchApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// POST /api/batch/delete
  Future<Map<String, dynamic>> batchDelete({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'api/batch/delete',
      data: {
        'file_ids': fileIds,
        'folder_ids': folderIds,
      },
    );
    return response.data ?? {};
  }

  /// POST /api/batch/move
  Future<Map<String, dynamic>> batchMove({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
    String? targetFolderId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'api/batch/move',
      data: {
        'file_ids': fileIds,
        'folder_ids': folderIds,
        'target_folder_id': targetFolderId,
      },
    );
    return response.data ?? {};
  }

  /// POST /api/batch/copy
  Future<Map<String, dynamic>> batchCopy({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
    String? targetFolderId,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'api/batch/copy',
      data: {
        'file_ids': fileIds,
        'folder_ids': folderIds,
        'target_folder_id': targetFolderId,
      },
    );
    return response.data ?? {};
  }

  /// GET /api/files/{id}/thumbnail/{size}
  String getThumbnailUrl(String fileId, {String size = 'small'}) {
    return '${_apiClient.baseUrl}api/files/$fileId/thumbnail/$size';
  }

  /// GET /api/folders/{id}/download — returns ZIP stream
  Future<void> downloadFolderAsZip(String folderId, String savePath) async {
    await _apiClient.dio.download(
      'api/folders/$folderId/download',
      savePath,
    );
  }
}
