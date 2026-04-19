import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/remote/favorites_remote_datasource.dart';
import '../mappers/file_mapper.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesRemoteDatasource _remote;

  FavoritesRepositoryImpl({required FavoritesRemoteDatasource remote})
      : _remote = remote;

  @override
  Future<List<FileEntity>> listFavorites() async {
    final dtos = await _remote.listFavorites();
    return FileMapper.fromDtoList(dtos);
  }

  @override
  Future<void> addFavorite(String itemType, String itemId) async {
    await _remote.addFavorite(itemType, itemId);
  }

  @override
  Future<void> removeFavorite(String itemType, String itemId) async {
    await _remote.removeFavorite(itemType, itemId);
  }
}
