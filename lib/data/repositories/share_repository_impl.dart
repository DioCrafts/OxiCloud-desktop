import '../../domain/entities/share_entity.dart';
import '../../domain/repositories/share_repository.dart';
import '../datasources/remote/share_remote_datasource.dart';
import '../dtos/shares/share_dtos.dart';
import '../mappers/share_mapper.dart';

class ShareRepositoryImpl implements ShareRepository {
  final ShareRemoteDatasource _remote;

  ShareRepositoryImpl({required ShareRemoteDatasource remote})
      : _remote = remote;

  @override
  Future<ShareEntity> createShare({
    required String itemId,
    required String itemType,
    String? itemName,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  }) async {
    final dto = CreateShareRequestDto(
      itemId: itemId,
      itemType: itemType,
      itemName: itemName,
      password: password,
      expiresAt: expiresAt,
      permissions: permissions != null
          ? ShareMapper.permissionsToDto(permissions)
          : null,
    );
    final response = await _remote.createShare(dto);
    return ShareMapper.fromDto(response);
  }

  @override
  Future<List<ShareEntity>> listShares() async {
    final dtos = await _remote.listShares();
    return ShareMapper.fromDtoList(dtos);
  }

  @override
  Future<ShareEntity> getShare(String id) async {
    final dto = await _remote.getShare(id);
    return ShareMapper.fromDto(dto);
  }

  @override
  Future<ShareEntity> updateShare(
    String id, {
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  }) async {
    final dto = UpdateShareRequestDto(
      password: password,
      expiresAt: expiresAt,
      permissions: permissions != null
          ? ShareMapper.permissionsToDto(permissions)
          : null,
    );
    final response = await _remote.updateShare(id, dto);
    return ShareMapper.fromDto(response);
  }

  @override
  Future<void> deleteShare(String id) async {
    await _remote.deleteShare(id);
  }
}
