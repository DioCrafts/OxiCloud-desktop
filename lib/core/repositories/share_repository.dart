import 'package:dartz/dartz.dart';

import '../entities/share_item.dart';
import '../errors/failures.dart';

/// Share repository port (domain interface).
abstract class ShareRepository {
  /// List shares owned by the current user (paginated).
  Future<Either<ShareFailure, PaginatedResult<ShareItem>>> listShares({
    int page = 1,
    int perPage = 20,
  });

  /// Get a single share by [id].
  Future<Either<ShareFailure, ShareItem>> getShare(String id);

  /// Create a new share link.
  Future<Either<ShareFailure, ShareItem>> createShare({
    required String itemId,
    required String itemType,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  });

  /// Update an existing share.
  Future<Either<ShareFailure, ShareItem>> updateShare({
    required String id,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  });

  /// Delete a share.
  Future<Either<ShareFailure, void>> deleteShare(String id);
}
