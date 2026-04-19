import '../../domain/entities/file_entity.dart';
import '../dtos/files/file_dto.dart';

class FileMapper {
  FileMapper._();

  static FileEntity fromDto(FileResponseDto dto) {
    return FileEntity(
      id: dto.id,
      name: dto.name,
      path: dto.path,
      size: dto.size,
      mimeType: dto.mimeType,
      folderId: dto.folderId,
      ownerId: dto.ownerId,
      createdAt: dto.createdAt ?? DateTime.now(),
      modifiedAt: dto.modifiedAt ?? DateTime.now(),
    );
  }

  static List<FileEntity> fromDtoList(List<FileResponseDto> dtos) {
    return dtos.map(fromDto).toList();
  }

  static FileResponseDto toDto(FileEntity entity) {
    return FileResponseDto(
      id: entity.id,
      name: entity.name,
      path: entity.path,
      size: entity.size,
      mimeType: entity.mimeType,
      folderId: entity.folderId,
      ownerId: entity.ownerId,
      createdAt: entity.createdAt,
      modifiedAt: entity.modifiedAt,
    );
  }
}
