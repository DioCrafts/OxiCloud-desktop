import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import 'core/repositories/auth_repository.dart';
import 'core/repositories/favorites_repository.dart';
import 'core/repositories/file_browser_repository.dart';
import 'core/repositories/recent_repository.dart';
import 'core/repositories/search_repository.dart';
import 'core/repositories/share_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'core/repositories/trash_repository.dart';
import 'data/datasources/favorites_api_datasource.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'injection.dart';
import 'package:window_manager/window_manager.dart';

import 'platform/desktop_window.dart';
import 'platform/system_tray_service.dart';
import 'presentation/app.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/favorites/favorites_bloc.dart';
import 'presentation/blocs/file_browser/file_browser_bloc.dart';
import 'presentation/blocs/recent/recent_bloc.dart';
import 'presentation/blocs/search/search_bloc.dart';
import 'presentation/blocs/share/share_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/trash/trash_bloc.dart';
import 'src/rust/frb_generated.dart';

/// Check if current platform is desktop
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Show the app immediately with a splash screen so the window becomes
  // visible. On Windows the native window is only shown after Flutter
  // renders its first frame (see flutter_window.cpp SetNextFrameCallback).
  // If we await heavy init before runApp() the window stays invisible.
  runApp(const OxiCloudBootstrap());
}

/// Write error log to a file for diagnosing release-build failures.
Future<void> _writeErrorLog(String message) async {
  try {
    final dir = await getApplicationSupportDirectory();
    final logFile = File('${dir.path}/oxicloud_crash.log');
    final timestamp = DateTime.now().toIso8601String();
    await logFile.writeAsString(
      '[$timestamp]\n$message\n\n',
      mode: FileMode.append,
    );
    debugPrint('Error log written to: ${logFile.path}');
  } catch (_) {
    // Can't log – ignore silently
  }
}

/// Global key so the tray can trigger sync without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _syncNowFromTray() {
  final ctx = navigatorKey.currentContext;
  if (ctx != null) {
    try {
      ctx.read<SyncBloc>().add(const SyncNowRequested());
    } on Exception catch (_) {
      // BLoC not yet available
    }
  }
}

// =============================================================================
// Bootstrap widget — shows splash, runs init, then transitions to the real app.
// =============================================================================

class OxiCloudBootstrap extends StatefulWidget {
  const OxiCloudBootstrap({super.key});

  @override
  State<OxiCloudBootstrap> createState() => _OxiCloudBootstrapState();
}

class _OxiCloudBootstrapState extends State<OxiCloudBootstrap> {
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // FIRST: make sure the window is visible on desktop, even if later
      // initialization steps hang. The window_manager plugin may have hidden
      // the window during native plugin registration.
      if (isDesktop) {
        try {
          await windowManager.ensureInitialized();
          await windowManager.setTitle('OxiCloud');
          await windowManager.setSize(const Size(1200, 800));
          await windowManager.setMinimumSize(const Size(800, 600));
          await windowManager.center();
          await windowManager.show();
          await windowManager.focus();
          debugPrint('OxiCloud: Window shown');
        } catch (e) {
          debugPrint('OxiCloud: window_manager early show failed: $e');
        }
      }

      // THEN: heavy async initialization
      debugPrint('OxiCloud: Initializing RustLib...');
      await RustLib.init();
      debugPrint('OxiCloud: RustLib initialized successfully');

      await configureDependencies();

      final rustDataSource = getIt<RustBridgeDataSource>();
      await rustDataSource.initialize();

      // Desktop services (tray + close-to-tray)
      if (isDesktop) {
        try {
          final trayService = getIt<SystemTrayService>();
          await trayService.init();

          final desktopWm = DesktopWindowManager(
            trayService: trayService,
            rustDataSource: rustDataSource,
          );
          await desktopWm.init();

          trayService.onSyncNow = _syncNowFromTray;
        } catch (e, stackTrace) {
          debugPrint('Warning: Desktop service init failed: $e');
          debugPrint('$stackTrace');
        }
      }

      if (mounted) setState(() => _ready = true);
    } catch (e, stackTrace) {
      debugPrint('Fatal initialization error: $e');
      debugPrint('$stackTrace');
      await _writeErrorLog('$e\n$stackTrace');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SelectableText(
                'OxiCloud failed to start.\n\n$_error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 96,
                  height: 96,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.cloud,
                    size: 96,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'OxiCloud',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const OxiCloudAppWrapper();
  }
}

/// Wrapper that provides BLoC providers to the app
class OxiCloudAppWrapper extends StatelessWidget {
  const OxiCloudAppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(getIt<AuthRepository>()),
        ),
        BlocProvider(
          create: (_) => SyncBloc(getIt<SyncRepository>()),
        ),
        BlocProvider(
          create: (_) => FileBrowserBloc(
            getIt<FileBrowserRepository>(),
            getIt<FavoritesApiDataSource>(),
          ),
        ),
        BlocProvider(
          create: (_) => TrashBloc(getIt<TrashRepository>()),
        ),
        BlocProvider(
          create: (_) => ShareBloc(getIt<ShareRepository>()),
        ),
        BlocProvider(
          create: (_) => SearchBloc(getIt<SearchRepository>()),
        ),
        BlocProvider(
          create: (_) => FavoritesBloc(getIt<FavoritesRepository>()),
        ),
        BlocProvider(
          create: (_) => RecentBloc(getIt<RecentRepository>()),
        ),
        RepositoryProvider<SyncRepository>(
          create: (_) => getIt<SyncRepository>(),
        ),
      ],
      child: const OxiCloudApp(),
    );
  }
}
