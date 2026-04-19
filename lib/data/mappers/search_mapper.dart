import '../../domain/entities/search_result_entity.dart';
import '../dtos/search/search_dtos.dart';

class SearchMapper {
  SearchMapper._();

  static SearchResultEntity fromDto(SearchResultResponseDto dto) {
    return SearchResultEntity(
      id: dto.id,
      name: dto.name,
      path: dto.path,
      type: dto.type,
      mimeType: dto.mimeType,
      size: dto.size,
      relevanceScore: dto.relevanceScore,
      modifiedAt: dto.modifiedAt,
    );
  }

  static List<SearchResultEntity> fromDtoList(
    List<SearchResultResponseDto> dtos,
  ) {
    return dtos.map(fromDto).toList();
  }
}
