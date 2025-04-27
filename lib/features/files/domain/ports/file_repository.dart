import 'package:dartz/dartz.dart';
import 'package:oxicloud_desktop_client/core/error/failures.dart';
import 'package:oxicloud_desktop_client/features/files/domain/models/file.dart';
import 'package:oxicloud_desktop_client/features/files/domain/models/folder.dart';

abstract class FileRepository {
  Future<Either<Failure, List<File>>> getFiles({String? parentId});
  Future<Either<Failure, List<Folder>>> getFolders({String? parentId});
  Future<Either<Failure, File>> uploadFile(String path, {String? parentId, Function(double)? onProgress});
  Future<Either<Failure, Folder>> createFolder(String name, {String? parentId});
  Future<Either<Failure, void>> deleteFile(String id);
  Future<Either<Failure, void>> deleteFolder(String id);
  Future<Either<Failure, void>> moveFile(String id, String newParentId);
  Future<Either<Failure, void>> moveFolder(String id, String newParentId);
  Future<Either<Failure, void>> renameFile(String id, String newName);
  Future<Either<Failure, void>> renameFolder(String id, String newName);
  Future<Either<Failure, void>> toggleFavorite(String id, bool isFavorite);
  Future<Either<Failure, void>> shareItem(String id, List<String> emails);
  Future<Either<Failure, String>> getDownloadUrl(String id);
  Future<Either<Failure, void>> trashItem(String id, bool isFile);
  Future<Either<Failure, List<File>>> getTrashedFiles();
  Future<Either<Failure, List<Folder>>> getTrashedFolders();
  Future<Either<Failure, void>> restoreItem(String id, bool isFile);
  Future<Either<Failure, void>> emptyTrash();
} 