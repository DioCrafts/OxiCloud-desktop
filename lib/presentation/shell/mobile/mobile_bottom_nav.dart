import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileBottomNav extends StatelessWidget {
  final String currentPath;

  const MobileBottomNav({super.key, required this.currentPath});

  int get _currentIndex {
    if (currentPath.startsWith('/files')) return 0;
    if (currentPath == '/favorites') return 1;
    if (currentPath == '/photos') return 2;
    if (currentPath == '/search') return 3;
    if (currentPath == '/recent') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (i) {
        final route = switch (i) {
          0 => '/files',
          1 => '/favorites',
          2 => '/photos',
          3 => '/search',
          4 => '/recent',
          _ => '/files',
        };
        context.go(route);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.folder_outlined),
          selectedIcon: Icon(Icons.folder),
          label: 'Files',
        ),
        NavigationDestination(
          icon: Icon(Icons.star_outline),
          selectedIcon: Icon(Icons.star),
          label: 'Favorites',
        ),
        NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: 'Photos',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.access_time),
          selectedIcon: Icon(Icons.access_time_filled),
          label: 'Recent',
        ),
      ],
    );
  }
}
