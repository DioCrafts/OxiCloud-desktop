import '../entities/share_entity.dart';

abstract class ShareRepository {
  /// Create a share link.
  Future<ShareEntity> createShare({
    required String itemId,
    required String itemType,
    String? itemName,
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  });

  /// List all shares for the current user.
  Future<List<ShareEntity>> listShares();

  /// Get a share by ID.
  Future<ShareEntity> getShare(String id);

  /// Update a share.
  Future<ShareEntity> updateShare(
    String id, {
    String? password,
    DateTime? expiresAt,
    SharePermissions? permissions,
  });

  /// Delete a share.
  Future<void> deleteShare(String id);
}
