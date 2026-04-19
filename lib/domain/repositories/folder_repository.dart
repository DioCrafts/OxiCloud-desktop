import '../entities/file_entity.dart';
import '../entities/folder_entity.dart';

class FolderContents {
  final List<FolderEntity> folders;
  final List<FileEntity> files;

  const FolderContents({required this.folders, required this.files});

  int get totalCount => folders.length + files.length;
  bool get isEmpty => folders.isEmpty && files.isEmpty;
}

abstract class FolderRepository {
  /// List root folders.
  Future<List<FolderEntity>> listRootFolders();

  /// List subfolders and files in a folder.
  Future<FolderContents> listFolderContents(String folderId);

  /// Get folder by ID.
  Future<FolderEntity> getFolder(String id);

  /// Create a new folder.
  Future<FolderEntity> createFolder({
    required String name,
    String? parentId,
  });

  /// Rename a folder.
  Future<FolderEntity> renameFolder(String id, String newName);

  /// Move a folder.
  Future<FolderEntity> moveFolder(String id, String? newParentId);

  /// Delete a folder (soft-delete to trash).
  Future<void> deleteFolder(String id);

  /// Download folder as ZIP.
  Future<Stream<List<int>>> downloadFolderZip(String id);
}
