import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({});

  void addToFavorites(String path) {
    if (!state.contains(path)) {
      state = {...state, path};
    }
  }

  void removeFromFavorites(String path) {
    state = state.where((p) => p != path).toSet();
  }

  bool isFavorite(String path) {
    return state.contains(path);
  }

  void toggleFavorite(String path) {
    if (state.contains(path)) {
      removeFromFavorites(path);
    } else {
      addToFavorites(path);
    }
  }
} 