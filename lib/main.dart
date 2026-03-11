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

  try {
    // Initialize Flutter-Rust Bridge
    debugPrint('OxiCloud: Initializing RustLib...');
    await RustLib.init();
    debugPrint('OxiCloud: RustLib initialized successfully');

    // Initialize dependency injection
    await configureDependencies();

    // Initialize Rust core
    final rustDataSource = getIt<RustBridgeDataSource>();
    await rustDataSource.initialize();

    // Initialize system tray + window manager for desktop
    if (isDesktop) {
      try {
        final trayService = getIt<SystemTrayService>();
        await trayService.init();

        final windowManager = DesktopWindowManager(
          trayService: trayService,
          rustDataSource: rustDataSource,
        );
        await windowManager.init();

        // Wire "Sync Now" tray action to the SyncBloc (deferred until app is built)
        trayService.onSyncNow = _syncNowFromTray;
      } catch (e, stackTrace) {
        // Desktop services are non-critical; log and continue
        debugPrint('Warning: Desktop service init failed: $e');
        debugPrint('$stackTrace');
      }
    }

    runApp(const OxiCloudAppWrapper());
  } catch (e, stackTrace) {
    debugPrint('Fatal initialization error: $e');
    debugPrint('$stackTrace');
    await _writeErrorLog('$e\n$stackTrace');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'OxiCloud failed to start.\n\nError: $e',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        ),
      ),
    ));
  }
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
