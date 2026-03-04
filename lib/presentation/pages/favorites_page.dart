import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/favorite_item.dart';
import '../blocs/favorites/favorites_bloc.dart';
import '../theme/oxicloud_colors.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(const LoadFavorites());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<FavoritesBloc>().add(const LoadFavorites()),
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FavoritesError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: OxiColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<FavoritesBloc>().add(const LoadFavorites()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is FavoritesLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_outline, size: 64, color: OxiColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No favorites yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: OxiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Star files and folders to find them quickly',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: OxiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _buildFavoriteTile(context, item);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildFavoriteTile(BuildContext context, FavoriteItem item) {
    return ListTile(
      leading: Icon(
        item.isFolder ? Icons.folder : Icons.insert_drive_file,
        color: item.isFolder ? OxiColors.primary : OxiColors.textSecondary,
      ),
      title: Text(item.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.path,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: OxiColors.textSecondary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.star, color: Colors.amber),
        onPressed: () {
          context.read<FavoritesBloc>().add(
            RemoveFavorite(itemType: item.itemType, itemId: item.itemId),
          );
        },
        tooltip: 'Remove from favorites',
      ),
    );
  }
}
