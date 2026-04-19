import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/file_entity.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/file_icon.dart';

// --- State ---

class RecentState {
  final List<FileEntity> items;
  final bool loading;
  final String? error;

  const RecentState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  RecentState copyWith({
    List<FileEntity>? items,
    bool? loading,
    String? error,
  }) {
    return RecentState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// --- Notifier ---

class RecentNotifier extends Notifier<RecentState> {
  @override
  RecentState build() => const RecentState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(recentRepositoryProvider).listRecent();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> clearRecent() async {
    await ref.read(recentRepositoryProvider).clearRecent();
    await load();
  }
}

final recentProvider =
    NotifierProvider<RecentNotifier, RecentState>(RecentNotifier.new);

// --- Page ---

class RecentPage extends ConsumerStatefulWidget {
  const RecentPage({super.key});

  @override
  ConsumerState<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends ConsumerState<RecentPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(recentProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recentProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.items.isEmpty) {
      body = const EmptyState(
        icon: Icons.access_time,
        title: 'No recent files',
        subtitle: 'Files you open will appear here',
      );
    } else {
      body = ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (_, i) {
          final file = state.items[i];
          return ListTile(
            leading: FileIcon(
                mimeType: file.mimeType,
                extension: file.extension,
                size: 32),
            title:
                Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                '${file.sizeFormatted} · ${_formatDate(file.modifiedAt)}'),
          );
        },
      );
    }

    return AdaptiveShell(
      currentPath: '/recent',
      title: 'Recent',
      itemCount: state.items.length,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(recentProvider.notifier).load(),
        ),
        if (state.items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear recent',
            onPressed: () => ref.read(recentProvider.notifier).clearRecent(),
          ),
      ],
      child: body,
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
