import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';
import 'package:oxicloud_desktop/domain/repositories/folder_repository.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';

/// Application service for folder operations
class FolderService {
  final FolderRepository _folderRepository;
  final ResourceManager _resourceManager;
  final Logger _logger = LoggingManager.getLogger('FolderService');
  
  /// Create a FolderService
  FolderService(this._folderRepository, this._resourceManager);
  
  /// Get a folder by ID
  Future<Folder> getFolder(String folderId) async {
    try {
      return await _folderRepository.getFolder(folderId);
    } catch (e) {
      _logger.warning('Failed to get folder: $folderId - $e');
      rethrow;
    }
  }
  
  /// Get the root folder
  Future<Folder> getRootFolder() async {
    try {
      return await _folderRepository.getRootFolder();
    } catch (e) {
      _logger.warning('Failed to get root folder - $e');
      rethrow;
    }
  }
  
  /// List contents of a folder with preloading based on resource profile
  Future<List<StorageItem>> listFolderContents(String folderId) async {
    try {
      // Get the current resource profile
      final profile = _resourceManager.currentProfile;
      
      // Basic folder listing
      final contents = await _folderRepository.listFolderContents(folderId);
      
      // If preloading is enabled, preload subfolders in background
      if (profile != null && profile.preloadDepth > 0) {
        _preloadSubfolders(contents, profile.preloadDepth);
      }
      
      return contents;
    } catch (e) {
      _logger.warning('Failed to list folder contents: $folderId - $e');
      rethrow;
    }
  }
  
  /// Preload subfolder contents in background
  void _preloadSubfolders(List<StorageItem> items, int depth) {
    if (depth <= 0) return;
    
    // Get folders from items
    final folders = items.where((item) => item.isFolder).toList();
    
    // Preload each folder in background
    for (final folder in folders) {
      Future.microtask(() async {
        try {
          final contents = await _folderRepository.listFolderContents(folder.id);
          
          // Continue preloading with reduced depth
          _preloadSubfolders(contents, depth - 1);
        } catch (e) {
          // Ignore errors during preloading
          _logger.fine('Preloading failed for folder: ${folder.id} - $e');
        }
      });
    }
  }
  
  /// Create a new folder
  Future<Folder> createFolder({
    required String parentFolderId,
    required String name,
  }) async {
    try {
      _logger.info('Creating folder $name in $parentFolderId');
      return await _folderRepository.createFolder(
        parentFolderId: parentFolderId,
        name: name,
      );
    } catch (e) {
      _logger.warning('Failed to create folder: $name - $e');
      rethrow;
    }
  }
  
  /// Rename a folder
  Future<Folder> renameFolder(String folderId, String newName) async {
    try {
      _logger.info('Renaming folder $folderId to $newName');
      return await _folderRepository.renameFolder(folderId, newName);
    } catch (e) {
      _logger.warning('Failed to rename folder: $folderId - $e');
      rethrow;
    }
  }
  
  /// Move a folder to another folder
  Future<Folder> moveFolder(String folderId, String newParentFolderId) async {
    try {
      _logger.info('Moving folder $folderId to $newParentFolderId');
      return await _folderRepository.moveFolder(folderId, newParentFolderId);
    } catch (e) {
      _logger.warning('Failed to move folder: $folderId - $e');
      rethrow;
    }
  }
  
  /// Delete a folder
  Future<void> deleteFolder(String folderId) async {
    try {
      _logger.info('Deleting folder $folderId');
      await _folderRepository.deleteFolder(folderId);
    } catch (e) {
      _logger.warning('Failed to delete folder: $folderId - $e');
      rethrow;
    }
  }
  
  /// Mark a folder as favorite
  Future<Folder> markAsFavorite(String folderId, bool favorite) async {
    try {
      _logger.info('Marking folder $folderId as favorite: $favorite');
      return await _folderRepository.markAsFavorite(folderId, favorite);
    } catch (e) {
      _logger.warning('Failed to mark folder as favorite: $folderId - $e');
      rethrow;
    }
  }
  
  /// Get the path to a folder
  Future<List<Folder>> getFolderPath(String folderId) async {
    try {
      return await _folderRepository.getFolderPath(folderId);
    } catch (e) {
      _logger.warning('Failed to get folder path: $folderId - $e');
      rethrow;
    }
  }
  
  /// Search for folders
  Future<List<Folder>> searchFolders(String query) async {
    try {
      _logger.info('Searching for folders: $query');
      return await _folderRepository.searchFolders(query);
    } catch (e) {
      _logger.warning('Failed to search folders: $query - $e');
      rethrow;
    }
  }
  
  /// Get folder size
  Future<int> getFolderSize(String folderId) async {
    try {
      return await _folderRepository.getFolderSize(folderId);
    } catch (e) {
      _logger.warning('Failed to get folder size: $folderId - $e');
      rethrow;
    }
  }
}