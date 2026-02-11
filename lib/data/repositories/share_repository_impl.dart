import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/entities/share_item.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/share_repository.dart';
import '../datasources/share_api_datasource.dart';
import '../mappers/trash_share_search_mapper.dart';

class ShareRepositoryImpl implements ShareRepository {
  final ShareApiDataSource _dataSource;
  final Logger _logger = Logger();

  ShareRepositoryImpl(this._dataSource);

  @override
  Future<Either<ShareFailure, PaginatedResult<ShareItem>>> listShares({
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final raw = await _dataSource.listShares(page: page, perPage: perPage);
      final rawItems = raw['items'] as List<dynamic>? ?? [];
      final items = rawItems
          .map((e) => ShareMapper.fromJson(e as Map<String, dynamic>))
          .toList();
      final pagination = ShareMapper.paginationFromJson(
        raw['pagination'] as Map<String, dynamic>? ?? {},
      );
      return Right(PaginatedResult(items: items, pagination: pagination));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'listing shares'));
    } catch (e) {
      _logger.e('Error listing shares: $e');
      return Left(UnknownShareFailure(e.toString()));
    }
  }

  @override
  Future<Either<ShareFailure, ShareItem>> getShare(String id) async {
    try {
      final raw = await _dataSource.getShare(id);
      return Right(ShareMapper.fromJson(raw));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'getting share'));
    } catch (e) {
      _logger.e('Error getting share: $e');
      return Left(UnknownShareFailure(e.toString()));
    }
  }

  @override
  Future<Either<ShareFailure, ShareItem>> createShare({
    required String itemId,
    required String itemType,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  }) async {
    try {
      final body = <String, dynamic>{
        'item_id': itemId,
        'item_type': itemType,
        if (password != null && password.isNotEmpty) 'password': password,
        if (expiresAt != null)
          'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
        if (permissions != null)
          'permissions': ShareMapper.permissionsToJson(permissions),
      };
      final raw = await _dataSource.createShare(body);
      return Right(ShareMapper.fromJson(raw));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'creating share'));
    } catch (e) {
      _logger.e('Error creating share: $e');
      return Left(UnknownShareFailure(e.toString()));
    }
  }

  @override
  Future<Either<ShareFailure, ShareItem>> updateShare({
    required String id,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  }) async {
    try {
      final body = <String, dynamic>{
        if (password != null) 'password': password,
        if (expiresAt != null)
          'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
        if (permissions != null)
          'permissions': ShareMapper.permissionsToJson(permissions),
      };
      final raw = await _dataSource.updateShare(id, body);
      return Right(ShareMapper.fromJson(raw));
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'updating share'));
    } catch (e) {
      _logger.e('Error updating share: $e');
      return Left(UnknownShareFailure(e.toString()));
    }
  }

  @override
  Future<Either<ShareFailure, void>> deleteShare(String id) async {
    try {
      await _dataSource.deleteShare(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'deleting share'));
    } catch (e) {
      _logger.e('Error deleting share: $e');
      return Left(UnknownShareFailure(e.toString()));
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────────

  ShareFailure _mapDioError(DioException e, String action) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      final errorBody = e.response?.data;
      if (errorBody is Map && errorBody['requiresPassword'] == true) {
        return const SharePasswordRequiredFailure();
      }
      return const ShareAccessDeniedFailure();
    }
    if (statusCode == 404) return ShareNotFoundFailure(action);
    if (statusCode == 410) return const ShareExpiredFailure();
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ShareNetworkFailure('$action: connection error');
    }
    _logger.e('Share DioException ($action): $e');
    return UnknownShareFailure(
      e.response?.data?['error']?.toString() ?? e.message ?? action,
    );
  }
}
