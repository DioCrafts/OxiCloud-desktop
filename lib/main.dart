import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';

import 'src/rust/frb_generated.dart';
import 'injection.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/file_browser_repository.dart';
import 'core/repositories/search_repository.dart';
import 'core/repositories/share_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'core/repositories/trash_repository.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/blocs/file_browser/file_browser_bloc.dart';
import 'presentation/blocs/trash/trash_bloc.dart';
import 'presentation/blocs/share/share_bloc.dart';
import 'presentation/blocs/search/search_bloc.dart';
import 'presentation/app.dart';
import 'platform/desktop_window.dart';
import 'platform/system_tray_service.dart';

/// Check if current platform is desktop
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Check if current platform is mobile
bool get isMobile => Platform.isAndroid || Platform.isIOS;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Flutter-Rust Bridge
  await RustLib.init();

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Rust core
  final rustDataSource = getIt<RustBridgeDataSource>();
  await rustDataSource.initialize();

  // Initialize system tray + window manager for desktop
  if (isDesktop) {
    final trayService = getIt<SystemTrayService>();
    await trayService.init();

    final windowManager = DesktopWindowManager(
      trayService: trayService,
      rustDataSource: rustDataSource,
    );
    await windowManager.init();

    // Wire "Sync Now" tray action to the SyncBloc (deferred until app is built)
    trayService.onSyncNow = () {
      // Access the global SyncBloc via the navigator key
      _syncNowFromTray();
    };
  }

  runApp(const OxiCloudAppWrapper());
}

/// Global key so the tray can trigger sync without a BuildContext.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void _syncNowFromTray() {
  final ctx = navigatorKey.currentContext;
  if (ctx != null) {
    try {
      ctx.read<SyncBloc>().add(const SyncNowRequested());
    } catch (_) {
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
          create: (_) => FileBrowserBloc(getIt<FileBrowserRepository>()),
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
        RepositoryProvider<SyncRepository>(
          create: (_) => getIt<SyncRepository>(),
        ),
      ],
      child: const OxiCloudApp(),
    );
  }
}
