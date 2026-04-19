import '../entities/search_result_entity.dart';

class SearchCriteria {
  final String? nameContains;
  final List<String>? fileTypes;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final int? minSize;
  final int? maxSize;
  final String? folderId;
  final bool recursive;
  final int limit;
  final int offset;
  final String sortBy;

  const SearchCriteria({
    this.nameContains,
    this.fileTypes,
    this.createdAfter,
    this.createdBefore,
    this.modifiedAfter,
    this.modifiedBefore,
    this.minSize,
    this.maxSize,
    this.folderId,
    this.recursive = true,
    this.limit = 100,
    this.offset = 0,
    this.sortBy = 'relevance',
  });
}

abstract class SearchRepository {
  /// Simple search by query string.
  Future<List<SearchResultEntity>> search(String query);

  /// Search with advanced criteria.
  Future<List<SearchResultEntity>> advancedSearch(SearchCriteria criteria);

  /// Get autocomplete suggestions.
  Future<List<String>> suggest(String query);
}
