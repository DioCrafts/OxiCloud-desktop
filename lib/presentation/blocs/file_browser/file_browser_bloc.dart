import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/entities/file_item.dart';
import '../../../core/repositories/file_browser_repository.dart';

part 'file_browser_event.dart';
part 'file_browser_state.dart';

// =============================================================================
// BLOC
// =============================================================================

class FileBrowserBloc extends Bloc<FileBrowserEvent, FileBrowserState> {
  final FileBrowserRepository _repository;

  FileBrowserBloc(this._repository) : super(const FileBrowserInitial()) {
    on<LoadFolder>(_onLoadFolder);
    on<NavigateToFolder>(_onNavigateToFolder);
    on<NavigateUp>(_onNavigateUp);
    on<NavigateToBreadcrumb>(_onNavigateToBreadcrumb);
    on<CreateFolderRequested>(_onCreateFolder);
    on<UploadFileRequested>(_onUploadFile);
    on<DeleteFileRequested>(_onDeleteFile);
    on<DeleteFolderRequested>(_onDeleteFolder);
    on<RenameFileRequested>(_onRenameFile);
    on<RenameFolderRequested>(_onRenameFolder);
    on<DownloadFileRequested>(_onDownloadFile);
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

    final result = await _repository.uploadFile(event.file, _currentFolderId);

    result.fold(
      (failure) => emit(FileBrowserActionError(failure.message)),
      (_) {
        emit(const FileBrowserActionSuccess('File uploaded'));
        add(const RefreshFolder());
      },
    );
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
