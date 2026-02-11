import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';

/// Manages the system-tray icon, context menu and
/// window-close-to-tray behaviour on desktop platforms.
class SystemTrayService with TrayListener {
  final Logger _logger = Logger();

  /// Callbacks the host (main.dart) can register.
  VoidCallback? onShowWindow;
  VoidCallback? onSyncNow;
  VoidCallback? onQuit;

  bool _initialised = false;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Set up the tray icon and context menu.
  ///
  /// [iconAssetPath] is a Flutter asset key (e.g. `assets/icons/app_icon.png`).
  Future<void> init({String iconAssetPath = 'assets/icons/app_icon.png'}) async {
    if (_initialised) return;

    try {
      // tray_manager needs a real filesystem path, not an asset key.
      final iconPath = await _resolveIconPath(iconAssetPath);

      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('OxiCloud — Sync client');

      await _buildMenu();
      trayManager.addListener(this);

      _initialised = true;
      _logger.i('System tray initialised');
    } catch (e) {
      _logger.e('Failed to initialise system tray: $e');
    }
  }

  Future<void> dispose() async {
    if (!_initialised) return;
    trayManager.removeListener(this);
    await trayManager.destroy();
  }

  /// Update the tooltip text (e.g. to show sync progress).
  Future<void> setTooltip(String text) async {
    if (!_initialised) return;
    await trayManager.setToolTip(text);
  }

  // ── Menu ────────────────────────────────────────────────────────────────

  Future<void> _buildMenu() async {
    final menu = Menu(items: [
      MenuItem(key: 'show', label: 'Open OxiCloud'),
      MenuItem.separator(),
      MenuItem(key: 'sync_now', label: 'Sync Now'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  // ── TrayListener callbacks ──────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() {
    // Single click on tray icon → show window
    onShowWindow?.call();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        onShowWindow?.call();
      case 'sync_now':
        onSyncNow?.call();
      case 'quit':
        onQuit?.call();
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Resolve the asset icon to a real filesystem path that tray_manager
  /// can read. Tries platform-specific bundle paths first; falls back to
  /// copying from rootBundle into a temp file.
  Future<String> _resolveIconPath(String assetKey) async {
    // 1. Development: project-relative file exists
    final projectFile = File(assetKey);
    if (await projectFile.exists()) {
      return projectFile.absolute.path;
    }

    // 2. Platform bundle paths
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = [
      // Windows
      p.join(exeDir, 'data', 'flutter_assets', assetKey),
      // Linux
      p.join(exeDir, 'data', 'flutter_assets', assetKey),
      // macOS
      p.join(exeDir, '..', 'Frameworks', 'App.framework',
          'Resources', 'flutter_assets', assetKey),
    ];

    for (final candidate in candidates) {
      if (await File(candidate).exists()) return candidate;
    }

    // 3. Fallback: copy from rootBundle to temp
    try {
      final byteData = await rootBundle.load(assetKey);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'oxicloud_tray_icon.png'));
      await tempFile.writeAsBytes(
        byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ),
      );
      return tempFile.path;
    } catch (e) {
      _logger.w('Could not resolve tray icon: $e');
      return assetKey;
    }
  }
}
