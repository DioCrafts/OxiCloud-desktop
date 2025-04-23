import 'package:oxicloud_desktop/domain/entities/trashed_item.dart';

/// Repository interface for trash operations
abstract class TrashRepository {
  /// List items in trash
  Future<List<TrashedItem>> listTrashedItems();
  
  /// Get a trashed item by ID
  Future<TrashedItem> getTrashedItem(String trashedItemId);
  
  /// Move an item to trash
  /// 
  /// Returns the trashed item
  Future<TrashedItem> moveToTrash(String itemId, bool isFolder);
  
  /// Restore an item from trash
  /// 
  /// Returns true if successful
  Future<bool> restoreFromTrash(String trashedItemId);
  
  /// Restore an item from trash to a specific folder
  /// 
  /// Returns true if successful
  Future<bool> restoreFromTrashTo(String trashedItemId, String destinationFolderId);
  
  /// Permanently delete an item from trash
  /// 
  /// Returns true if successful
  Future<bool> deletePermanently(String trashedItemId);
  
  /// Empty the trash (delete all items permanently)
  /// 
  /// Returns the number of items deleted
  Future<int> emptyTrash();
  
  /// Get the expiration date for trashed items
  /// 
  /// Returns the expiration date in days from the current date
  Future<int> getTrashExpirationDays();
  
  /// Update the expiration date for a trashed item
  /// 
  /// Returns true if successful
  Future<bool> updateExpirationDate(String trashedItemId, DateTime newExpirationDate);
}