import 'package:dio/dio.dart';

import 'api_client.dart';

/// Raw REST calls to OxiCloud server for search operations.
class SearchApiDataSource {
  final ApiClient _apiClient;

  SearchApiDataSource(this._apiClient);

  Dio get _dio => _apiClient.dio;

  /// GET /api/search/ — simple search.
  Future<Map<String, dynamic>> search({
    String? query,
    String? folderId,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      if (query != null && query.isNotEmpty) 'query': query,
      if (folderId != null) 'folder_id': folderId,
      'limit': limit,
      'offset': offset,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      'api/search/',
      queryParameters: params,
    );
    return response.data!;
  }

  /// POST /api/search/advanced — advanced search.
  Future<Map<String, dynamic>> advancedSearch(
    Map<String, dynamic> criteria,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'api/search/advanced',
      data: criteria,
    );
    return response.data!;
  }
}
