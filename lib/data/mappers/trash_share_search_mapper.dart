import '../../core/entities/trash_item.dart';
import '../../core/entities/share_item.dart';
import '../../core/entities/search_results.dart';
import 'file_browser_mapper.dart';

// =============================================================================
// Trash mapper
// =============================================================================

class TrashMapper {
  const TrashMapper._();

  static TrashItem fromJson(Map<String, dynamic> json) {
    return TrashItem(
      id: json['id'] as String,
      originalId: json['original_id'] as String? ?? '',
      itemType: json['item_type'] as String? ?? 'file',
      name: json['name'] as String,
      originalPath: json['original_path'] as String? ?? '',
      trashedAt: _parseDateTime(json['trashed_at']),
      daysUntilDeletion: _parseInt(json['days_until_deletion']),
    );
  }

  static List<TrashItem> listFromJson(List<Map<String, dynamic>> list) {
    return list.map(fromJson).toList();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
    }
    return DateTime.now();
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

// =============================================================================
// Share mapper
// =============================================================================

class ShareMapper {
  const ShareMapper._();

  static ShareItem fromJson(Map<String, dynamic> json) {
    return ShareItem(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      itemType: json['item_type'] as String? ?? 'file',
      token: json['token'] as String,
      url: json['url'] as String? ?? '',
      hasPassword: json['has_password'] as bool? ?? false,
      expiresAt: _parseOptionalTimestamp(json['expires_at']),
      permissions: _permissionsFromJson(
        json['permissions'] as Map<String, dynamic>?,
      ),
      createdAt: _parseTimestamp(json['created_at']),
      createdBy: json['created_by'] as String? ?? '',
      accessCount: _parseInt(json['access_count']),
    );
  }

  static List<ShareItem> listFromJson(List<Map<String, dynamic>> list) {
    return list.map(fromJson).toList();
  }

  static SharePermissions _permissionsFromJson(Map<String, dynamic>? json) {
    if (json == null) return const SharePermissions();
    return SharePermissions(
      read: json['read'] as bool? ?? true,
      write: json['write'] as bool? ?? false,
      reshare: json['reshare'] as bool? ?? false,
    );
  }

  static Map<String, dynamic> permissionsToJson(SharePermissions p) => {
        'read': p.read,
        'write': p.write,
        'reshare': p.reshare,
      };

  static PaginationInfo paginationFromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: _parseInt(json['page']),
      pageSize: _parseInt(json['page_size']),
      totalItems: _parseInt(json['total_items']),
      totalPages: _parseInt(json['total_pages']),
      hasNext: json['has_next'] as bool? ?? false,
      hasPrev: json['has_prev'] as bool? ?? false,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value == null) return null;
    return _parseTimestamp(value);
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}

// =============================================================================
// Search mapper
// =============================================================================

class SearchMapper {
  const SearchMapper._();

  static SearchResults resultsFromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final rawFolders = json['folders'] as List<dynamic>? ?? [];

    return SearchResults(
      files: rawFiles
          .map((e) =>
              FileBrowserMapper.fileFromJson(e as Map<String, dynamic>))
          .toList(),
      folders: rawFolders
          .map((e) =>
              FileBrowserMapper.folderFromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['total_count'] as int?,
      limit: _parseInt(json['limit']),
      offset: _parseInt(json['offset']),
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  /// Convert [SearchCriteria] to JSON for POST /api/search/advanced.
  static Map<String, dynamic> criteriaToJson(SearchCriteria criteria) {
    return {
      if (criteria.nameContains != null && criteria.nameContains!.isNotEmpty)
        'name_contains': criteria.nameContains,
      if (criteria.fileTypes != null && criteria.fileTypes!.isNotEmpty)
        'file_types': criteria.fileTypes,
      if (criteria.createdAfter != null)
        'created_after':
            criteria.createdAfter!.millisecondsSinceEpoch ~/ 1000,
      if (criteria.createdBefore != null)
        'created_before':
            criteria.createdBefore!.millisecondsSinceEpoch ~/ 1000,
      if (criteria.modifiedAfter != null)
        'modified_after':
            criteria.modifiedAfter!.millisecondsSinceEpoch ~/ 1000,
      if (criteria.modifiedBefore != null)
        'modified_before':
            criteria.modifiedBefore!.millisecondsSinceEpoch ~/ 1000,
      if (criteria.minSize != null) 'min_size': criteria.minSize,
      if (criteria.maxSize != null) 'max_size': criteria.maxSize,
      if (criteria.folderId != null) 'folder_id': criteria.folderId,
      'recursive': criteria.recursive,
      'limit': criteria.limit,
      'offset': criteria.offset,
    };
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
}
