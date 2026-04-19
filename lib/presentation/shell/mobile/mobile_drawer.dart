import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';

class MobileDrawer extends ConsumerWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_outlined,
                      size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('OxiCloud',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const Divider(height: 1),

            // Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.search_outlined),
                    title: const Text('Search'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/search');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Shares'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/shares');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.music_note_outlined),
                    title: const Text('Music'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/playlists');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: const Text('Trash'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/trash');
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings_outlined),
                    title: const Text('Admin'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/admin');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Logout',
                  style: TextStyle(color: theme.colorScheme.error)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authRepositoryProvider).logout();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}
