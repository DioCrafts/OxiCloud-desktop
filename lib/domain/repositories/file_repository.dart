import 'dart:typed_data';
import '../entities/file_entity.dart';

abstract class FileRepository {
  /// List files in a folder (null = root).
  Future<List<FileEntity>> listFiles({String? folderId});

  /// Get file metadata by ID.
  Future<FileEntity> getFile(String id);

  /// Upload a file (simple upload for small files).
  Future<FileEntity> uploadFile({
    required String name,
    required String? folderId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String mimeType,
  });

  /// Download a file. Returns bytes stream.
  Future<Stream<List<int>>> downloadFile(String id);

  /// Download file to a local path.
  Future<String> downloadFileToPath(String id, String localPath);

  /// Delete a file (soft-delete to trash).
  Future<void> deleteFile(String id);

  /// Rename a file.
  Future<FileEntity> renameFile(String id, String newName);

  /// Move a file to another folder.
  Future<FileEntity> moveFile(String id, String targetFolderId);

  /// Get thumbnail bytes.
  Future<Uint8List> getThumbnail(String id, {String size = '256'});
}
