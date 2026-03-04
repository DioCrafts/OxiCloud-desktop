import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../core/entities/favorite_item.dart';
import '../../core/repositories/favorites_repository.dart';
import '../datasources/favorites_api_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesApiDataSource _dataSource;

  FavoritesRepositoryImpl(this._dataSource);

  @override
  Future<Either<FavoritesFailure, List<FavoriteItem>>> getFavorites() async {
    try {
      final data = await _dataSource.getFavorites();
      final items = data.map((d) => FavoriteItem(
        id: d['id']?.toString() ?? '',
        itemId: d['item_id']?.toString() ?? '',
        itemType: d['item_type']?.toString() ?? 'file',
        name: d['name']?.toString() ?? '',
        path: d['path']?.toString() ?? '',
        addedAt: DateTime.tryParse(d['created_at']?.toString() ?? '') ?? DateTime.now(),
      )).toList();
      return Right(items);
    } on DioException catch (e) {
      return Left(NetworkFavoritesFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFavoritesFailure(e.toString()));
    }
  }

  @override
  Future<Either<FavoritesFailure, void>> addFavorite(String itemType, String itemId) async {
    try {
      await _dataSource.addFavorite(itemType, itemId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkFavoritesFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFavoritesFailure(e.toString()));
    }
  }

  @override
  Future<Either<FavoritesFailure, void>> removeFavorite(String itemType, String itemId) async {
    try {
      await _dataSource.removeFavorite(itemType, itemId);
      return const Right(null);
    } on DioException catch (e) {
      return Left(NetworkFavoritesFailure(e.message ?? 'Network error'));
    } catch (e) {
      return Left(UnknownFavoritesFailure(e.toString()));
    }
  }
}
