import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../../core/entities/file_item.dart';
import '../../core/errors/failures.dart';
import '../../core/repositories/file_browser_repository.dart';
import '../datasources/batch_api_datasource.dart';
import '../datasources/chunked_upload_datasource.dart';
import '../datasources/file_browser_api_datasource.dart';
import '../mappers/file_browser_mapper.dart';

/// Concrete implementation of [FileBrowserRepository].
///
/// Delegates network calls to [FileBrowserApiDataSource] and maps
/// raw JSON through [FileBrowserMapper].
class FileBrowserRepositoryImpl implements FileBrowserRepository {
  FileBrowserRepositoryImpl(
    this._dataSource,
    this._chunkedUpload,
    this._batchDataSource,
  );

  final FileBrowserApiDataSource _dataSource;
  final ChunkedUploadDataSource _chunkedUpload;
  final BatchApiDataSource _batchDataSource;
  final Logger _logger = Logger();

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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      _logger.e('uploadFile error: $e');
      return Left(UploadFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, FileItem>> uploadFileChunked(
    File file,
    String? folderId, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final json = await _chunkedUpload.uploadFile(
        file: file,
        folderId: folderId,
        onProgress: onProgress,
      );
      return Right(FileBrowserMapper.fileFromJson(json));
    } on DioException catch (e) {
      return Left(UploadFailure(e.message ?? 'Chunked upload error'));
    } on Exception catch (e) {
      _logger.e('uploadFileChunked error: $e');
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
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
    } on Exception catch (e) {
      _logger.e('downloadFile error: $e');
      return Left(DownloadFailure(e.toString()));
    }
  }

  // ── Batch operations ──────────────────────────────────────────────────

  @override
  Future<Either<FileBrowserFailure, void>> batchDelete({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
  }) async {
    try {
      await _batchDataSource.batchDelete(
        fileIds: fileIds,
        folderIds: folderIds,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Exception catch (e) {
      _logger.e('batchDelete error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, void>> batchMove({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
    String? targetFolderId,
  }) async {
    try {
      await _batchDataSource.batchMove(
        fileIds: fileIds,
        folderIds: folderIds,
        targetFolderId: targetFolderId,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Exception catch (e) {
      _logger.e('batchMove error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, void>> batchCopy({
    List<String> fileIds = const [],
    List<String> folderIds = const [],
    String? targetFolderId,
  }) async {
    try {
      await _batchDataSource.batchCopy(
        fileIds: fileIds,
        folderIds: folderIds,
        targetFolderId: targetFolderId,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } on Exception catch (e) {
      _logger.e('batchCopy error: $e');
      return Left(UnknownFileBrowserFailure(e.toString()));
    }
  }

  @override
  Future<Either<FileBrowserFailure, String>> downloadFolderAsZip(
    String folderId,
    String savePath,
  ) async {
    try {
      await _batchDataSource.downloadFolderAsZip(folderId, savePath);
      return Right(savePath);
    } on DioException catch (e) {
      return Left(DownloadFailure(e.message ?? 'Unknown download error'));
    } on Exception catch (e) {
      _logger.e('downloadFolderAsZip error: $e');
      return Left(DownloadFailure(e.toString()));
    }
  }

  @override
  String? getThumbnailUrl(String fileId, {String size = 'small'}) {
    return _batchDataSource.getThumbnailUrl(fileId, size: size);
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
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
        return UnknownFileBrowserFailure(e.message ?? 'Unknown error');
    }
  }
}
