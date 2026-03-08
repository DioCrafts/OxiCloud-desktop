part of 'file_browser_bloc.dart';

// =============================================================================
// FILE BROWSER EVENTS
// =============================================================================

abstract class FileBrowserEvent extends Equatable {
  const FileBrowserEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) the root folder.
class LoadFolder extends FileBrowserEvent {
  const LoadFolder();
}

/// Navigate into a sub-folder.
class NavigateToFolder extends FileBrowserEvent {
  final String folderId;
  final String folderName;

  const NavigateToFolder({required this.folderId, required this.folderName});

  @override
  List<Object?> get props => [folderId, folderName];
}

/// Navigate one level up.
class NavigateUp extends FileBrowserEvent {
  const NavigateUp();
}

/// Jump to a specific breadcrumb index.
class NavigateToBreadcrumb extends FileBrowserEvent {
  final int index;

  const NavigateToBreadcrumb(this.index);

  @override
  List<Object?> get props => [index];
}

/// Refresh the current folder without changing navigation.
class RefreshFolder extends FileBrowserEvent {
  const RefreshFolder();
}

/// Create a new folder in the current directory.
class CreateFolderRequested extends FileBrowserEvent {
  final String name;

  const CreateFolderRequested(this.name);

  @override
  List<Object?> get props => [name];
}

/// Upload a local file to the current folder.
class UploadFileRequested extends FileBrowserEvent {
  final File file;

  const UploadFileRequested(this.file);

  @override
  List<Object?> get props => [file];
}

/// Delete a file.
class DeleteFileRequested extends FileBrowserEvent {
  final String fileId;

  const DeleteFileRequested(this.fileId);

  @override
  List<Object?> get props => [fileId];
}

/// Delete a folder.
class DeleteFolderRequested extends FileBrowserEvent {
  final String folderId;

  const DeleteFolderRequested(this.folderId);

  @override
  List<Object?> get props => [folderId];
}

/// Rename a file.
class RenameFileRequested extends FileBrowserEvent {
  final String fileId;
  final String newName;

  const RenameFileRequested({required this.fileId, required this.newName});

  @override
  List<Object?> get props => [fileId, newName];
}

/// Rename a folder.
class RenameFolderRequested extends FileBrowserEvent {
  final String folderId;
  final String newName;

  const RenameFolderRequested({required this.folderId, required this.newName});

  @override
  List<Object?> get props => [folderId, newName];
}

/// Download a file to the given path.
class DownloadFileRequested extends FileBrowserEvent {
  final String fileId;
  final String savePath;

  const DownloadFileRequested({required this.fileId, required this.savePath});

  @override
  List<Object?> get props => [fileId, savePath];
}

/// Upload a file with progress tracking (chunked upload for large files).
class UploadFileWithProgress extends FileBrowserEvent {
  final File file;

  const UploadFileWithProgress(this.file);

  @override
  List<Object?> get props => [file];
}

/// Internal event: upload progress updated.
class UploadProgressUpdated extends FileBrowserEvent {
  final String fileName;
  final int bytesSent;
  final int bytesTotal;

  const UploadProgressUpdated({
    required this.fileName,
    required this.bytesSent,
    required this.bytesTotal,
  });

  @override
  List<Object?> get props => [fileName, bytesSent, bytesTotal];
}

/// Toggle favorite on a file or folder.
class ToggleFavorite extends FileBrowserEvent {
  final String itemId;
  final String itemType; // 'file' or 'folder'
  final bool isFavorite;

  const ToggleFavorite({
    required this.itemId,
    required this.itemType,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [itemId, itemType, isFavorite];
}

/// Batch delete multiple items.
class BatchDeleteRequested extends FileBrowserEvent {
  final List<String> fileIds;
  final List<String> folderIds;

  const BatchDeleteRequested({this.fileIds = const [], this.folderIds = const []});

  @override
  List<Object?> get props => [fileIds, folderIds];
}

/// Move items to a different folder.
class MoveItemsRequested extends FileBrowserEvent {
  final List<String> fileIds;
  final List<String> folderIds;
  final String? targetFolderId;

  const MoveItemsRequested({
    this.fileIds = const [],
    this.folderIds = const [],
    this.targetFolderId,
  });

  @override
  List<Object?> get props => [fileIds, folderIds, targetFolderId];
}

/// Copy items to a different folder.
class CopyItemsRequested extends FileBrowserEvent {
  final List<String> fileIds;
  final List<String> folderIds;
  final String? targetFolderId;

  const CopyItemsRequested({
    this.fileIds = const [],
    this.folderIds = const [],
    this.targetFolderId,
  });

  @override
  List<Object?> get props => [fileIds, folderIds, targetFolderId];
}

/// Toggle between list / grid view.
class ToggleViewMode extends FileBrowserEvent {
  const ToggleViewMode();
}
