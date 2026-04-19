import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sync/sync_engine.dart';
import '../../../providers.dart';
import '../../widgets/sync_status_indicator.dart';

class DesktopSidebar extends ConsumerWidget {
  final String currentPath;

  const DesktopSidebar({super.key, required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final syncEngine = ref.watch(syncEngineProvider);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Logo / Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.cloud_outlined,
                    size: 28, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('OxiCloud',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Divider(),

          // Navigation
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                _NavItem(
                  icon: Icons.folder_outlined,
                  selectedIcon: Icons.folder,
                  label: 'Files',
                  isSelected: currentPath.startsWith('/files'),
                  onTap: () => context.go('/files'),
                ),
                _NavItem(
                  icon: Icons.star_outline,
                  selectedIcon: Icons.star,
                  label: 'Favorites',
                  isSelected: currentPath == '/favorites',
                  onTap: () => context.go('/favorites'),
                ),
                _NavItem(
                  icon: Icons.access_time,
                  selectedIcon: Icons.access_time_filled,
                  label: 'Recent',
                  isSelected: currentPath == '/recent',
                  onTap: () => context.go('/recent'),
                ),
                _NavItem(
                  icon: Icons.photo_library_outlined,
                  selectedIcon: Icons.photo_library,
                  label: 'Photos',
                  isSelected: currentPath == '/photos',
                  onTap: () => context.go('/photos'),
                ),
                _NavItem(
                  icon: Icons.search_outlined,
                  selectedIcon: Icons.search,
                  label: 'Search',
                  isSelected: currentPath == '/search',
                  onTap: () => context.go('/search'),
                ),
                const Divider(height: 24),
                _NavItem(
                  icon: Icons.share_outlined,
                  selectedIcon: Icons.share,
                  label: 'Shares',
                  isSelected: currentPath == '/shares',
                  onTap: () => context.go('/shares'),
                ),
                _NavItem(
                  icon: Icons.music_note_outlined,
                  selectedIcon: Icons.music_note,
                  label: 'Music',
                  isSelected: currentPath == '/playlists',
                  onTap: () => context.go('/playlists'),
                ),
                _NavItem(
                  icon: Icons.delete_outline,
                  selectedIcon: Icons.delete,
                  label: 'Trash',
                  isSelected: currentPath == '/trash',
                  onTap: () => context.go('/trash'),
                ),
                const Divider(height: 24),
                _NavItem(
                  icon: Icons.admin_panel_settings_outlined,
                  selectedIcon: Icons.admin_panel_settings,
                  label: 'Admin',
                  isSelected: currentPath == '/admin',
                  onTap: () => context.go('/admin'),
                ),
                _NavItem(
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings,
                  label: 'Settings',
                  isSelected: currentPath == '/settings',
                  onTap: () => context.go('/settings'),
                ),
              ],
            ),
          ),

          // Sync status footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: ListenableBuilder(
              listenable: syncEngine,
              builder: (context, _) => SyncStatusIndicator(
                status: syncEngine.status,
                pendingCount: syncEngine.pendingCount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : null,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
