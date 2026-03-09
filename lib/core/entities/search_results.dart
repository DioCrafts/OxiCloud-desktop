import 'package:equatable/equatable.dart';

import 'file_item.dart';

// =============================================================================
// Search results entity
// =============================================================================

class SearchResults extends Equatable {
  const SearchResults({
    required this.files,
    required this.folders,
    required this.limit,
    required this.offset,
    required this.hasMore,
    this.totalCount,
  });

  final List<FileItem> files;
  final List<FolderItem> folders;
  final int? totalCount;
  final int limit;
  final int offset;
  final bool hasMore;

  int get count => files.length + folders.length;
  bool get isEmpty => files.isEmpty && folders.isEmpty;

  @override
  List<Object?> get props =>
      [files, folders, totalCount, limit, offset, hasMore];
}

// =============================================================================
// Search criteria value object (for advanced search)
// =============================================================================

class SearchCriteria extends Equatable {
  const SearchCriteria({
    this.nameContains,
    this.fileTypes,
    this.createdAfter,
    this.createdBefore,
    this.modifiedAfter,
    this.modifiedBefore,
    this.minSize,
    this.maxSize,
    this.folderId,
    this.recursive = true,
    this.limit = 100,
    this.offset = 0,
  });

  final String? nameContains;
  final List<String>? fileTypes;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final DateTime? modifiedAfter;
  final DateTime? modifiedBefore;
  final int? minSize;
  final int? maxSize;
  final String? folderId;
  final bool recursive;
  final int limit;
  final int offset;

  @override
  List<Object?> get props => [
        nameContains,
        fileTypes,
        createdAfter,
        createdBefore,
        modifiedAfter,
        modifiedBefore,
        minSize,
        maxSize,
        folderId,
        recursive,
        limit,
        offset,
      ];
}
