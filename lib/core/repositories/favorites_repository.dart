import 'package:dartz/dartz.dart';
import '../entities/favorite_item.dart';

/// Favorites repository interface
abstract class FavoritesRepository {
  Future<Either<FavoritesFailure, List<FavoriteItem>>> getFavorites();
  Future<Either<FavoritesFailure, void>> addFavorite(String itemType, String itemId);
  Future<Either<FavoritesFailure, void>> removeFavorite(String itemType, String itemId);
}

abstract class FavoritesFailure {
  const FavoritesFailure(this.message);
  final String message;
}

class NetworkFavoritesFailure extends FavoritesFailure {
  const NetworkFavoritesFailure(super.message);
}

class UnknownFavoritesFailure extends FavoritesFailure {
  const UnknownFavoritesFailure(super.message);
}
