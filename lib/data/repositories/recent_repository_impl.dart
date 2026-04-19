import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/recent_repository.dart';
import '../datasources/remote/recent_remote_datasource.dart';
import '../mappers/file_mapper.dart';

class RecentRepositoryImpl implements RecentRepository {
  final RecentRemoteDatasource _remote;

  RecentRepositoryImpl({required RecentRemoteDatasource remote})
    : _remote = remote;

  @override
  Future<List<FileEntity>> listRecent() async {
    final dtos = await _remote.listRecent();
    return FileMapper.fromDtoList(dtos);
  }

  @override
  Future<void> recordAccess(String itemType, String itemId) async {
    await _remote.recordAccess(itemType, itemId);
  }

  @override
  Future<void> clearRecent() async {
    await _remote.clearRecent();
  }
}
