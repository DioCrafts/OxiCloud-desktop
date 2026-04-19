import 'package:equatable/equatable.dart';

class SearchResultEntity extends Equatable {
  final String id;
  final String name;
  final String path;
  final String type; // 'file' or 'folder'
  final String? mimeType;
  final int? size;
  final double? relevanceScore;
  final DateTime? modifiedAt;

  const SearchResultEntity({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    this.mimeType,
    this.size,
    this.relevanceScore,
    this.modifiedAt,
  });

  bool get isFile => type == 'file';
  bool get isFolder => type == 'folder';

  @override
  List<Object?> get props => [id, name, path, type];
}
