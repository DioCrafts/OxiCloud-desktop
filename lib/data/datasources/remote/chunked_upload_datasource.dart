import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// Upload session metadata returned by the server.
class UploadSession {
  final String uploadId;
  final int chunkSize;
  final int totalChunks;
  final DateTime expiresAt;

  const UploadSession({
    required this.uploadId,
    required this.chunkSize,
    required this.totalChunks,
    required this.expiresAt,
  });

  factory UploadSession.fromJson(Map<String, dynamic> json) {
    return UploadSession(
      uploadId: json['upload_id'] as String,
      chunkSize: json['chunk_size'] as int,
      totalChunks: json['total_chunks'] as int,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Result of a completed chunked upload.
class ChunkedUploadResult {
  final String fileId;
  final String filename;
  final int size;
  final String path;

  const ChunkedUploadResult({
    required this.fileId,
    required this.filename,
    required this.size,
    required this.path,
  });

  factory ChunkedUploadResult.fromJson(Map<String, dynamic> json) {
    return ChunkedUploadResult(
      fileId: json['file_id'] as String,
      filename: json['filename'] as String,
      size: json['size'] as int,
      path: json['path'] as String,
    );
  }
}

class ChunkedUploadDatasource {
  final Dio _dio;

  ChunkedUploadDatasource(this._dio);

  /// Create a new upload session.
  Future<UploadSession> createSession({
    required String filename,
    String? folderId,
    String? contentType,
    required int totalSize,
    int? chunkSize,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.uploads,
        data: {
          'filename': filename,
          if (folderId != null) 'folder_id': folderId,
          if (contentType != null) 'content_type': contentType,
          'total_size': totalSize,
          if (chunkSize != null) 'chunk_size': chunkSize,
        },
      );
      return UploadSession.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Upload a single chunk.
  Future<void> uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required Uint8List data,
    String? checksum,
  }) async {
    try {
      await _dio.patch(
        ApiEndpoints.uploadById(uploadId),
        data: Stream.fromIterable([data]),
        queryParameters: {
          'chunk_index': chunkIndex,
          if (checksum != null) 'checksum': checksum,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/octet-stream',
            'Content-Length': data.length,
          },
        ),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Get upload progress (HEAD).
  Future<({int offset, int total, int chunksComplete, int chunksTotal})>
      getStatus(String uploadId) async {
    try {
      final response = await _dio.head(ApiEndpoints.uploadById(uploadId));
      final h = response.headers;
      return (
        offset: int.parse(h.value('Upload-Offset') ?? '0'),
        total: int.parse(h.value('Upload-Length') ?? '0'),
        chunksComplete: int.parse(h.value('Upload-Chunks-Complete') ?? '0'),
        chunksTotal: int.parse(h.value('Upload-Chunks-Total') ?? '0'),
      );
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Finalize the upload — assembles chunks on server.
  Future<ChunkedUploadResult> complete(String uploadId) async {
    try {
      final response =
          await _dio.post(ApiEndpoints.uploadComplete(uploadId));
      return ChunkedUploadResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Cancel and clean up an upload session.
  Future<void> cancel(String uploadId) async {
    try {
      await _dio.delete(ApiEndpoints.uploadById(uploadId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
