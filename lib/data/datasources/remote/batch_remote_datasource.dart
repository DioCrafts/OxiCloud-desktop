import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';
import '../../dtos/files/file_dto.dart';
import '../../dtos/folders/folder_dtos.dart';

/// Batch operation result from the server.
class BatchResult<T> {
  final List<T> successful;
  final List<BatchFailure> failed;
  final BatchStats stats;

  const BatchResult({
    required this.successful,
    required this.failed,
    required this.stats,
  });
}

class BatchFailure {
  final String id;
  final String error;

  const BatchFailure({required this.id, required this.error});

  factory BatchFailure.fromJson(Map<String, dynamic> json) {
    return BatchFailure(
      id: json['id'] as String,
      error: json['error'] as String,
    );
  }
}

class BatchStats {
  final int total;
  final int successful;
  final int failed;
  final int executionTimeMs;

  const BatchStats({
    required this.total,
    required this.successful,
    required this.failed,
    required this.executionTimeMs,
  });

  factory BatchStats.fromJson(Map<String, dynamic> json) {
    return BatchStats(
      total: json['total'] as int,
      successful: json['successful'] as int,
      failed: json['failed'] as int,
      executionTimeMs: json['execution_time_ms'] as int? ?? 0,
    );
  }
}

class BatchRemoteDatasource {
  final Dio _dio;

  BatchRemoteDatasource(this._dio);

  // --- Files ---

  Future<BatchResult<FileResponseDto>> moveFiles(
    List<String> fileIds,
    String targetFolderId,
  ) async {
    return _postFileBatch(ApiEndpoints.batchFilesMove, {
      'file_ids': fileIds,
      'target_folder_id': targetFolderId,
    });
  }

  Future<BatchResult<FileResponseDto>> copyFiles(
    List<String> fileIds,
    String targetFolderId,
  ) async {
    return _postFileBatch(ApiEndpoints.batchFilesCopy, {
      'file_ids': fileIds,
      'target_folder_id': targetFolderId,
    });
  }

  Future<BatchResult<FileResponseDto>> deleteFiles(List<String> fileIds) async {
    return _postFileBatch(ApiEndpoints.batchFilesDelete, {'file_ids': fileIds});
  }

  Future<BatchResult<FileResponseDto>> getFiles(List<String> fileIds) async {
    return _postFileBatch(ApiEndpoints.batchFilesGet, {'file_ids': fileIds});
  }

  // --- Folders ---

  Future<BatchResult<FolderResponseDto>> deleteFolders(
    List<String> folderIds,
  ) async {
    return _postFolderBatch(ApiEndpoints.batchFoldersDelete, {
      'folder_ids': folderIds,
    });
  }

  Future<BatchResult<FolderResponseDto>> createFolders(
    List<Map<String, dynamic>> folders,
  ) async {
    return _postFolderBatch(ApiEndpoints.batchFoldersCreate, {
      'folders': folders,
    });
  }

  Future<BatchResult<FolderResponseDto>> getFolders(
    List<String> folderIds,
  ) async {
    return _postFolderBatch(ApiEndpoints.batchFoldersGet, {
      'folder_ids': folderIds,
    });
  }

  Future<BatchResult<FolderResponseDto>> moveFolders(
    List<String> folderIds,
    String? targetParentId,
  ) async {
    return _postFolderBatch(ApiEndpoints.batchFoldersMove, {
      'folder_ids': folderIds,
      if (targetParentId != null) 'target_folder_id': targetParentId,
    });
  }

  // --- Trash ---

  Future<BatchResult<void>> batchTrash({
    List<String>? fileIds,
    List<String>? folderIds,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.batchTrash,
        data: {
          if (fileIds != null) 'file_ids': fileIds,
          if (folderIds != null) 'folder_ids': folderIds,
        },
      );
      final data = response.data as Map<String, dynamic>;
      return BatchResult<void>(
        successful: [],
        failed: _parseFailures(data),
        stats: BatchStats.fromJson(data['stats'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // --- Download ---

  Future<void> batchDownload({
    required List<String> fileIds,
    required String savePath,
  }) async {
    try {
      await _dio.download(
        ApiEndpoints.batchDownload,
        savePath,
        data: {'file_ids': fileIds},
        options: Options(method: 'POST'),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // --- Helpers ---

  Future<BatchResult<FileResponseDto>> _postFileBatch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      final data = response.data as Map<String, dynamic>;
      final successful = (data['successful'] as List<dynamic>? ?? [])
          .map((e) => FileResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return BatchResult(
        successful: successful,
        failed: _parseFailures(data),
        stats: BatchStats.fromJson(data['stats'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<BatchResult<FolderResponseDto>> _postFolderBatch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      final data = response.data as Map<String, dynamic>;
      final successful = (data['successful'] as List<dynamic>? ?? [])
          .map((e) => FolderResponseDto.fromJson(e as Map<String, dynamic>))
          .toList();
      return BatchResult(
        successful: successful,
        failed: _parseFailures(data),
        stats: BatchStats.fromJson(data['stats'] as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  List<BatchFailure> _parseFailures(Map<String, dynamic> data) {
    return (data['failed'] as List<dynamic>? ?? [])
        .map((e) => BatchFailure.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
