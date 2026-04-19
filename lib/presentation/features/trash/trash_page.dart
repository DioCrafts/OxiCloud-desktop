import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/trash_item_entity.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/file_icon.dart';

// --- State ---

class TrashState {
  final List<TrashItemEntity> items;
  final bool loading;
  final String? error;

  const TrashState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  TrashState copyWith({
    List<TrashItemEntity>? items,
    bool? loading,
    String? error,
  }) {
    return TrashState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// --- Notifier ---

class TrashNotifier extends Notifier<TrashState> {
  @override
  TrashState build() => const TrashState();

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final items = await ref.read(trashRepositoryProvider).listTrash();
      state = state.copyWith(items: items, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> restore(String id) async {
    await ref.read(trashRepositoryProvider).restoreItem(id);
    await load();
  }

  Future<void> permanentlyDelete(String id) async {
    await ref.read(trashRepositoryProvider).permanentlyDelete(id);
    await load();
  }

  Future<void> emptyTrash() async {
    await ref.read(trashRepositoryProvider).emptyTrash();
    await load();
  }
}

final trashProvider =
    NotifierProvider<TrashNotifier, TrashState>(TrashNotifier.new);

// --- Page ---

class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(trashProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trashProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.items.isEmpty) {
      body = const EmptyState(
        icon: Icons.delete_outline,
        title: 'Trash is empty',
        subtitle: 'Deleted files will appear here',
      );
    } else {
      body = ListView.builder(
        itemCount: state.items.length,
        itemBuilder: (_, i) => _TrashItemTile(
          item: state.items[i],
          onRestore: () =>
              ref.read(trashProvider.notifier).restore(state.items[i].id),
          onDelete: () async {
            final confirm = await AppDialogs.showConfirm(
              context: context,
              title: 'Permanently delete "${state.items[i].name}"?',
              message: 'This cannot be undone.',
              isDanger: true,
            );
            if (confirm) {
              ref
                  .read(trashProvider.notifier)
                  .permanentlyDelete(state.items[i].id);
            }
          },
        ),
      );
    }

    return AdaptiveShell(
      currentPath: '/trash',
      title: 'Trash',
      itemCount: state.items.length,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(trashProvider.notifier).load(),
        ),
        if (state.items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await AppDialogs.showConfirm(
                context: context,
                title: 'Empty trash?',
                message:
                    'All ${state.items.length} items will be permanently deleted.',
                isDanger: true,
              );
              if (confirm) ref.read(trashProvider.notifier).emptyTrash();
            },
          ),
      ],
      child: body,
    );
  }
}

class _TrashItemTile extends StatelessWidget {
  final TrashItemEntity item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _TrashItemTile({
    required this.item,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: item.isFolder
          ? Icon(Icons.folder, color: Colors.amber.shade700)
          : const FileIcon(mimeType: 'application/octet-stream', size: 32),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        'Deleted ${_formatDate(item.deletedAt)} · ${item.originalPath}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore',
            onPressed: onRestore,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete permanently',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }
}
