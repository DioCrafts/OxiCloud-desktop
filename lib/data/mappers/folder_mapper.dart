import '../../domain/entities/folder_entity.dart';
import '../dtos/folders/folder_dtos.dart';

class FolderMapper {
  FolderMapper._();

  static FolderEntity fromDto(FolderResponseDto dto) {
    return FolderEntity(
      id: dto.id,
      name: dto.name,
      path: dto.path,
      parentId: dto.parentId,
      ownerId: dto.ownerId,
      isRoot: dto.isRoot ?? false,
      createdAt: dto.createdAt ?? DateTime.now(),
      modifiedAt: dto.modifiedAt ?? DateTime.now(),
    );
  }

  static List<FolderEntity> fromDtoList(List<FolderResponseDto> dtos) {
    return dtos.map(fromDto).toList();
  }
}
