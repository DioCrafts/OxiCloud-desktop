import 'package:equatable/equatable.dart';

// =============================================================================
// Share entity
// =============================================================================

class ShareItem extends Equatable {
  const ShareItem({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.token,
    required this.url,
    required this.hasPassword,
    required this.permissions,
    required this.createdAt,
    required this.createdBy,
    required this.accessCount,
    this.expiresAt,
  });

  final String id;
  final String itemId;

  /// `"file"` or `"folder"`.
  final String itemType;
  final String token;
  final String url;
  final bool hasPassword;
  final DateTime? expiresAt;
  final SharePermissions permissions;
  final DateTime createdAt;
  final String createdBy;
  final int accessCount;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemType,
        token,
        url,
        hasPassword,
        expiresAt,
        permissions,
        createdAt,
        createdBy,
        accessCount,
      ];
}

// =============================================================================
// Share permissions value object
// =============================================================================

class SharePermissions extends Equatable {
  const SharePermissions({
    this.read = true,
    this.write = false,
    this.reshare = false,
  });

  final bool read;
  final bool write;
  final bool reshare;

  @override
  List<Object?> get props => [read, write, reshare];
}

// =============================================================================
// Pagination value object
// =============================================================================

class PaginationInfo extends Equatable {
  const PaginationInfo({
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  @override
  List<Object?> get props =>
      [page, pageSize, totalItems, totalPages, hasNext, hasPrev];
}

/// Paginated wrapper for any list.
class PaginatedResult<T> extends Equatable {
  const PaginatedResult({
    required this.items,
    required this.pagination,
  });

  final List<T> items;
  final PaginationInfo pagination;

  @override
  List<Object?> get props => [items, pagination];
}
