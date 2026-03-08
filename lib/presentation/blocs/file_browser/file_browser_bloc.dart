import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/file_item.dart';
import '../../../core/repositories/file_browser_repository.dart';
import '../../../data/datasources/favorites_api_datasource.dart';

part 'file_browser_event.dart';
part 'file_browser_state.dart';

// =============================================================================
// BLOC
// =============================================================================

/// Threshold above which chunked upload is used (10 MB).
const int _chunkedUploadThreshold = 10 * 1024 * 1024;

class FileBrowserBloc extends Bloc<FileBrowserEvent, FileBrowserState> {
  final FileBrowserRepository _repository;
  final FavoritesApiDataSource? _favoritesDataSource;

  FileBrowserBloc(this._repository, [this._favoritesDataSource])
      : super(const FileBrowserInitial()) {
    on<LoadFolder>(_onLoadFolder);
    on<NavigateToFolder>(_onNavigateToFolder);
    on<NavigateUp>(_onNavigateUp);
    on<NavigateToBreadcrumb>(_onNavigateToBreadcrumb);
    on<CreateFolderRequested>(_onCreateFolder);
    on<UploadFileRequested>(_onUploadFile);
    on<UploadFileWithProgress>(_onUploadFileWithProgress);
    on<UploadProgressUpdated>(_onUploadProgressUpdated);
    on<DeleteFileRequested>(_onDeleteFile);
    on<DeleteFolderRequested>(_onDeleteFolder);
    on<RenameFileRequested>(_onRenameFile);
    on<RenameFolderRequested>(_onRenameFolder);
    on<DownloadFileRequested>(_onDownloadFile);
    on<ToggleFavorite>(_onToggleFavorite);
    on<BatchDeleteRequested>(_onBatchDelete);
    on<MoveItemsRequested>(_onMoveItems);
    on<CopyItemsRequested>(_onCopyItems);
    on<ToggleViewMode>(_onToggleViewMode);
    on<RefreshFolder>(_onRefreshFolder);
  }

  // Current navigation stack — kept in the bloc so it survives state changes.
  final List<BreadcrumbItem> _breadcrumbs = [
    const BreadcrumbItem(name: 'Root'),
  ];

  String? get _currentFolderId =>
      _breadcrumbs.last.id; // null = root

  // ── Load folder ─────────────────────────────────────────────────────────

  Future<void> _onLoadFolder(
    LoadFolder event,
    Emitter<FileBrowserState> emit,
  ) async {
    emit(const FileBrowserLoading());
    await _loadCurrentFolder(emit);
  }

  Future<void> _onNavigateToFolder(
    NavigateToFolder event,
    Emitter<FileBrowserState> emit,
  ) async {
    _breadcrumbs.add(BreadcrumbItem(id: event.folderId, name: event.folderName));
    emit(const FileBrowserLoading());
    await _loadCurrentFolder(emit);
  }

  Future<void> _onNavigateUp(
    NavigateUp event,
    Emitter<FileBrowserState> emit,
  ) async {
    if (_breadcrumbs.length > 1) {
      _breadcrumbs.removeLast();
      emit(const FileBrowserLoading());
      await _loadCurrentFolder(emit);
    }
  }

  Future<void> _onNavigateToBreadcrumb(
    NavigateToBreadcrumb event,
    Emitter<FileBrowserState> emit,
  ) async {
    if (event.index < _breadcrumbs.length - 1) {
      _breadcrumbs.removeRange(event.index + 1, _breadcrumbs.length);
      emit(const FileBrowserLoading());
      await _loadCurrentFolder(emit);
    }
  }

  Future<void> _onRefreshFolder(
    RefreshFolder event,
    Emitter<FileBrowserState> emit,
  ) async {
    // Keep current content visible while refreshing
    await _loadCurrentFolder(emit, silent: true);
  }

  // ── CRUD operations ─────────────────────────────────────────────────────

  Future<void> _onCreateFolder(
    CreateFolderRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    }

