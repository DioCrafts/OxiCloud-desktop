import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/search_results.dart';
import '../../../core/repositories/search_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchRepository _repository;

  SearchBloc(this._repository) : super(const SearchInitial()) {
    on<SearchQuerySubmitted>(_onSearch);
    on<AdvancedSearchSubmitted>(_onAdvancedSearch);
    on<SearchCleared>(_onCleared);
    on<SearchLoadMore>(_onLoadMore);
  }

  String _lastQuery = '';
  String? _lastFolderId;

  Future<void> _onSearch(
    SearchQuerySubmitted event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }
    _lastQuery = event.query;
    _lastFolderId = event.folderId;
    emit(const SearchLoading());
    final result = await _repository.search(
      event.query,
      folderId: event.folderId,
      limit: 50,
      offset: 0,
    );
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (results) => emit(SearchLoaded(results)),
    );
  }

  Future<void> _onAdvancedSearch(
    AdvancedSearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());
    final result = await _repository.advancedSearch(event.criteria);
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (results) => emit(SearchLoaded(results)),
    );
  }

  Future<void> _onLoadMore(
    SearchLoadMore event,
    Emitter<SearchState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SearchLoaded || !currentState.results.hasMore) {
      return;
    }
    final nextOffset =
        currentState.results.offset + currentState.results.limit;
    final result = await _repository.search(
      _lastQuery,
      folderId: _lastFolderId,
      limit: 50,
      offset: nextOffset,
    );
    result.fold(
      (failure) => emit(SearchError(failure.message)),
      (moreResults) {
        final merged = SearchResults(
          files: [...currentState.results.files, ...moreResults.files],
          folders: [
            ...currentState.results.folders,
            ...moreResults.folders,
          ],
          totalCount: moreResults.totalCount,
          limit: moreResults.limit,
          offset: moreResults.offset,
          hasMore: moreResults.hasMore,
        );
        emit(SearchLoaded(merged));
      },
    );
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    _lastQuery = '';
    _lastFolderId = null;
    emit(const SearchInitial());
  }
}
