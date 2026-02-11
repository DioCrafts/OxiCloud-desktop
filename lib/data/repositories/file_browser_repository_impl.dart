import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/entities/file_item.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/file_browser_repository.dart';
import '../datasources/file_browser_api_datasource.dart';
import '../mappers/file_browser_mapper.dart';

/// Concrete implementation of [FileBrowserRepository].
///
/// Delegates network calls to [FileBrowserApiDataSource] and maps
/// raw JSON through [FileBrowserMapper].
class FileBrowserRepositoryImpl implements FileBrowserRepository {
  final FileBrowserApiDataSource _dataSource;
  final Logger _logger = Logger();

  FileBrowserRepositoryImpl(this._dataSource);

  // ── Listing ─────────────────────────────────────────────────────────────

  @override
  Future<Either<FileBrowserFailure, List<FolderItem>>> listFolders(
    String? parentId,
  ) async {
    try {
      final json = parentId == null
          ? await _dataSource.listRootFolders()
          : await _dataSource.listSubFolders(parentId);
      return Right(FileBrowserMapper.foldersFromJson(json));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('listFolders error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, List<FileItem>>> listFiles(
    String? folderId,
  ) async {
    try {
      final json = await _dataSource.listFiles(folderId);
      return Right(FileBrowserMapper.filesFromJson(json));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('listFiles error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, FolderItem>> getFolder(String id) async {
    try {
      final json = await _dataSource.getFolder(id);
      return Right(FileBrowserMapper.folderFromJson(json));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('getFolder error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  // ── CRUD — folders ────────────────────────────────────────────────────

  @override
  Future<Either<FileBrowserFailure, FolderItem>> createFolder(
    String name,
    String? parentId,
  ) async {
    try {
      final json = await _dataSource.createFolder(name, parentId);
      return Right(FileBrowserMapper.folderFromJson(json));
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return Left(FolderAlreadyExistsFailure(name));
      }
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('createFolder error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, FolderItem>> renameFolder(
    String id,
    String newName,
  ) async {
    try {
      final json = await _dataSource.renameFolder(id, newName);
      return Right(FileBrowserMapper.folderFromJson(json));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('renameFolder error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, void>> deleteFolder(String id) async {
    try {
      await _dataSource.deleteFolder(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('deleteFolder error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  // ── CRUD — files ──────────────────────────────────────────────────────

  @override
  Future<Either<FileBrowserFailure, FileItem>> uploadFile(
    File file,
    String? folderId,
  ) async {
    try {
      final json = await _dataSource.uploadFile(file, folderId);
      return Right(FileBrowserMapper.fileFromJson(json));
    } on DioException catch (e) {
      return Left(UploadFailure(e.message ?? 'Unknown upload error'));
    } catch (e) {
      _logger.e('uploadFile error: $e');
      return Left(UploadFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, FileItem>> renameFile(
    String id,
    String newName,
  ) async {
    try {
      final json = await _dataSource.renameFile(id, newName);
      return Right(FileBrowserMapper.fileFromJson(json));
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('renameFile error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, void>> deleteFile(String id) async {
    try {
      await _dataSource.deleteFile(id);
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      _logger.e('deleteFile error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, String>> downloadFile(
    String id,
    String savePath,
  ) async {
    try {
      await _dataSource.downloadFile(id, savePath);
      return Right(savePath);
    } on DioException catch (e) {
      return Left(DownloadFailure(e.message ?? 'Unknown download error'));
    } catch (e) {
      _logger.e('downloadFile error: $e');
      return Left(DownloadFailure(e.toString()));
    }
  }

  // ── Error mapping ─────────────────────────────────────────────────────

  FileBrowserFailure _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return FileBrowserNetworkFailure(e.message ?? 'Connection error');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code == 401) return const PermissionDeniedFailure();
        if (code == 403) return const PermissionDeniedFailure();
        if (code == 404) return FileNotFoundFailure(e.requestOptions.path);
        return UnknownFileBrowserFailure(
          'Server responded with $code: ${e.response?.statusMessage}',
        );
      default:
        return UnknownFileBrowserFailure(e.message ?? 'Unknown error');
    }
  }
}
