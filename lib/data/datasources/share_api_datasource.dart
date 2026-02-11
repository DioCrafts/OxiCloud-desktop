import 'package:dio/dio.dart';

import 'api_client.dart';

/// Raw REST calls to OxiCloud server for share operations.
class ShareApiDataSource {
  final ApiClient _apiClient;

  ShareApiDataSource(this._apiClient);

  Dio get _dio => _apiClient.dio;

  /// POST /api/shares/ — create a new share.
  Future<Map<String, dynamic>> createShare(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'api/shares/',
      data: body,
    );
    return response.data!;
  }

  /// GET /api/shares/ — list user shares (paginated).
  Future<Map<String, dynamic>> listShares({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'api/shares/',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    return response.data!;
  }

  /// GET /api/shares/{id} — get a share by ID.
  Future<Map<String, dynamic>> getShare(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>('api/shares/$id');
    return response.data!;
  }

  /// PUT /api/shares/{id} — update a share.
  Future<Map<String, dynamic>> updateShare(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      'api/shares/$id',
      data: body,
    );
    return response.data!;
  }

  /// DELETE /api/shares/{id} — delete a share.
  Future<void> deleteShare(String id) async {
    await _dio.delete<void>('api/shares/$id');
  }
}
