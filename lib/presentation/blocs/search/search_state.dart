part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchLoaded extends SearchState {
  final SearchResults results;

  const SearchLoaded(this.results);

  @override
  List<Object?> get props => [results];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
