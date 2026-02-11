import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/entities/search_results.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/search_repository.dart';
import '../datasources/search_api_datasource.dart';
import '../mappers/trash_share_search_mapper.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchApiDataSource _dataSource;
  final Logger _logger = Logger();

  SearchRepositoryImpl(this._dataSource);

  @override
  Future<Either<SearchFailure, SearchResults>> search(
    String query, {
    String? folderId,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final raw = await _dataSource.search(
        query: query,
        folderId: folderId,
        limit: limit,
        offset: offset,
      );
      return Right(SearchMapper.resultsFromJson(raw));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'searching'));
    } catch (e) {
      _logger.e('Error searching: $e');
      return Left(UnknownSearchFailure(e.toString()));
    }
  }

  @override
  Future<Either<SearchFailure, SearchResults>> advancedSearch(
    SearchCriteria criteria,
  ) async {
    try {
      final body = SearchMapper.criteriaToJson(criteria);
      final raw = await _dataSource.advancedSearch(body);
      return Right(SearchMapper.resultsFromJson(raw));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'advanced search'));
    } catch (e) {
      _logger.e('Error in advanced search: $e');
      return Left(UnknownSearchFailure(e.toString()));
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────────

  SearchFailure _mapDioError(DioException e, String action) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 503) return const SearchUnavailableFailure();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return SearchNetworkFailure('$action: connection error');
    }
    _logger.e('Search DioException ($action): $e');
    return UnknownSearchFailure(
      e.response?.data?['error']?.toString() ?? e.message ?? action,
    );
  }
}
