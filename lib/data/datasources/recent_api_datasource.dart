import 'api_client.dart';

/// API data source for recent files matching OxiCloud server
class RecentApiDataSource {
  RecentApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/recent
  Future<List<Map<String, dynamic>>> getRecent() async {
    final response = await _apiClient.dio.get<List<dynamic>>('api/recent');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// POST /api/recent/{itemType}/{itemId}
  Future<void> addRecent(String itemType, String itemId) async {
    await _apiClient.dio.post<void>('api/recent/$itemType/$itemId');
  }

  /// DELETE /api/recent/clear
  Future<void> clearRecent() async {
    await _apiClient.dio.delete<void>('api/recent/clear');
  }
}
