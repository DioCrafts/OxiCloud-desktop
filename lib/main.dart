import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

import 'injection.dart';
import 'core/repositories/auth_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/sync/sync_bloc.dart';
import 'presentation/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependency injection
  await configureDependencies();

  // Initialize Rust core
  final rustDataSource = getIt<RustBridgeDataSource>();
  await rustDataSource.initialize();

  // Initialize window manager for desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
      title: 'OxiCloud',
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const OxiCloudAppWrapper());
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
        RepositoryProvider<SyncRepository>(
          create: (_) => getIt<SyncRepository>(),
        ),
      ],
      child: const OxiCloudApp(),
    );
  }
}
