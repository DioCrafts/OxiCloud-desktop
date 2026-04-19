import '../../domain/entities/trash_item_entity.dart';
import '../dtos/trash/trash_dtos.dart';

class TrashMapper {
  TrashMapper._();

  static TrashItemEntity fromDto(TrashItemResponseDto dto) {
    return TrashItemEntity(
      id: dto.id,
      name: dto.name,
      itemType: dto.itemType,
      originalPath: dto.originalPath,
      size: dto.size,
      deletedAt: dto.deletedAt,
    );
  }

  static List<TrashItemEntity> fromDtoList(List<TrashItemResponseDto> dtos) {
    return dtos.map(fromDto).toList();
  }
}
