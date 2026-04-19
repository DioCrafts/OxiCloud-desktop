import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/search_result_entity.dart';
import '../../../../domain/repositories/search_repository.dart';
import '../../../../providers.dart';
import '../../shell/adaptive_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/file_icon.dart';

// --- State ---

class SearchState {
  final List<SearchResultEntity> results;
  final List<String> suggestions;
  final bool loading;
  final String? error;
  final String query;

  const SearchState({
    this.results = const [],
    this.suggestions = const [],
    this.loading = false,
    this.error,
    this.query = '',
  });

  SearchState copyWith({
    List<SearchResultEntity>? results,
    List<String>? suggestions,
    bool? loading,
    String? error,
    String? query,
  }) {
    return SearchState(
      results: results ?? this.results,
      suggestions: suggestions ?? this.suggestions,
      loading: loading ?? this.loading,
      error: error,
      query: query ?? this.query,
    );
  }
}

// --- Notifier ---

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(loading: true, error: null, query: query);
    try {
      final results = await ref.read(searchRepositoryProvider).search(query);
      state = state.copyWith(results: results, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> advancedSearch(SearchCriteria criteria) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final results =
          await ref.read(searchRepositoryProvider).advancedSearch(criteria);
      state = state.copyWith(results: results, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> suggest(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }
    try {
      final suggestions =
          await ref.read(searchRepositoryProvider).suggest(query);
      state = state.copyWith(suggestions: suggestions);
    } catch (_) {}
  }
}

final searchProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);

// --- Page ---

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    Widget body;
    if (state.loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      body = Center(child: Text('Error: ${state.error}'));
    } else if (state.query.isEmpty) {
      body = const EmptyState(
        icon: Icons.search,
        title: 'Search your files',
        subtitle: 'Type a query above to find files and folders',
      );
    } else if (state.results.isEmpty) {
      body = EmptyState(
        icon: Icons.search_off,
        title: 'No results',
        subtitle: 'No items match "${state.query}"',
      );
    } else {
      body = ListView.builder(
        itemCount: state.results.length,
        itemBuilder: (_, i) {
          final item = state.results[i];
          return ListTile(
            leading: item.isFolder
                ? Icon(Icons.folder, color: Colors.amber.shade700)
                : FileIcon(mimeType: item.mimeType, size: 32),
            title:
                Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle:
                Text(item.path, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: item.relevanceScore != null
                ? Text(
                    '${(item.relevanceScore! * 100).toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null,
          );
        },
      );
    }

    return AdaptiveShell(
      currentPath: '/search',
      title: 'Search',
      itemCount: state.results.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search files and folders…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchProvider.notifier).search('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (q) =>
                  ref.read(searchProvider.notifier).search(q),
              onChanged: (q) =>
                  ref.read(searchProvider.notifier).suggest(q),
            ),
          ),
          // Suggestions chips
          if (state.suggestions.isNotEmpty && state.query.isEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: state.suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ActionChip(
                  label: Text(state.suggestions[i]),
                  onPressed: () {
                    _controller.text = state.suggestions[i];
                    ref
                        .read(searchProvider.notifier)
                        .search(state.suggestions[i]);
                  },
                ),
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
