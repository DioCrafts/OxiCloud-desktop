import '../../domain/entities/trash_item_entity.dart';
import '../../domain/repositories/trash_repository.dart';
import '../datasources/remote/trash_remote_datasource.dart';
import '../mappers/trash_mapper.dart';

class TrashRepositoryImpl implements TrashRepository {
  final TrashRemoteDatasource _remote;

  TrashRepositoryImpl({required TrashRemoteDatasource remote})
    : _remote = remote;

  @override
  Future<List<TrashItemEntity>> listTrash() async {
    final dtos = await _remote.listTrash();
    return TrashMapper.fromDtoList(dtos);
  }

  @override
  Future<void> restoreItem(String id) async {
    await _remote.restoreItem(id);
  }

  @override
  Future<void> permanentlyDelete(String id) async {
    await _remote.permanentlyDelete(id);
  }

  @override
  Future<void> emptyTrash() async {
    await _remote.emptyTrash();
  }
}
