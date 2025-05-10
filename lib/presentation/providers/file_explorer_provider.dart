import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/file_item.dart';
import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
import 'package:path/path.dart' as path;
import 'package:oxicloud_desktop/infrastructure/repositories/api_file_repository.dart';

enum ViewMode {
  list,
  grid,
}

enum FileType { all, folder, image, document, video, audio, other }
enum SortBy { name, date, size, type }

final searchQueryProvider = StateProvider<String>((ref) => '');
final fileTypeFilterProvider = StateProvider<FileType>((ref) => FileType.all);
final sortByProvider = StateProvider<SortBy>((ref) => SortBy.name);
final sortAscendingProvider = StateProvider<bool>((ref) => true);

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  throw UnimplementedError('Debe ser inicializado con una instancia de ApiFileRepository');
});

final currentPathProvider = StateProvider<String>((ref) => '/');

final navigationHistoryProvider = StateNotifierProvider<NavigationHistoryNotifier, String>((ref) {
  return NavigationHistoryNotifier();
});

final viewModeProvider = StateProvider<ViewMode>((ref) => ViewMode.list);

final selectedFilesProvider = StateProvider<Set<FileItem>>((ref) => {});

final apiFileRepositoryProvider = Provider<ApiFileRepository>((ref) {
  throw UnimplementedError('Debe ser inicializado con una instancia de ApiFileRepository');
});

class NavigationHistoryNotifier extends StateNotifier<String> {
  NavigationHistoryNotifier() : super('/');
  
  final List<String> _history = ['/'];
  int _currentIndex = 0;

  String get currentPath => state;
  bool get canGoBack => _currentIndex > 0;
  bool get canGoForward => _currentIndex < _history.length - 1;

  void navigateTo(String newPath) {
    if (newPath != state) {
      _history.add(newPath);
      _currentIndex = _history.length - 1;
      state = newPath;
    }
  }

  void goBack() {
    if (canGoBack) {
      _currentIndex--;
      state = _history[_currentIndex];
    }
  }

  void goForward() {
    if (canGoForward) {
      _currentIndex++;
      state = _history[_currentIndex];
    }
  }

  void goUp() {
    final parentPath = path.dirname(currentPath);
    if (parentPath != currentPath) {
      navigateTo(parentPath);
    }
  }
}

final fileExplorerProvider = StateNotifierProvider<FileExplorerNotifier, AsyncValue<List<FileItem>>>((ref) {
  return FileExplorerNotifier(ref.watch(apiFileRepositoryProvider), ref);
});

class FileExplorerNotifier extends StateNotifier<AsyncValue<List<FileItem>>> {
  final ApiFileRepository _repository;
  final Ref _ref;

  FileExplorerNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    loadFiles();
  }

  Future<void> loadFiles() async {
    try {
      state = const AsyncValue.loading();
      final currentPath = _ref.read(currentPathProvider);
      final files = await _repository.listFiles(currentPath);
      state = AsyncValue.data(files);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createFolder(String name) async {
    try {
      final currentPath = _ref.read(currentPathProvider);
      await _repository.createFolder(currentPath, name);
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> moveFile(FileItem file, String destination) async {
    try {
      await _repository.moveFile(file.path, destination);
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> copyFile(FileItem file, String destination) async {
    try {
      await _repository.copyFile(file.path, destination);
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> renameFile(FileItem file, String newName) async {
    try {
      await _repository.renameFile(file.path, newName);
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteFile(FileItem file) async {
    try {
      await _repository.deleteFile(file.path);
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> uploadFiles(List<File> files) async {
    try {
      final currentPath = _ref.read(currentPathProvider);
      for (final file in files) {
        await _repository.uploadFile(file, currentPath);
      }
      await loadFiles();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> downloadFile(FileItem file, String destination) async {
    try {
      await _repository.downloadFile(file.path, destination);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void navigateTo(String path) {
    _ref.read(currentPathProvider.notifier).state = path;
    loadFiles();
  }

  void navigateUp() {
    final currentPath = _ref.read(currentPathProvider);
    if (currentPath != '/') {
      final parentPath = path.dirname(currentPath);
      _ref.read(currentPathProvider.notifier).state = parentPath;
      loadFiles();
    }
  }

  List<FileItem> filterAndSortFiles(List<FileItem> files, String query, FileType type, SortBy sortBy, bool ascending) {
    var filteredFiles = files;

    // Aplicar filtro de búsqueda
    if (query.isNotEmpty) {
      filteredFiles = filteredFiles.where((file) {
        return file.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }

    // Aplicar filtro de tipo
    if (type != FileType.all) {
      filteredFiles = filteredFiles.where((file) {
        if (type == FileType.folder) return file.isDirectory;
        if (file.isDirectory) return false;
        
        final extension = path.extension(file.name).toLowerCase();
        switch (type) {
          case FileType.image:
            return ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension);
          case FileType.document:
            return ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'].contains(extension);
          case FileType.video:
            return ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv'].contains(extension);
          case FileType.audio:
            return ['.mp3', '.wav', '.ogg', '.flac', '.m4a'].contains(extension);
          case FileType.other:
            return !['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
                    '.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt',
                    '.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv',
                    '.mp3', '.wav', '.ogg', '.flac', '.m4a'].contains(extension);
          default:
            return true;
        }
      }).toList();
    }

    // Aplicar ordenamiento
    filteredFiles.sort((a, b) {
      int comparison;
      switch (sortBy) {
        case SortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case SortBy.date:
          comparison = a.lastModified.compareTo(b.lastModified);
          break;
        case SortBy.size:
          comparison = a.size.compareTo(b.size);
          break;
        case SortBy.type:
          comparison = path.extension(a.name).compareTo(path.extension(b.name));
          break;
      }
      return ascending ? comparison : -comparison;
    });

    return filteredFiles;
  }
} 