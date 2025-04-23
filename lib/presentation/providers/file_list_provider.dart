import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/application/services/file_service.dart';
import 'package:oxicloud_desktop/application/services/folder_service.dart';
import 'package:oxicloud_desktop/application/services/trash_service.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';

/// Provider for file list state
final fileListProvider = StateNotifierProvider.family<FileListNotifier, AsyncValue<List<StorageItem>>, String>(
  (ref, folderId) => FileListNotifier(
    getIt<FileService>(),
    getIt<FolderService>(),
    getIt<TrashService>(),
    folderId,
  ),
);

/// Provider for thumbnail of a file
final fileThumbnailProvider = FutureProvider.family<Uint8List?, String>(
  (ref, fileId) async {
    return getIt<FileService>().getThumbnail(fileId);
  },
);

/// Provider for current folder path
final folderPathProvider = FutureProvider.family<List<String>, String>(
  (ref, folderId) async {
    final folders = await getIt<FolderService>().getFolderPath(folderId);
    return folders.map((folder) => folder.name).toList();
  },
);

/// Notifier for file list state
class FileListNotifier extends StateNotifier<AsyncValue<List<StorageItem>>> {
  final FileService _fileService;
  final FolderService _folderService;
  final TrashService _trashService;
  final String _folderId;
  final Logger _logger = LoggingManager.getLogger('FileListNotifier');
  
  /// Create a FileListNotifier
  FileListNotifier(this._fileService, this._folderService, this._trashService, this._folderId)
      : super(const AsyncValue.loading()) {
    _loadFolderContents();
  }
  
  /// Load folder contents
  Future<void> _loadFolderContents() async {
    state = const AsyncValue.loading();
    
    try {
      final items = await _folderService.listFolderContents(_folderId);
      
      // Sort items: folders first, then files, alphabetically
      items.sort((a, b) {
        if (a.type != b.type) {
          return a.type == ItemType.folder ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      state = AsyncValue.data(items);
    } catch (e, stack) {
      _logger.warning('Failed to load folder contents: $_folderId - $e');
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Refresh folder contents
  Future<void> refresh() async {
    await _loadFolderContents();
  }
  
  /// Create a new folder
  Future<void> createFolder(String name) async {
    try {
      await _folderService.createFolder(
        parentFolderId: _folderId,
        name: name,
      );
      
      // Refresh folder contents
      await refresh();
    } catch (e) {
      _logger.warning('Failed to create folder: $name - $e');
      rethrow;
    }
  }
  
  /// Delete an item (move to trash)
  Future<void> deleteItem(StorageItem item) async {
    try {
      await _trashService.moveItemToTrash(item);
      
      // Refresh folder contents
      await refresh();
    } catch (e) {
      _logger.warning('Failed to move item to trash: ${item.id} - $e');
      rethrow;
    }
  }
  
  /// Delete an item permanently
  Future<void> deleteItemPermanently(StorageItem item) async {
    try {
      if (item.isFolder) {
        await _folderService.deleteFolder(item.id);
      } else {
        await _fileService.deleteFile(item.id);
      }
      
      // Refresh folder contents
      await refresh();
    } catch (e) {
      _logger.warning('Failed to delete item permanently: ${item.id} - $e');
      rethrow;
    }
  }
  
  /// Rename an item
  Future<void> renameItem(StorageItem item, String newName) async {
    try {
      if (item.isFolder) {
        await _folderService.renameFolder(item.id, newName);
      } else {
        await _fileService.renameFile(item.id, newName);
      }
      
      // Refresh folder contents
      await refresh();
    } catch (e) {
      _logger.warning('Failed to rename item: ${item.id} - $e');
      rethrow;
    }
  }
  
  /// Mark an item as favorite
  Future<void> markAsFavorite(StorageItem item, bool favorite) async {
    try {
      if (item.isFolder) {
        await _folderService.markAsFavorite(item.id, favorite);
      } else {
        await _fileService.markAsFavorite(item.id, favorite);
      }
      
      // Update item in state
      state.whenData((items) {
        final index = items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          final updatedItems = List<StorageItem>.from(items);
          updatedItems[index] = StorageItem(
            id: item.id,
            name: item.name,
            path: item.path,
            modifiedAt: item.modifiedAt,
            isShared: item.isShared,
            isFavorite: favorite,
            type: item.type,
            size: item.size,
            mimeType: item.mimeType,
          );
          state = AsyncValue.data(updatedItems);
        }
      });
    } catch (e) {
      _logger.warning('Failed to mark item as favorite: ${item.id} - $e');
      rethrow;
    }
  }
  
  /// Move an item to another folder
  Future<void> moveItem(StorageItem item, String newParentFolderId) async {
    try {
      if (item.isFolder) {
        await _folderService.moveFolder(item.id, newParentFolderId);
      } else {
        await _fileService.moveFile(item.id, newParentFolderId);
      }
      
      // Refresh folder contents
      await refresh();
    } catch (e) {
      _logger.warning('Failed to move item: ${item.id} - $e');
      rethrow;
    }
  }
}