import '../entities/file_entity.dart';

abstract class RecentRepository {
  /// List recent items.
  Future<List<FileEntity>> listRecent();

  /// Record item access (touch).
  Future<void> recordAccess(String itemType, String itemId);

  /// Clear all recent items.
  Future<void> clearRecent();
}
