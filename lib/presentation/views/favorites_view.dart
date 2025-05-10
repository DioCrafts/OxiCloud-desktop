import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/presentation/providers/favorites_provider.dart';
import 'package:oxicloud_desktop/presentation/providers/file_explorer_provider.dart';
import 'package:oxicloud_desktop/presentation/widgets/file_item_tile.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final filesAsync = ref.watch(fileExplorerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
      ),
      body: filesAsync.when(
        data: (files) {
          final favoriteFiles = files.where((file) => favorites.contains(file.path)).toList();
          
          if (favoriteFiles.isEmpty) {
            return const Center(
              child: Text('No hay archivos favoritos'),
            );
          }

          return ListView.builder(
            itemCount: favoriteFiles.length,
            itemBuilder: (context, index) {
              final file = favoriteFiles[index];
              return FileItemTile(
                file: file,
                onTap: () {
                  if (file.isDirectory) {
                    ref.read(fileExplorerProvider.notifier).navigateTo(file.path);
                  }
                },
                onLongPress: () {
                  ref.read(favoritesProvider.notifier).toggleFavorite(file.path);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
} 