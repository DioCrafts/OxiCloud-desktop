part of 'file_browser_bloc.dart';

// =============================================================================
// FILE BROWSER STATES
// =============================================================================

abstract class FileBrowserState extends Equatable {
  const FileBrowserState();

  @override
  List<Object?> get props => [];
}

/// Initial state — no data loaded yet.
class FileBrowserInitial extends FileBrowserState {
  const FileBrowserInitial();
}

/// Loading folder contents.
class FileBrowserLoading extends FileBrowserState {
  const FileBrowserLoading();
}

/// Folder contents loaded successfully.
class FileBrowserLoaded extends FileBrowserState {
  final List<FolderItem> folders;
  final List<FileItem> files;
  final List<BreadcrumbItem> breadcrumbs;
  final String? currentFolderId;
  final ViewMode viewMode;
  final bool isActionInProgress;

  const FileBrowserLoaded({
    required this.folders,
    required this.files,
    required this.breadcrumbs,
    this.currentFolderId,
    this.viewMode = ViewMode.list,
    this.isActionInProgress = false,
  });

  /// Total items (folders + files).
  int get totalItems => folders.length + files.length;

  /// Whether we are at the root level.
  bool get isRoot => currentFolderId == null;

  FileBrowserLoaded copyWith({
    List<FolderItem>? folders,
    List<FileItem>? files,
    List<BreadcrumbItem>? breadcrumbs,
    String? currentFolderId,
    ViewMode? viewMode,
    bool? isActionInProgress,
  }) {
    return FileBrowserLoaded(
      folders: folders ?? this.folders,
      files: files ?? this.files,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      currentFolderId: currentFolderId ?? this.currentFolderId,
      viewMode: viewMode ?? this.viewMode,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }

  @override
  List<Object?> get props =>
      [folders, files, breadcrumbs, currentFolderId, viewMode, isActionInProgress];
}

/// Error while loading folder.
class FileBrowserError extends FileBrowserState {
  final String message;

  const FileBrowserError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Transient success message (create, rename, delete completed).
class FileBrowserActionSuccess extends FileBrowserState {
  final String message;

  const FileBrowserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

/// Transient error message from an action.
class FileBrowserActionError extends FileBrowserState {
  final String message;

  const FileBrowserActionError(this.message);

  @override
  List<Object?> get props => [message];
}
