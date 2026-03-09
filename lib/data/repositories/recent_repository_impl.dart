import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/entities/favorite_item.dart';
import '../../core/repositories/recent_repository.dart';
import '../datasources/recent_api_datasource.dart';

class RecentRepositoryImpl implements RecentRepository {
  RecentRepositoryImpl(this._dataSource);

  final RecentApiDataSource _dataSource;

  @override
  Future<Either<RecentFailure, List<RecentItem>>> getRecent() async {
    try {
      final data = await _dataSource.getRecent();
      final items = data.map((d) => RecentItem(
        id: d['id']?.toString() ?? '',
        itemId: d['item_id']?.toString() ?? '',
        itemType: d['item_type']?.toString() ?? 'file',
        name: d['name']?.toString() ?? '',
        path: d['path']?.toString() ?? '',
        mimeType: d['mime_type']?.toString(),
        size: d['size'] as int?,
        accessedAt: DateTime.tryParse(d['accessed_at']?.toString() ?? '') ?? DateTime.now(),
      )).toList();
      return Right(items);
    } on DioException catch (e) {
      return Left(NetworkRecentFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(UnknownRecentFailure(e.toString()));
    }
  }

  @override
  Future<Either<RecentFailure, void>> addRecent(String itemType, String itemId) async {
    try {
      await _dataSource.addRecent(itemType, itemId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkRecentFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(UnknownRecentFailure(e.toString()));
    }
  }

  @override
  Future<Either<RecentFailure, void>> clearRecent() async {
    try {
      await _dataSource.clearRecent();
      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkRecentFailure(e.message ?? 'Network error'));
    } on Exception catch (e) {
      return Left(UnknownRecentFailure(e.toString()));
    }
  }
}
