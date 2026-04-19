import '../entities/file_entity.dart';

abstract class FavoritesRepository {
  /// List all favorites.
  Future<List<FileEntity>> listFavorites();

  /// Add item to favorites.
  Future<void> addFavorite(String itemType, String itemId);

  /// Remove item from favorites.
  Future<void> removeFavorite(String itemType, String itemId);
}
