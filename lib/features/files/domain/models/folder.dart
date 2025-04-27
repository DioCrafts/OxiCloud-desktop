import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder.freezed.dart';
part 'folder.g.dart';

@freezed
class Folder with _$Folder {
  const factory Folder({
    required String id,
    required String name,
    required String path,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? parentId,
    @Default(false) bool isFavorite,
    @Default(false) bool isShared,
    @Default(0) int itemCount,
  }) = _Folder;

  factory Folder.fromJson(Map<String, dynamic> json) => _$FolderFromJson(json);
} 