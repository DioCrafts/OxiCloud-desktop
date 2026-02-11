import 'package:dartz/dartz.dart';

import '../entities/search_results.dart';
import '../errors/failures.dart';

/// Search repository port (domain interface).
abstract class SearchRepository {
  /// Simple text search.
  Future<Either<SearchFailure, SearchResults>> search(
    String query, {
    String? folderId,
    int limit = 100,
    int offset = 0,
  });

  /// Advanced search with multiple criteria.
  Future<Either<SearchFailure, SearchResults>> advancedSearch(
    SearchCriteria criteria,
  );
}
