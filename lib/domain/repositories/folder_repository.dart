import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/item.dart';

/// Repository interface for folder operations
abstract class FolderRepository {
  /// Get a folder by ID
  Future<Folder> getFolder(String folderId);
  
  /// Get the root folder
  Future<Folder> getRootFolder();
  
  /// List items (files and folders) in a folder
  Future<List<StorageItem>> listFolderContents(String folderId);
  
  /// Create a new folder
  Future<Folder> createFolder({
    required String parentFolderId,
    required String name,
  });
  
  /// Rename a folder
  Future<Folder> renameFolder(String folderId, String newName);
  
  /// Move a folder to another folder
  Future<Folder> moveFolder(String folderId, String newParentFolderId);
  
  /// Delete a folder
  Future<void> deleteFolder(String folderId);
  
  /// Mark a folder as favorite
  Future<Folder> markAsFavorite(String folderId, bool favorite);
  
  /// Get the path to a folder
  Future<List<Folder>> getFolderPath(String folderId);
  
  /// Search for folders
  Future<List<Folder>> searchFolders(String query);
  
  /// Get folder size (total size of all files and subfolders)
  Future<int> getFolderSize(String folderId);
}