import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../providers.dart';
import '../../widgets/breadcrumb_bar.dart';

class DesktopToolbar extends ConsumerWidget {
  final List<BreadcrumbItem> breadcrumbs;
  final VoidCallback? onRefresh;
  final VoidCallback? onNewFolder;
  final VoidCallback? onUpload;
  final ValueChanged<String>? onSearch;

  const DesktopToolbar({
    super.key,
    required this.breadcrumbs,
    this.onRefresh,
    this.onNewFolder,
    this.onUpload,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(
            child: BreadcrumbBar(items: breadcrumbs),
          ),

          // Search
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              onSubmitted: onSearch,
            ),
          ),

          const SizedBox(width: 8),

          // Actions
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined, size: 20),
            tooltip: 'New folder',
            onPressed: onNewFolder,
          ),
          IconButton(
            icon: const Icon(Icons.upload_file, size: 20),
            tooltip: 'Upload files',
            onPressed: onUpload,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
            onPressed: onRefresh,
          ),

          const SizedBox(width: 4),
          const VerticalDivider(indent: 12, endIndent: 12),
          const SizedBox(width: 4),

          // User menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            tooltip: 'Account',
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(authRepositoryProvider).logout();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 18),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
