import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../data/datasources/rust_bridge_datasource.dart';
import 'system_tray_service.dart';

/// Desktop window manager that handles:
/// - Initial window sizing
/// - Close-to-tray behaviour (minimize instead of quit)
/// - Graceful Rust core shutdown on real quit
class DesktopWindowManager with WindowListener {
  final SystemTrayService _trayService;
  final RustBridgeDataSource _rustDataSource;

  bool _minimizeToTray;
  bool _forceQuit = false;

  DesktopWindowManager({
    required SystemTrayService trayService,
    required RustBridgeDataSource rustDataSource,
    bool minimizeToTray = true,
  })  : _trayService = trayService,
        _rustDataSource = rustDataSource,
        _minimizeToTray = minimizeToTray;

  /// Call once at startup to configure the window and wire listeners.
  Future<void> init() async {
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

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    // Prevent default close → we decide what to do in onWindowClose
    await windowManager.setPreventClose(true);
    windowManager.addListener(this);

    // Wire tray callbacks
    _trayService.onShowWindow = _showWindow;
    _trayService.onQuit = _realQuit;
  }

  void dispose() {
    windowManager.removeListener(this);
  }

  /// Whether the app should minimize to tray on close.
  set minimizeToTray(bool value) => _minimizeToTray = value;

  // ── WindowListener ──────────────────────────────────────────────────────

  @override
  void onWindowClose() async {
    if (_forceQuit) {
      // Real quit: shut down Rust core, then exit
      await _rustDataSource.shutdown();
      await windowManager.destroy();
      return;
    }

    if (_minimizeToTray) {
      // Hide to tray instead of quitting
      await windowManager.hide();
    } else {
      // No tray → real quit
      await _realQuit();
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _realQuit() async {
    _forceQuit = true;
    await _trayService.dispose();
    await _rustDataSource.shutdown();
    await windowManager.destroy();
  }
}

/// Convenience function — kept for backward compatibility.
/// Prefer using [DesktopWindowManager] for full tray + lifecycle support.
Future<void> initDesktopWindow() async {
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
