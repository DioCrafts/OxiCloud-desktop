import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/entities/favorite_item.dart';
import '../blocs/recent/recent_bloc.dart';
import '../theme/oxicloud_colors.dart';

class RecentPage extends StatefulWidget {
  const RecentPage({super.key});

  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  @override
  void initState() {
    super.initState();
    context.read<RecentBloc>().add(const LoadRecent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RecentBloc>().add(const LoadRecent()),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Recent'),
                    content: const Text('Clear all recent file history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<RecentBloc>().add(const ClearRecentRequested());
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear history')),
            ],
          ),
        ],
      ),
      body: BlocBuilder<RecentBloc, RecentState>(
        builder: (context, state) {
          if (state is RecentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RecentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: OxiColors.error),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<RecentBloc>().add(const LoadRecent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is RecentLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: OxiColors.textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'No recent files',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: OxiColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Files you open will appear here',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: OxiColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: state.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return _buildRecentTile(item);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildRecentTile(RecentItem item) {
    return ListTile(
      leading: Icon(
        item.isFolder ? Icons.folder : Icons.insert_drive_file,
        color: item.isFolder ? OxiColors.primary : OxiColors.textSecondary,
      ),
      title: Text(item.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.path,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, color: OxiColors.textSecondary),
      ),
      trailing: Text(
        _formatTimestamp(item.accessedAt),
        style: TextStyle(fontSize: 11, color: OxiColors.textSecondary),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
