import 'package:dio/dio.dart';

import 'api_client.dart';

/// Raw REST calls to OxiCloud server for trash operations.
class TrashApiDataSource {
  final ApiClient _apiClient;

  TrashApiDataSource(this._apiClient);

  Dio get _dio => _apiClient.dio;

  /// GET /api/trash/ — list all trashed items.
  Future<List<Map<String, dynamic>>> listTrash() async {
    final response = await _dio.get<List<dynamic>>('api/trash/');
    return List<Map<String, dynamic>>.from(response.data!);
  }

  /// DELETE /api/trash/files/{id} — move file to trash.
  Future<void> trashFile(String fileId) async {
    await _dio.delete<dynamic>('api/trash/files/$fileId');
  }

  /// DELETE /api/trash/folders/{id} — move folder to trash.
  Future<void> trashFolder(String folderId) async {
    await _dio.delete<dynamic>('api/trash/folders/$folderId');
  }

  /// POST /api/trash/{id}/restore — restore an item.
  Future<void> restoreItem(String trashId) async {
    await _dio.post<dynamic>('api/trash/$trashId/restore');
  }

  /// DELETE /api/trash/{id} — permanently delete.
  Future<void> deleteItemPermanently(String trashId) async {
    await _dio.delete<dynamic>('api/trash/$trashId');
  }

  /// DELETE /api/trash/empty — empty entire trash.
  Future<void> emptyTrash() async {
    await _dio.delete<dynamic>('api/trash/empty');
  }
}
