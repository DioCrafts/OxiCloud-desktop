import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/application/services/folder_service.dart';

/// Provider for root folders
final rootFoldersProvider = AsyncNotifierProvider<RootFoldersNotifier, List<Folder>>(() {
  return RootFoldersNotifier();
});

/// Notifier for root folders
class RootFoldersNotifier extends AsyncNotifier<List<Folder>> {
  @override
  Future<List<Folder>> build() async {
    // Initialize with an empty list
    return [];
  }
  
  /// Load root folders
  Future<void> loadRootFolders() async {
    state = const AsyncValue.loading();
    
    try {
      final folderService = getIt<FolderService>();
      
      // Get root folder first
      final rootFolder = await folderService.getRootFolder();
      
      // Get contents of root folder
      final contents = await folderService.listFolderContents(rootFolder.id);
      
      // Filter out only folders
      final folders = contents
          .where((item) => item.isFolder)
          .map((item) async {
            // Get full folder object for each item
            return await folderService.getFolder(item.id);
          })
          .toList();
      
      // Wait for all folder requests to complete
      final folderList = await Future.wait(folders);
      
      state = AsyncValue.data(folderList);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

/// Provider for subfolders of a specific folder
final subFoldersProvider = FutureProvider.family<List<Folder>, String>((ref, folderId) async {
  final folderService = getIt<FolderService>();
  
  // Get contents of the folder
  final contents = await folderService.listFolderContents(folderId);
  
  // Filter out only folders
  final folders = contents
      .where((item) => item.isFolder)
      .map((item) async {
        // Get full folder object for each item
        return await folderService.getFolder(item.id);
      })
      .toList();
  
  // Wait for all folder requests to complete
  return await Future.wait(folders);
});

/// Provider for folder favorites
final favoriteFoldersProvider = FutureProvider<List<Folder>>((ref) async {
  final folderService = getIt<FolderService>();
  
  // In a real implementation, you would have a dedicated API
  // to fetch only favorite folders. This is a simplified example.
  final rootFolder = await folderService.getRootFolder();
  final allFolders = await folderService.listFolderContents(rootFolder.id);
  
  // Get full folder objects for favorite folders
  final favoriteFolders = allFolders
      .where((item) => item.isFolder && item.isFavorite)
      .map((item) async {
        return await folderService.getFolder(item.id);
      })
      .toList();
  
  // Wait for all folder requests to complete
  return await Future.wait(favoriteFolders);
});