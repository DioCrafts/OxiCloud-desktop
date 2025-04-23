import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart' as file_entity;
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:oxicloud_desktop/domain/entities/trashed_item.dart';
import 'package:oxicloud_desktop/domain/repositories/trash_repository.dart';

/// Application service for trash operations
class TrashService {
  final TrashRepository _trashRepository;
  final Logger _logger = LoggingManager.getLogger('TrashService');
  
  /// Create a TrashService
  TrashService(this._trashRepository);
  
  /// List items in trash
  Future<List<TrashedItem>> listTrashedItems() async {
    try {
      return await _trashRepository.listTrashedItems();
    } catch (e) {
      _logger.warning('Failed to list trashed items: $e');
      rethrow;
    }
  }
  
  /// Get a trashed item by ID
  Future<TrashedItem> getTrashedItem(String trashedItemId) async {
    try {
      return await _trashRepository.getTrashedItem(trashedItemId);
    } catch (e) {
      _logger.warning('Failed to get trashed item: $trashedItemId - $e');
      rethrow;
    }
  }
  
  /// Move a file to trash
  Future<TrashedItem> moveFileToTrash(file_entity.File file) async {
    try {
      _logger.info('Moving file to trash: ${file.id} (${file.name})');
      return await _trashRepository.moveToTrash(file.id, false);
    } catch (e) {
      _logger.warning('Failed to move file to trash: ${file.id} - $e');
      rethrow;
    }
  }
  
  /// Move a folder to trash
  Future<TrashedItem> moveFolderToTrash(Folder folder) async {
    try {
      _logger.info('Moving folder to trash: ${folder.id} (${folder.name})');
      return await _trashRepository.moveToTrash(folder.id, true);
    } catch (e) {
      _logger.warning('Failed to move folder to trash: ${folder.id} - $e');
      rethrow;
    }
  }
  
  /// Move a storage item to trash
  Future<TrashedItem> moveItemToTrash(StorageItem item) async {
    try {
      _logger.info('Moving item to trash: ${item.id} (${item.name})');
      return await _trashRepository.moveToTrash(item.id, item.isFolder);
    } catch (e) {
      _logger.warning('Failed to move item to trash: ${item.id} - $e');
      rethrow;
    }
  }
  
  /// Restore an item from trash
  Future<bool> restoreFromTrash(String trashedItemId) async {
    try {
      _logger.info('Restoring item from trash: $trashedItemId');
      return await _trashRepository.restoreFromTrash(trashedItemId);
    } catch (e) {
      _logger.warning('Failed to restore item from trash: $trashedItemId - $e');
      rethrow;
    }
  }
  
  /// Restore an item from trash to a specific folder
  Future<bool> restoreFromTrashTo(String trashedItemId, String destinationFolderId) async {
    try {
      _logger.info('Restoring item from trash to folder: $trashedItemId, $destinationFolderId');
      return await _trashRepository.restoreFromTrashTo(trashedItemId, destinationFolderId);
    } catch (e) {
      _logger.warning('Failed to restore item from trash to folder: $trashedItemId, $destinationFolderId - $e');
      rethrow;
    }
  }
  
  /// Permanently delete an item from trash
  Future<bool> deletePermanently(String trashedItemId) async {
    try {
      _logger.info('Permanently deleting item from trash: $trashedItemId');
      return await _trashRepository.deletePermanently(trashedItemId);
    } catch (e) {
      _logger.warning('Failed to delete item permanently: $trashedItemId - $e');
      rethrow;
    }
  }
  
  /// Empty the trash (delete all items permanently)
  Future<int> emptyTrash() async {
    try {
      _logger.info('Emptying trash');
      return await _trashRepository.emptyTrash();
    } catch (e) {
      _logger.warning('Failed to empty trash: $e');
      rethrow;
    }
  }
  
  /// Get the expiration date for trashed items
  Future<int> getTrashExpirationDays() async {
    try {
      return await _trashRepository.getTrashExpirationDays();
    } catch (e) {
      _logger.warning('Failed to get trash expiration days: $e');
      rethrow;
    }
  }
  
  /// Extend expiration for a trashed item
  Future<bool> extendExpiration(String trashedItemId, int additionalDays) async {
    try {
      // Get the current item
      final item = await _trashRepository.getTrashedItem(trashedItemId);
      
      // Calculate new expiration date
      final newExpirationDate = item.expiresAt.add(Duration(days: additionalDays));
      
      _logger.info('Extending expiration for trashed item: $trashedItemId by $additionalDays days');
      return await _trashRepository.updateExpirationDate(trashedItemId, newExpirationDate);
    } catch (e) {
      _logger.warning('Failed to extend expiration for trashed item: $trashedItemId - $e');
      rethrow;
    }
  }
}