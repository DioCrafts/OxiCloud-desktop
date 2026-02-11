import 'package:dartz/dartz.dart';

import '../entities/trash_item.dart';
import '../errors/failures.dart';

/// Trash repository port (domain interface).
abstract class TrashRepository {
  /// List all trashed items for the current user.
  Future<Either<TrashFailure, List<TrashItem>>> listTrash();

  /// Move a file to trash.
  Future<Either<TrashFailure, void>> trashFile(String fileId);

  /// Move a folder to trash.
  Future<Either<TrashFailure, void>> trashFolder(String folderId);

  /// Restore an item from trash.
  Future<Either<TrashFailure, void>> restoreItem(String trashId);

  /// Permanently delete a trashed item.
  Future<Either<TrashFailure, void>> deleteItemPermanently(String trashId);

  /// Empty the entire trash.
  Future<Either<TrashFailure, void>> emptyTrash();
}
