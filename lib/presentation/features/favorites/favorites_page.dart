import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/file_entity.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/file_icon.dart';

// --- State ---

class FavoritesState {
  final List<FileEntity> items;
  final bool loading;
  final String? error;

  const FavoritesState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  FavoritesState copyWith({
    List<FileEntity>? items,
    bool? loading,
    String? error,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// --- Notifier ---

class FavoritesNotifier extends Notifier<FavoritesState> {
  @override
  FavoritesState build() => const FavoritesState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(favoritesRepositoryProvider).listFavorites();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> removeFavorite(String itemId) async {
    await ref.read(favoritesRepositoryProvider).removeFavorite('file', itemId);
    await load();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, FavoritesState>(
  FavoritesNotifier.new,
);

// --- Page ---

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(favoritesProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.items.isEmpty) {
      body = const EmptyState(
        icon: Icons.star_outline,
        title: 'No favorites yet',
        subtitle: 'Mark files as favorites to see them here',
      );
    } else {
      body = ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (_, i) {
          final file = state.items[i];
          return ListTile(
            leading: FileIcon(
              mimeType: file.mimeType,
              extension: file.extension,
              size: 32,
            ),
            title: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(file.sizeFormatted),
            trailing: IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              tooltip: 'Remove from favorites',
              onPressed: () =>
                  ref.read(favoritesProvider.notifier).removeFavorite(file.id),
            ),
          );
        },
      );
    }

    return AdaptiveShell(
      currentPath: '/favorites',
      title: 'Favorites',
      itemCount: state.items.length,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(favoritesProvider.notifier).load(),
        ),
      ],
      child: body,
    );
  }
}
