import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers.dart';
import '../../../data/datasources/remote/playlist_remote_datasource.dart';
import '../../shell/adaptive_shell.dart';

// --- State ---

class PlaylistsState {
  final List<PlaylistDto> playlists;
  final PlaylistDto? selected;
  final List<PlaylistTrackDto> tracks;
  final bool loading;
  final String? error;

  const PlaylistsState({
    this.playlists = const [],
    this.selected,
    this.tracks = const [],
    this.loading = false,
    this.error,
  });

  PlaylistsState copyWith({
    List<PlaylistDto>? playlists,
    PlaylistDto? selected,
    List<PlaylistTrackDto>? tracks,
    bool? loading,
    String? error,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      selected: selected ?? this.selected,
      tracks: tracks ?? this.tracks,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

// --- Notifier ---

class PlaylistsNotifier extends Notifier<PlaylistsState> {
  @override
  PlaylistsState build() => const PlaylistsState();

  PlaylistRemoteDatasource get _ds =>
      ref.read(playlistRemoteDatasourceProvider);

  Future<void> loadPlaylists() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final playlists = await _ds.getAll();
      state = state.copyWith(playlists: playlists, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> selectPlaylist(PlaylistDto playlist) async {
    state = state.copyWith(selected: playlist, loading: true, error: null);
    try {
      final tracks = await _ds.getTracks(playlist.id);
      state = state.copyWith(tracks: tracks, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> createPlaylist(String name, String? description) async {
    try {
      await _ds.create(name: name, description: description);
      await loadPlaylists();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deletePlaylist(String id) async {
    try {
      await _ds.delete(id);
      state = state.copyWith(
        selected: state.selected?.id == id ? null : state.selected,
        tracks: state.selected?.id == id ? [] : state.tracks,
      );
      await loadPlaylists();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeTrack(String fileId) async {
    final sel = state.selected;
    if (sel == null) return;
    try {
      await _ds.removeTrack(sel.id, fileId);
      await selectPlaylist(sel);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearSelection() {
    state = state.copyWith(selected: null, tracks: []);
  }
}

final playlistsProvider = NotifierProvider<PlaylistsNotifier, PlaylistsState>(
  PlaylistsNotifier.new,
);

// --- UI ---

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(playlistsProvider.notifier).loadPlaylists(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playlistsProvider);
    final theme = Theme.of(context);

    return AdaptiveShell(
      currentPath: '/playlists',
      title: 'Music',
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      child: state.selected != null
          ? _PlaylistDetail(
              playlist: state.selected!,
              tracks: state.tracks,
              loading: state.loading,
              onBack: () =>
                  ref.read(playlistsProvider.notifier).clearSelection(),
              onRemoveTrack: (fileId) =>
                  ref.read(playlistsProvider.notifier).removeTrack(fileId),
            )
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.music_note_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('No playlists yet', style: theme.textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.playlists.length,
              itemBuilder: (context, i) {
                final p = state.playlists[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.queue_music),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.trackCount} tracks • ${_formatDuration(p.totalDuration)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(playlistsProvider.notifier)
                          .deletePlaylist(p.id),
                    ),
                    onTap: () =>
                        ref.read(playlistsProvider.notifier).selectPlaylist(p),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result == true && nameCtrl.text.isNotEmpty) {
      ref
          .read(playlistsProvider.notifier)
          .createPlaylist(
            nameCtrl.text.trim(),
            descCtrl.text.isEmpty ? null : descCtrl.text.trim(),
          );
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }
}

class _PlaylistDetail extends StatelessWidget {
  final PlaylistDto playlist;
  final List<PlaylistTrackDto> tracks;
  final bool loading;
  final VoidCallback onBack;
  final ValueChanged<String> onRemoveTrack;

  const _PlaylistDetail({
    required this.playlist,
    required this.tracks,
    required this.loading,
    required this.onBack,
    required this.onRemoveTrack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(playlist.name, style: theme.textTheme.titleLarge),
                    if (playlist.description != null)
                      Text(
                        playlist.description!,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (tracks.isEmpty)
          const Expanded(
            child: Center(child: Text('No tracks in this playlist')),
          )
        else
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tracks.length,
              onReorder: (_, __) {}, // TODO: wire reorder
              itemBuilder: (context, i) {
                final t = tracks[i];
                return ListTile(
                  key: ValueKey(t.fileId),
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(t.title ?? t.filename),
                  subtitle: Text(
                    [
                      if (t.artist != null) t.artist!,
                      if (t.album != null) t.album!,
                      if (t.duration != null)
                        '${t.duration! ~/ 60}:${(t.duration! % 60).toString().padLeft(2, '0')}',
                    ].join(' • '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onRemoveTrack(t.fileId),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
