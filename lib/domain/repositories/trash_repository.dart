import '../entities/trash_item_entity.dart';

abstract class TrashRepository {
  /// List all items in trash.
  Future<List<TrashItemEntity>> listTrash();

  /// Restore an item from trash.
  Future<void> restoreItem(String id);

  /// Permanently delete an item.
  Future<void> permanentlyDelete(String id);

  /// Empty the entire trash.
  Future<void> emptyTrash();
}
