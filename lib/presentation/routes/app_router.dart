import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/auth_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/presentation/pages/file_browser_page.dart';
import 'package:oxicloud_desktop/presentation/pages/initial_sync_setup_page.dart';
import 'package:oxicloud_desktop/presentation/pages/login_page.dart';
import 'package:oxicloud_desktop/presentation/pages/server_setup_page.dart';
import 'package:oxicloud_desktop/presentation/pages/splash_page.dart';
import 'package:oxicloud_desktop/presentation/pages/settings_page.dart';
import 'package:oxicloud_desktop/presentation/pages/sync_status_page.dart';
import 'package:oxicloud_desktop/presentation/pages/trash_page.dart';
import 'package:oxicloud_desktop/presentation/pages/native_fs_settings_page.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = getIt<AuthService>();
  
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      // Don't redirect during splash screen
      if (state.matchedLocation == '/splash') {
        return null;
      }
      
      // Check if a server URL is set
      final hasServerUrl = await authService.hasServerUrl();
      
      // If no server URL is set, redirect to server setup
      if (!hasServerUrl && state.matchedLocation != '/server-setup') {
        return '/server-setup';
      }
      
      // Check authentication status
      final isLoggedIn = authService.currentState == AuthState.authenticated;
      
      // Allow access to public routes even when not logged in
      if (state.matchedLocation == '/login' || 
          state.matchedLocation == '/server-setup' || 
          state.matchedLocation == '/initial-setup') {
        return null;
      }
      
      // Redirect to login if not logged in
      if (!isLoggedIn) {
        return '/login';
      }
      
      // Check if initial setup is needed
      // In a real implementation, you would check if this is the first run
      final isFirstRun = false; // Replace with actual check
      
      // If first run, redirect to initial setup
      if (isFirstRun && state.matchedLocation != '/initial-setup') {
        return '/initial-setup';
      }
      
      // User is logged in and setup is complete, allow access to protected routes
      return null;
    },
    routes: [
      // Splash screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Authentication & setup routes
      GoRoute(
        path: '/server-setup',
        builder: (context, state) => const ServerSetupPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/initial-setup',
        builder: (context, state) => const InitialSyncSetupPage(),
      ),
      
      // Main application routes
      GoRoute(
        path: '/',
        builder: (context, state) => const FileBrowserPage(folderId: '/'),
        routes: [
          // Folder browser
          GoRoute(
            path: 'folder/:folderId',
            builder: (context, state) {
              final folderId = state.pathParameters['folderId'] ?? '/';
              return FileBrowserPage(folderId: folderId);
            },
          ),
          
          // Settings
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          
          // Sync status
          GoRoute(
            path: 'sync',
            builder: (context, state) => const SyncStatusPage(),
          ),
          
          // Trash
          GoRoute(
            path: 'trash',
            builder: (context, state) => const TrashPage(),
          ),
          
          // Native File System Settings
          GoRoute(
            path: 'native-fs',
            builder: (context, state) => const NativeFileSystemSettingsPage(),
          ),
        ],
      ),
    ],
    // Handle errors
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('The page ${state.matchedLocation} does not exist'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});