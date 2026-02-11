import 'dart:io';

import 'package:dartz/dartz.dart';

import '../entities/file_item.dart';
import '../errors/failures.dart';

/// File browser repository port (domain interface).
///
/// All methods return [Either] so callers can handle success/failure
/// uniformly via `.fold()`.
abstract class FileBrowserRepository {
  // ── Listing ───────────────────────────────────────────────────────────

  /// List sub-folders inside [parentId]. Pass `null` for root.
  Future<Either<FileBrowserFailure, List<FolderItem>>> listFolders(
    String? parentId,
  );

  /// List files inside [folderId]. Pass `null` for root.
  Future<Either<FileBrowserFailure, List<FileItem>>> listFiles(
    String? folderId,
  );

  /// Get folder metadata by [id].
  Future<Either<FileBrowserFailure, FolderItem>> getFolder(String id);

  // ── CRUD — folders ────────────────────────────────────────────────────

  /// Create a new folder with [name] under [parentId] (null = root).
  Future<Either<FileBrowserFailure, FolderItem>> createFolder(
    String name,
    String? parentId,
  );

  /// Rename folder [id] to [newName].
  Future<Either<FileBrowserFailure, FolderItem>> renameFolder(
    String id,
    String newName,
  );

  /// Delete folder [id] (moves to trash on server).
  Future<Either<FileBrowserFailure, void>> deleteFolder(String id);

  // ── CRUD — files ──────────────────────────────────────────────────────

  /// Upload a local [file] into [folderId] (null = root).
  Future<Either<FileBrowserFailure, FileItem>> uploadFile(
    File file,
    String? folderId,
  );

  /// Rename file [id] to [newName].
  Future<Either<FileBrowserFailure, FileItem>> renameFile(
    String id,
    String newName,
  );

  /// Delete file [id] (moves to trash on server).
  Future<Either<FileBrowserFailure, void>> deleteFile(String id);

  /// Download file [id] and save to [savePath]. Returns the path.
  Future<Either<FileBrowserFailure, String>> downloadFile(
    String id,
    String savePath,
  );
}
