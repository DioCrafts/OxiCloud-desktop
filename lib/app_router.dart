import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers.dart';
import 'presentation/features/admin/admin_page.dart';
import 'presentation/features/auth/connect_page.dart';
import 'presentation/features/auth/device_login_page.dart';
import 'presentation/features/auth/login_page.dart';
import 'presentation/features/auth/setup_page.dart';
import 'presentation/features/favorites/favorites_page.dart';
import 'presentation/features/file_browser/file_browser_page.dart';
import 'presentation/features/photos/photos_page.dart';
import 'presentation/features/playlists/playlists_page.dart';
import 'presentation/features/public_share/public_share_page.dart';
import 'presentation/features/recent/recent_page.dart';
import 'presentation/features/search/search_page.dart';
import 'presentation/features/settings/settings_page.dart';
import 'presentation/features/shares/shares_page.dart';
import 'presentation/features/trash/trash_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/connect',
    routes: [
      GoRoute(
        path: '/connect',
        builder: (context, state) => const ConnectPage(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/files',
        builder: (context, state) => const FileBrowserPage(),
      ),
      GoRoute(
        path: '/files/:folderId',
        builder: (context, state) => FileBrowserPage(
          folderId: state.pathParameters['folderId'],
        ),
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/recent',
        builder: (context, state) => const RecentPage(),
      ),
      GoRoute(
        path: '/photos',
        builder: (context, state) => const PhotosPage(),
      ),
      GoRoute(
        path: '/trash',
        builder: (context, state) => const TrashPage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/shares',
        builder: (context, state) => const SharesPage(),
      ),
      GoRoute(
        path: '/playlists',
        builder: (context, state) => const PlaylistsPage(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/device-login',
        builder: (context, state) => const DeviceLoginPage(),
      ),
      GoRoute(
        path: '/s/:token',
        builder: (context, state) => PublicSharePage(
          token: state.pathParameters['token']!,
        ),
      ),
    ],
    redirect: (context, state) async {
      final config = ref.read(appConfigProvider);
      final hasServer = config.hasServer;
      final secureStorage = ref.read(secureStorageProvider);
      final token = await secureStorage.getAccessToken();
      final isLoggedIn = token != null;
      final loc = state.matchedLocation;
      final isConnectRoute = loc == '/connect';
      final isAuthRoute = loc == '/login' || loc == '/setup' || isConnectRoute || loc == '/device-login';

      // No server configured → must connect first
      if (!hasServer && !isConnectRoute) return '/connect';
      // Server configured, skip connect page
      if (hasServer && isConnectRoute) {
        return isLoggedIn ? '/files' : '/login';
      }
      // Not logged in → send to login
      if (!isLoggedIn && !isAuthRoute) return '/login';
      // Already logged in, don't show auth pages
      if (isLoggedIn && isAuthRoute) return '/files';
      return null;
    },
  );
});
