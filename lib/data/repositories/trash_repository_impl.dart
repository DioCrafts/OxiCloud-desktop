import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/entities/trash_item.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/trash_repository.dart';
import '../datasources/trash_api_datasource.dart';
import '../mappers/trash_share_search_mapper.dart';

class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._dataSource);

  final TrashApiDataSource _dataSource;
  final Logger _logger = Logger();

  @override
  Future<Either<TrashFailure, List<TrashItem>>> listTrash() async {
    try {
      final rawList = await _dataSource.listTrash();
      final items = TrashMapper.listFromJson(rawList);
      return Right(items);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'listing trash'));
    } on Exception catch (e) {
      _logger.e('Error listing trash: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  @override
  Future<Either<TrashFailure, void>> trashFile(String fileId) async {
    try {
      await _dataSource.trashFile(fileId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'trashing file'));
    } on Exception catch (e) {
      _logger.e('Error trashing file: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  @override
  Future<Either<TrashFailure, void>> trashFolder(String folderId) async {
    try {
      await _dataSource.trashFolder(folderId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'trashing folder'));
    } on Exception catch (e) {
      _logger.e('Error trashing folder: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  @override
  Future<Either<TrashFailure, void>> restoreItem(String trashId) async {
    try {
      await _dataSource.restoreItem(trashId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'restoring item'));
    } on Exception catch (e) {
      _logger.e('Error restoring item: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  @override
  Future<Either<TrashFailure, void>> deleteItemPermanently(
    String trashId,
  ) async {
    try {
      await _dataSource.deleteItemPermanently(trashId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'deleting permanently'));
    } on Exception catch (e) {
      _logger.e('Error deleting permanently: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  @override
  Future<Either<TrashFailure, void>> emptyTrash() async {
    try {
      await _dataSource.emptyTrash();
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e, 'emptying trash'));
    } on Exception catch (e) {
      _logger.e('Error emptying trash: $e');
      return Left(UnknownTrashFailure(e.toString()));
    }
  }

  // ── Error mapping ───────────────────────────────────────────────────────

  TrashFailure _mapDioError(DioException e, String action) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 501) {
      return const TrashDisabledFailure();
    }
    if (statusCode == 404) {
      final data = e.response?.data;
      return TrashItemNotFoundFailure(
        (data is Map ? data['error']?.toString() : null) ?? 'Unknown',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return TrashNetworkFailure('$action: connection error');
    }
    _logger.e('Trash DioException ($action): $e');
    final data = e.response?.data;
    return UnknownTrashFailure(
      (data is Map ? data['error']?.toString() : null) ?? e.message ?? action,
    );
  }
}
