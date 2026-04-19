import '../../domain/entities/share_entity.dart';
import '../dtos/shares/share_dtos.dart';

class ShareMapper {
  ShareMapper._();

  static ShareEntity fromDto(ShareResponseDto dto) {
    return ShareEntity(
      id: dto.id,
      itemId: dto.itemId,
      itemName: dto.itemName,
      itemType: dto.itemType,
      token: dto.token,
      url: dto.url,
      hasPassword: dto.hasPassword,
      expiresAt: dto.expiresAt,
      permissions: SharePermissions(
        read: dto.permissions.read,
        write: dto.permissions.write,
        reshare: dto.permissions.reshare,
      ),
      createdAt: dto.createdAt,
      createdBy: dto.createdBy,
      accessCount: dto.accessCount,
    );
  }

  static List<ShareEntity> fromDtoList(List<ShareResponseDto> dtos) {
    return dtos.map(fromDto).toList();
  }

  static SharePermissionsDto permissionsToDto(SharePermissions? perms) {
    if (perms == null) return const SharePermissionsDto();
    return SharePermissionsDto(
      read: perms.read,
      write: perms.write,
      reshare: perms.reshare,
    );
  }
}