    final result = await _repository.createFolder(event.name, _currentFolderId);

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('Folder created'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onUploadFile(
    UploadFileRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    }

    // Use chunked upload for large files
    final fileSize = await event.file.length();
    if (fileSize > _chunkedUploadThreshold) {
      add(UploadFileWithProgress(event.file));
      return;
    }

    final result = await _repository.uploadFile(event.file, _currentFolderId);

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('File uploaded'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onUploadFileWithProgress(
    UploadFileWithProgress event,
    Emitter<FileBrowserState> emit,
  ) async {
    final fileName = event.file.path.split(Platform.pathSeparator).last;

    emit(FileBrowserUploadProgress(
      fileName: fileName,
      bytesSent: 0,
      bytesTotal: await event.file.length(),
    ));

    final result = await _repository.uploadFileChunked(
      event.file,
      _currentFolderId,
      onProgress: (sent, total) {
        add(UploadProgressUpdated(
          fileName: fileName,
          bytesSent: sent,
          bytesTotal: total,
        ));
      },
    );

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('File uploaded'));
        add(const RefreshFolder());
      },
    );
  }

  void _onUploadProgressUpdated(
    UploadProgressUpdated event,
    Emitter<FileBrowserState> emit,
  ) {
    emit(FileBrowserUploadProgress(
      fileName: event.fileName,
      bytesSent: event.bytesSent,
      bytesTotal: event.bytesTotal,
    ));
  }

  Future<void> _onDeleteFile(
    DeleteFileRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final result = await _repository.deleteFile(event.fileId);
    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('File deleted'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onDeleteFolder(
    DeleteFolderRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final result = await _repository.deleteFolder(event.folderId);
    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('Folder deleted'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onRenameFile(
    RenameFileRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final result = await _repository.renameFile(event.fileId, event.newName);
    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('File renamed'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onRenameFolder(
    RenameFolderRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final result = await _repository.renameFolder(event.folderId, event.newName);
    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('Folder renamed'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onDownloadFile(
    DownloadFileRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final result = await _repository.downloadFile(event.fileId, event.savePath);
    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (path) => emit(FileBrowserActionSuccess('Downloaded to $path')),
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FileBrowserState> emit,
  ) async {
    if (_favoritesDataSource == null) return;
    try {
      if (event.isFavorite) {
        await _favoritesDataSource.removeFavorite(event.itemType, event.itemId);
        emit(const FileBrowserActionSuccess('Removed from favorites'));
      } else {
        await _favoritesDataSource.addFavorite(event.itemType, event.itemId);
        emit(const FileBrowserActionSuccess('Added to favorites'));
      }
    } catch (e) {
      emit(FileBrowserActionError('Failed to update favorite: $e'));
    }
  }

  Future<void> _onBatchDelete(
    BatchDeleteRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    }

    final result = await _repository.batchDelete(
      fileIds: event.fileIds,
      folderIds: event.folderIds,
    );

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        final count = event.fileIds.length + event.folderIds.length;
        emit(FileBrowserActionSuccess('$count items deleted'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onMoveItems(
    MoveItemsRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    }

    final result = await _repository.batchMove(
      fileIds: event.fileIds,
      folderIds: event.folderIds,
      targetFolderId: event.targetFolderId,
    );

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        final count = event.fileIds.length + event.folderIds.length;
        emit(FileBrowserActionSuccess('$count items moved'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onCopyItems(
    CopyItemsRequested event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(isActionInProgress: true));
    }

    final result = await _repository.batchCopy(
      fileIds: event.fileIds,
      folderIds: event.folderIds,
      targetFolderId: event.targetFolderId,
    );

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        final count = event.fileIds.length + event.folderIds.length;
        emit(FileBrowserActionSuccess('$count items copied'));
        add(const RefreshFolder());
      },
    );
  }

  Future<void> _onToggleViewMode(
    ToggleViewMode event,
    Emitter<FileBrowserState> emit,
  ) async {
    final currentState = state;
    if (currentState is FileBrowserLoaded) {
      emit(currentState.copyWith(
        viewMode: currentState.viewMode == ViewMode.list
            ? ViewMode.grid
            : ViewMode.list,
      ));
    }
  }

  // ── Shared loader ───────────────────────────────────────────────────────

  Future<void> _loadCurrentFolder(
    Emitter<FileBrowserState> emit, {
    bool silent = false,
  }) async {
    final foldersResult = await _repository.listFolders(_currentFolderId);
    final filesResult = await _repository.listFiles(_currentFolderId);

    // If both fail, emit error
    if (foldersResult.isLeft() && filesResult.isLeft()) {
      foldersResult.fold(
        (failure) => emit(FileBrowserError(failure.message)),
        (_) {},
      );
      return;
    }

    final folders = foldersResult.getOrElse(() => []);
    final files = filesResult.getOrElse(() => []);

    // Determine view mode — keep current if available
    var viewMode = ViewMode.list;
    if (state is FileBrowserLoaded) {
      viewMode = (state as FileBrowserLoaded).viewMode;
    }

    emit(FileBrowserLoaded(
      folders: folders,
      files: files,
      breadcrumbs: List.unmodifiable(_breadcrumbs),
      currentFolderId: _currentFolderId,
      viewMode: viewMode,
    ));
  }
}
