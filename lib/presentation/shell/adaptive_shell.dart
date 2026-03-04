import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/repositories/sync_repository.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/sync/sync_bloc.dart';
import '../pages/favorites_page.dart';
import '../pages/file_browser_page.dart';
import '../pages/home_page.dart';
import '../pages/recent_page.dart';
import '../pages/search_page.dart';
import '../pages/settings_page.dart';
import '../pages/shares_page.dart';
import '../pages/trash_page.dart';
import '../theme/oxicloud_colors.dart';

// =============================================================================
// Navigation destinations
// =============================================================================

/// Logical destinations used by both desktop and mobile shells.
enum ShellDestination { home, files, favorites, recent, search, shares, trash, settings }

// =============================================================================
// ShellScope — lets child pages trigger tab switches
// =============================================================================

class ShellScope extends InheritedWidget {
  final void Function(ShellDestination destination) navigateTo;

  const ShellScope({
    super.key,
    required this.navigateTo,
    required super.child,
  });

  /// Returns null when the widget is not inside a shell (standalone page).
  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  static ShellScope of(BuildContext context) {
    final s = maybeOf(context);
    assert(s != null, 'ShellScope not found — are you inside AdaptiveShell?');
    return s!;
  }

  @override
  bool updateShouldNotify(ShellScope old) => false;
}

// =============================================================================
// AdaptiveShell — root widget that picks desktop or mobile layout
// =============================================================================

class AdaptiveShell extends StatefulWidget {
  const AdaptiveShell({super.key});

  @override
  State<AdaptiveShell> createState() => _AdaptiveShellState();
}

class _AdaptiveShellState extends State<AdaptiveShell> {
  ShellDestination _selected = ShellDestination.home;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  void _onNavigate(ShellDestination dest) {
    // On mobile, some pages are not in bottom nav → push as standalone
    if (!_isDesktop) {
      if (dest == ShellDestination.trash) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TrashPage()),
        );
        return;
      }
      if (dest == ShellDestination.favorites) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FavoritesPage()),
        );
        return;
      }
      if (dest == ShellDestination.recent) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecentPage()),
        );
        return;
      }
    }
    setState(() => _selected = dest);
  }

  // Order MUST match ShellDestination.values index
  late final List<Widget> _pages = [
    const HomePage(),             // 0 — home
    const FileBrowserPage(),      // 1 — files
    const FavoritesPage(),        // 2 — favorites
    const RecentPage(),           // 3 — recent
    const SearchPage(),           // 4 — search
    const SharesPage(),           // 5 — shares
    const TrashPage(),            // 6 — trash  (desktop tab, mobile push)
    BlocProvider(                  // 7 — settings
      create: (ctx) => SettingsBloc(ctx.read<SyncRepository>()),
      child: const SettingsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ShellScope(
      navigateTo: _onNavigate,
      child: _isDesktop
          ? _DesktopLayout(
              selected: _selected,
              onSelected: _onNavigate,
              pages: _pages,
            )
          : _MobileLayout(
              selected: _selected,
              onSelected: _onNavigate,
              pages: _pages,
            ),
    );
  }
}

// =============================================================================
// Desktop — NavigationRail + content
// =============================================================================

class _DesktopLayout extends StatelessWidget {
  final ShellDestination selected;
  final ValueChanged<ShellDestination> onSelected;
  final List<Widget> pages;

  const _DesktopLayout({
    required this.selected,
    required this.onSelected,
    required this.pages,
  });

  // Desktop shows all 6 destinations
  static const _destinations = ShellDestination.values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final railIndex = _destinations.indexOf(selected);

    return Scaffold(
      body: Row(
        children: [
          // ── Navigation rail ──────────────────────────────────────────
          NavigationRail(
            selectedIndex: railIndex,
            onDestinationSelected: (i) => onSelected(_destinations[i]),
            labelType: NavigationRailLabelType.all,
            backgroundColor: theme.colorScheme.surface,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.cloud, size: 32, color: OxiColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    'OxiCloud',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: OxiColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            trailing: Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Divider(indent: 12, endIndent: 12),
                  _DesktopSyncIndicator(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder_outlined),
                selectedIcon: Icon(Icons.folder),
                label: Text('Files'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: Text('Favorites'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.history_outlined),
                selectedIcon: Icon(Icons.history),
                label: Text('Recent'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.search),
                selectedIcon: Icon(Icons.search),
                label: Text('Search'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.link_outlined),
                selectedIcon: Icon(Icons.link),
                label: Text('Shares'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.delete_outline),
                selectedIcon: Icon(Icons.delete),
                label: Text('Trash'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // ── Content ──────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: selected.index,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mobile — NavigationBar (Material 3 bottom nav)
// =============================================================================

class _MobileLayout extends StatelessWidget {
  final ShellDestination selected;
  final ValueChanged<ShellDestination> onSelected;
  final List<Widget> pages;

  const _MobileLayout({
    required this.selected,
    required this.onSelected,
    required this.pages,
  });

  // Mobile shows 5 destinations (Trash, Favorites, Recent accessed via Home)
  static const _navDests = [
    ShellDestination.home,
    ShellDestination.files,
    ShellDestination.search,
    ShellDestination.shares,
    ShellDestination.settings,
  ];

  @override
  Widget build(BuildContext context) {
    // If current selection isn't in the mobile nav (e.g. trash), fallback to 0
    final bottomIndex = _navDests.indexOf(selected);
    final safeIndex = bottomIndex >= 0 ? bottomIndex : 0;

    return Scaffold(
      body: IndexedStack(
        index: selected.index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIndex,
        onDestinationSelected: (i) => onSelected(_navDests[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.link_outlined),
            selectedIcon: Icon(Icons.link),
            label: 'Shares',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Desktop sync indicator — compact widget in the rail trailing area
// =============================================================================

class _DesktopSyncIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
      builder: (context, state) {
        IconData icon;
        Color color;
        String tooltip;

        if (state is SyncInProgress) {
          icon = Icons.sync;
          color = OxiColors.primary;
          tooltip = 'Syncing…';
        } else if (state is SyncError) {
          icon = Icons.cloud_off;
          color = Colors.red;
          tooltip = 'Sync error';
        } else if (state is SyncPaused) {
          icon = Icons.pause_circle_outline;
          color = OxiColors.textSecondary;
          tooltip = 'Paused';
        } else {
          icon = Icons.cloud_done_outlined;
          color = OxiColors.success;
          tooltip = 'Up to date';
        }

        return Tooltip(
          message: tooltip,
          child: Icon(icon, size: 20, color: color),
        );
      },
    );
  }
}
