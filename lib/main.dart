import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
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

  // Catch all Flutter framework errors so unhandled exceptions never kill
  // the process silently.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('${details.stack}');
    _writeErrorLog('FlutterError: ${details.exception}\n${details.stack}');
  };

  // Catch async errors that escape all try-catch blocks.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher uncaught error: $error');
    debugPrint('$stack');
    _writeErrorLog('UNCAUGHT: $error\n$stack');
    return true; // Prevent the runtime from terminating
  };

  // Wrap the entire app in runZonedGuarded to catch any Dart async errors
  // that might escape both PlatformDispatcher and FlutterError handlers.
  runZonedGuarded(
    () {
      // Show the app immediately with a splash screen so the window becomes
      // visible. On Windows the native window is only shown after Flutter
      // renders its first frame (see flutter_window.cpp SetNextFrameCallback).
      // If we await heavy init before runApp() the window stays invisible.
      runApp(const OxiCloudBootstrap());
    },
    (error, stack) {
      debugPrint('Zoned uncaught error: $error');
      debugPrint('$stack');
      _writeErrorLog('ZONED: $error\n$stack');
    },
  );
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
        await _ensureWindowVisible();
      }

      // Run platform diagnostics before heavy init to surface issues early.
      if (Platform.isWindows) {
        _logWindowsDiagnostics();
      }

      // THEN: heavy async initialization — load the Rust native library.
      // On Windows the DLL must be resolved relative to the executable, not
      // the current working directory, because shortcuts / installers may set
      // a different CWD.
      debugPrint('OxiCloud: Initializing RustLib...');
      try {
        await RustLib.init(
          externalLibrary: _loadRustLibrary(),
        );
      } catch (e) {
        debugPrint('OxiCloud: RustLib.init with explicit path failed: $e');
        // Fallback: let flutter_rust_bridge try its default search
        debugPrint('OxiCloud: Retrying RustLib.init with default loader...');
        await RustLib.init();
      }
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
          // Non-fatal: the app can still work without tray / close-to-tray
        }
      }

      // Final safety net on Windows: schedule a delayed re-show in case
      // a plugin or race condition hid the window during initialization.
      if (isDesktop && Platform.isWindows) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          try {
            await windowManager.setSkipTaskbar(false);
            await windowManager.show();
          } catch (_) {}
        });
      }

      if (mounted) setState(() => _ready = true);
    } catch (e, stackTrace) {
      debugPrint('Fatal initialization error: $e');
      debugPrint('$stackTrace');
      await _writeErrorLog('$e\n$stackTrace');
      if (mounted) setState(() => _error = e.toString());

      // Make absolutely sure the window is visible so the user can see the
      // error message, even if the first attempt to show it failed.
      if (isDesktop) {
        await _ensureWindowVisible();
      }
    }
  }

  /// Show the window using window_manager with multiple retry strategies.
  Future<void> _ensureWindowVisible() async {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setTitle('OxiCloud');
      await windowManager.setSize(const Size(1200, 800));
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.center();
      // skipTaskbar: false ensures the app appears in the taskbar
      await windowManager.setSkipTaskbar(false);
      await windowManager.show();
      await windowManager.focus();
      debugPrint('OxiCloud: Window shown');
    } catch (e) {
      debugPrint('OxiCloud: window_manager show failed: $e');
    }
  }

  /// Log diagnostics about the Windows environment to help debug startup
  /// failures (missing DLLs, wrong CWD, missing data directory, etc.).
  void _logWindowsDiagnostics() {
    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final cwd = Directory.current.path;
      debugPrint('OxiCloud [diag] exe dir : $exeDir');
      debugPrint('OxiCloud [diag] CWD     : $cwd');

      // Check critical files
      final criticalFiles = [
        '$exeDir\\oxicloud_core.dll',
        '$exeDir\\flutter_windows.dll',
        '$exeDir\\data\\flutter_assets\\AssetManifest.json',
      ];
      for (final path in criticalFiles) {
        final exists = File(path).existsSync();
        debugPrint('OxiCloud [diag] ${exists ? "OK" : "MISSING"}: $path');
        if (!exists) {
          _writeErrorLog('DIAGNOSTIC: Missing critical file: $path');
        }
      }

      // Check that the data directory exists
      final dataDir = Directory('$exeDir\\data');
      if (!dataDir.existsSync()) {
        debugPrint('OxiCloud [diag] MISSING: data directory at $exeDir\\data');
        _writeErrorLog('DIAGNOSTIC: Missing data directory: ${dataDir.path}');
      }
    } catch (e) {
      debugPrint('OxiCloud [diag] diagnostics failed: $e');
    }
  }

  /// Load the Rust native library from the correct platform-specific path.
  /// On Windows, when launched from a shortcut, the CWD may differ from the
  /// exe directory, so we resolve relative to the executable location.
  ExternalLibrary? _loadRustLibrary() {
    try {
      if (Platform.isWindows) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final dllPath = '$exeDir\\oxicloud_core.dll';
        debugPrint('OxiCloud: Loading Rust DLL from: $dllPath');
        if (File(dllPath).existsSync()) {
          return ExternalLibrary.open(dllPath);
        }
        debugPrint('OxiCloud: DLL not found at $dllPath, falling back');
      } else if (Platform.isLinux) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final soPath = '$exeDir/lib/liboxicloud_core.so';
        if (File(soPath).existsSync()) {
          return ExternalLibrary.open(soPath);
        }
        // Try next to the executable
        final soPath2 = '$exeDir/liboxicloud_core.so';
        if (File(soPath2).existsSync()) {
          return ExternalLibrary.open(soPath2);
        }
      } else if (Platform.isMacOS) {
        final exeDir = File(Platform.resolvedExecutable).parent.path;
        final dylibPath = '$exeDir/../Frameworks/liboxicloud_core.dylib';
        if (File(dylibPath).existsSync()) {
          return ExternalLibrary.open(dylibPath);
        }
      }
    } catch (e) {
      debugPrint('OxiCloud: Could not pre-load Rust library: $e');
    }
    return null; // Let FRB use its default loader
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'OxiCloud failed to start',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _error!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                  if (Platform.isWindows) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Troubleshooting (Windows):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '1. Reinstall OxiCloud from the official installer\n'
                        '2. Ensure oxicloud_core.dll is next to OxiCloud.exe\n'
                        '3. Install Visual C++ Redistributable 2022\n'
                        '4. Check %APPDATA%\\oxicloud_crash.log for details',
                        style: TextStyle(fontSize: 14, color: Colors.white60, height: 1.6),
                      ),
                    ),
                  ],
                ],
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
