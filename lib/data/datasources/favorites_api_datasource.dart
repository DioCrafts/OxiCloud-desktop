import 'api_client.dart';

/// API data source for favorites operations matching OxiCloud server
class FavoritesApiDataSource {
  FavoritesApiDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/favorites
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final response = await _apiClient.dio.get<List<dynamic>>('api/favorites');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  /// POST /api/favorites/{itemType}/{itemId}
  Future<void> addFavorite(String itemType, String itemId) async {
    await _apiClient.dio.post<void>('api/favorites/$itemType/$itemId');
  }

  /// DELETE /api/favorites/{itemType}/{itemId}
  Future<void> removeFavorite(String itemType, String itemId) async {
    await _apiClient.dio.delete<void>('api/favorites/$itemType/$itemId');
  }
}
