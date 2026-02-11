part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchQuerySubmitted extends SearchEvent {
  final String query;
  final String? folderId;

  const SearchQuerySubmitted(this.query, {this.folderId});

  @override
  List<Object?> get props => [query, folderId];
}

class AdvancedSearchSubmitted extends SearchEvent {
  final SearchCriteria criteria;

  const AdvancedSearchSubmitted(this.criteria);

  @override
  List<Object?> get props => [criteria];
}

class SearchLoadMore extends SearchEvent {
  const SearchLoadMore();
}

class SearchCleared extends SearchEvent {
  const SearchCleared();
}
