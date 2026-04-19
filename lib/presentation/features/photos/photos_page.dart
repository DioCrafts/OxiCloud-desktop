import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../../domain/entities/file_entity.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/empty_state.dart';

// --- State ---

class PhotosState {
  final List<FileEntity> photos;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int? nextCursor;
  final bool hasMore;

  const PhotosState({
    this.photos = const [],
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.nextCursor,
    this.hasMore = true,
  });

  PhotosState copyWith({
    List<FileEntity>? photos,
    bool? loading,
    bool? loadingMore,
    String? error,
    int? nextCursor,
    bool? hasMore,
  }) {
    return PhotosState(
      photos: photos ?? this.photos,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: error,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

// --- Notifier ---

class PhotosNotifier extends Notifier<PhotosState> {
  @override
  PhotosState build() => const PhotosState();

  Future<void> load() async {
    state = const PhotosState(loading: true);
    try {
      final result =
          await ref.read(photosRepositoryProvider).listPhotos(limit: 100);
      state = PhotosState(
        photos: result.photos,
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
      );
    } catch (e) {
      state = PhotosState(error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.nextCursor == null) return;
    state = state.copyWith(loadingMore: true);
    try {
      final result = await ref
          .read(photosRepositoryProvider)
          .listPhotos(before: state.nextCursor, limit: 100);
      state = state.copyWith(
        photos: [...state.photos, ...result.photos],
        nextCursor: result.nextCursor,
        hasMore: result.nextCursor != null,
        loadingMore: false,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }
}

final photosProvider =
    NotifierProvider<PhotosNotifier, PhotosState>(PhotosNotifier.new);

// Thumbnail cache provider — caches loaded thumbnails by file id
final _thumbnailCacheProvider =
    StateProvider<Map<String, Uint8List>>((ref) => {});

// --- Page ---

class PhotosPage extends ConsumerStatefulWidget {
  const PhotosPage({super.key});

  @override
  ConsumerState<PhotosPage> createState() => _PhotosPageState();
}

class _PhotosPageState extends ConsumerState<PhotosPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(photosProvider.notifier).load());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(photosProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photosProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null && state.photos.isEmpty) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.photos.isEmpty) {
      body = const EmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No photos yet',
        subtitle: 'Upload images to see them here',
      );
    } else {
      body = _buildGallery(state);
    }

    return AdaptiveShell(
      currentPath: '/photos',
      title: 'Photos',
      itemCount: state.photos.length,
      mobileActions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(photosProvider.notifier).load(),
        ),
      ],
      child: body,
    );
  }

  Widget _buildGallery(PhotosState state) {
    // Group photos by month
    final groups = _groupByMonth(state.photos);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        for (final group in groups) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                group.label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _PhotoThumbnail(
                  photo: group.photos[i],
                ),
                childCount: group.photos.length,
              ),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
            ),
          ),
        ],
        // Loading more indicator
        if (state.loadingMore)
          const SliverPadding(
            padding: EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  List<_PhotoGroup> _groupByMonth(List<FileEntity> photos) {
    final Map<String, List<FileEntity>> map = {};
    final months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    for (final photo in photos) {
      final dt = photo.modifiedAt;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      final label = '${months[dt.month]} ${dt.year}';
      map.putIfAbsent(label, () => []).add(photo);
      // We use label as key since photos arrive sorted from server
    }

    return map.entries
        .map((e) => _PhotoGroup(label: e.key, photos: e.value))
        .toList();
  }
}

class _PhotoGroup {
  final String label;
  final List<FileEntity> photos;

  const _PhotoGroup({required this.label, required this.photos});
}

// --- Thumbnail widget ---

class _PhotoThumbnail extends ConsumerStatefulWidget {
  final FileEntity photo;

  const _PhotoThumbnail({required this.photo});

  @override
  ConsumerState<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends ConsumerState<_PhotoThumbnail> {
  Uint8List? _bytes;
  bool _loading = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    final cache = ref.read(_thumbnailCacheProvider);
    final cached = cache[widget.photo.id];
    if (cached != null) {
      setState(() => _bytes = cached);
      return;
    }

    setState(() => _loading = true);
    try {
      final bytes = await ref
          .read(fileRepositoryProvider)
          .getThumbnail(widget.photo.id, size: '256');
      ref.read(_thumbnailCacheProvider.notifier).update(
            (state) => {...state, widget.photo.id: bytes},
          );
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_loading) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Failed or video without thumbnail
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          widget.photo.isVideo ? Icons.videocam : Icons.image,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
