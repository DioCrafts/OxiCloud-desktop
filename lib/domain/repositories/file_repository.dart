import 'dart:typed_data';
import 'package:oxicloud_desktop/domain/entities/file.dart';

/// Repository interface for file operations
abstract class FileRepository {
  /// Get a file by ID
  Future<File> getFile(String fileId);
  
  /// List files in a folder
  Future<List<File>> listFiles(String folderId);
  
  /// Upload a file to a folder
  Future<File> uploadFile({
    required String parentFolderId,
    required String name,
    required Uint8List data,
    String? mimeType,
  });
  
  /// Update an existing file
  Future<File> updateFile({
    required String fileId,
    required Uint8List data,
  });
  
  /// Download a file
  Future<Uint8List> downloadFile(String fileId);
  
  /// Download a file to a local path
  Future<void> downloadFileToPath(String fileId, String localPath);
  
  /// Rename a file
  Future<File> renameFile(String fileId, String newName);
  
  /// Move a file to another folder
  Future<File> moveFile(String fileId, String newParentFolderId);
  
  /// Delete a file
  Future<void> deleteFile(String fileId);
  
  /// Mark a file as favorite
  Future<File> markAsFavorite(String fileId, bool favorite);
  
  /// Get a file's thumbnail
  Future<Uint8List?> getThumbnail(String fileId, {int? size});
  
  /// Search for files
  Future<List<File>> searchFiles(String query);
  
  /// Get files shared with me
  Future<List<File>> getSharedFiles();
  
  /// Get recently modified files
  Future<List<File>> getRecentFiles({int limit = 10});
}