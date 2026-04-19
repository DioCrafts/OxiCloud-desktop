import '../../domain/entities/search_result_entity.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/remote/search_remote_datasource.dart';
import '../mappers/search_mapper.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDatasource _remote;

  SearchRepositoryImpl({required SearchRemoteDatasource remote})
      : _remote = remote;

  @override
  Future<List<SearchResultEntity>> search(String query) async {
    final dtos = await _remote.search(query);
    return SearchMapper.fromDtoList(dtos);
  }

  @override
  Future<List<SearchResultEntity>> advancedSearch(
      SearchCriteria criteria) async {
    final dtos = await _remote.advancedSearch(criteria);
    return SearchMapper.fromDtoList(dtos);
  }

  @override
  Future<List<String>> suggest(String query) async {
    return _remote.suggest(query);
  }
}
