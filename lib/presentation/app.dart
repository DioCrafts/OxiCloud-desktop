import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/repositories/sync_repository.dart';
import '../main.dart' show navigatorKey;

import 'blocs/auth/auth_bloc.dart';
import 'blocs/settings/settings_bloc.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/settings_page.dart';
import 'pages/selective_sync_page.dart';
import 'pages/file_browser_page.dart';
import 'pages/trash_page.dart';
import 'pages/shares_page.dart';
import 'pages/search_page.dart';
import 'shell/adaptive_shell.dart';
import 'theme/oxicloud_theme.dart';

class OxiCloudApp extends StatelessWidget {
  const OxiCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'OxiCloud',
      debugShowCheckedModeBanner: false,
      theme: OxiCloudTheme.light(),
      darkTheme: OxiCloudTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => const _AuthWrapper(),
        );

      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case '/home':
        return MaterialPageRoute(
          builder: (_) => const HomePage(),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => SettingsBloc(context.read<SyncRepository>()),
            child: const SettingsPage(),
          ),
        );

      case '/selective-sync':
        return MaterialPageRoute(
          builder: (_) => const SelectiveSyncPage(),
        );

      case '/files':
        return MaterialPageRoute(
          builder: (_) => const FileBrowserPage(),
        );

      case '/trash':
        return MaterialPageRoute(
          builder: (_) => const TrashPage(),
        );

      case '/shares':
        return MaterialPageRoute(
          builder: (_) => const SharesPage(),
        );

      case '/search':
        return MaterialPageRoute(
          builder: (_) => const SearchPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }

}

/// Wrapper that checks authentication status and redirects accordingly
class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading || state is AuthInitial) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const AdaptiveShell();
        }

        return const LoginPage();
      },
    );
  }
}
