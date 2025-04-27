import 'package:freezed_annotation/freezed_annotation.dart';

part 'file.freezed.dart';
part 'file.g.dart';

@freezed
class File with _$File {
  const factory File({
    required String id,
    required String name,
    required String path,
    required int size,
    required String mimeType,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentId,
    @Default(false) bool isFavorite,
    @Default(false) bool isShared,
    String? thumbnailUrl,
    String? downloadUrl,
  }) = _File;

  factory File.fromJson(Map<String, dynamic> json) => _$FileFromJson(json);
} 