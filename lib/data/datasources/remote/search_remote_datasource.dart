import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../domain/repositories/search_repository.dart';
import '../../dtos/search/search_dtos.dart';

class SearchRemoteDatasource {
  final Dio _dio;

  SearchRemoteDatasource(this._dio);

  Future<List<SearchResultResponseDto>> search(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.search,
        queryParameters: {'q': query},
      );
      final list = response.data as List<dynamic>;
      return list
          .map(
            (e) => SearchResultResponseDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<List<SearchResultResponseDto>> advancedSearch(
    SearchCriteria criteria,
  ) async {
    try {
      final body = <String, dynamic>{};
      if (criteria.nameContains != null) {
        body['name_contains'] = criteria.nameContains;
      }
      if (criteria.fileTypes != null) body['file_types'] = criteria.fileTypes;
      if (criteria.createdAfter != null) {
        body['created_after'] = criteria.createdAfter!.toIso8601String();
      }
      if (criteria.createdBefore != null) {
        body['created_before'] = criteria.createdBefore!.toIso8601String();
      }
      if (criteria.modifiedAfter != null) {
        body['modified_after'] = criteria.modifiedAfter!.toIso8601String();
      }
      if (criteria.modifiedBefore != null) {
        body['modified_before'] = criteria.modifiedBefore!.toIso8601String();
      }
      if (criteria.minSize != null) body['min_size'] = criteria.minSize;
      if (criteria.maxSize != null) body['max_size'] = criteria.maxSize;
      if (criteria.folderId != null) body['folder_id'] = criteria.folderId;
      body['recursive'] = criteria.recursive;
      body['limit'] = criteria.limit;
      body['offset'] = criteria.offset;
      body['sort_by'] = criteria.sortBy;

      final response = await _dio.post(ApiEndpoints.searchAdvanced, data: body);
      final list = response.data as List<dynamic>;
      return list
          .map(
            (e) => SearchResultResponseDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<List<String>> suggest(String query) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.searchSuggest,
        queryParameters: {'q': query},
      );
      final list = response.data as List<dynamic>;
      return list.cast<String>();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> clearCache() async {
    try {
      await _dio.delete(ApiEndpoints.searchCache);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
