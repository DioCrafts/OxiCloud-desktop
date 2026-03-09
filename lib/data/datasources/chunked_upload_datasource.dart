import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

/// Chunked upload data source matching OxiCloud server's /api/uploads endpoint
class ChunkedUploadDataSource {
  ChunkedUploadDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Default chunk size: 5 MB
  static const int defaultChunkSize = 5 * 1024 * 1024;

  /// Initiate a chunked upload session.
  /// POST /api/uploads
  Future<ChunkedUploadSession> initiate({
    required String fileName,
    required int totalSize,
    String? folderId,
    String? mimeType,
  }) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'api/uploads',
      data: {
        'file_name': fileName,
        'total_size': totalSize,
        'folder_id': ?folderId,
        'mime_type': ?mimeType,
      },
    );

    final data = response.data!;
    return ChunkedUploadSession(
      uploadId: data['upload_id'] as String,
      chunkSize: (data['chunk_size'] as int?) ?? defaultChunkSize,
      totalChunks: (data['total_chunks'] as int?) ?? 0,
    );
  }

  /// Upload a single chunk.
  /// PATCH /api/uploads/{uploadId}
  Future<void> uploadChunk({
    required String uploadId,
    required int chunkIndex,
    required List<int> chunkData,
    required int offset,
    required int totalSize,
  }) async {
    await _apiClient.dio.patch<dynamic>(
      'api/uploads/$uploadId',
      data: Stream.fromIterable([chunkData]),
      options: Options(
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Range': 'bytes $offset-${offset + chunkData.length - 1}/$totalSize',
        },
      ),
    );
  }

  /// Check upload progress.
  /// HEAD /api/uploads/{uploadId}
  Future<int> getUploadOffset(String uploadId) async {
    final response = await _apiClient.dio.head<dynamic>('api/uploads/$uploadId');
    final offset = response.headers.value('Upload-Offset');
    return offset != null ? int.tryParse(offset) ?? 0 : 0;
  }

  /// Complete the upload.
  /// POST /api/uploads/{uploadId}/complete
  Future<Map<String, dynamic>> complete(String uploadId) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      'api/uploads/$uploadId/complete',
    );
    return response.data ?? {};
  }

  /// Cancel / abort the upload.
  /// DELETE /api/uploads/{uploadId}
  Future<void> cancel(String uploadId) async {
    await _apiClient.dio.delete<dynamic>('api/uploads/$uploadId');
  }

  /// Upload a large file using chunked upload.
  /// Returns the created file metadata.
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    String? folderId,
    void Function(int sent, int total)? onProgress,
  }) async {
    final totalSize = await file.length();
    final fileName = file.path.split(Platform.pathSeparator).last;

    // 1. Initiate
    final session = await initiate(
      fileName: fileName,
      totalSize: totalSize,
      folderId: folderId,
    );

    // 2. Upload chunks
    final chunkSize = session.chunkSize;
    final raf = await file.open();
    var offset = 0;

    try {
      while (offset < totalSize) {
        final remaining = totalSize - offset;
        final currentChunkSize = remaining < chunkSize ? remaining : chunkSize;

        await raf.setPosition(offset);
        final chunk = await raf.read(currentChunkSize);

        await uploadChunk(
          uploadId: session.uploadId,
          chunkIndex: offset ~/ chunkSize,
          chunkData: chunk,
          offset: offset,
          totalSize: totalSize,
        );

        offset += currentChunkSize;
        onProgress?.call(offset, totalSize);
      }
    } finally {
      await raf.close();
    }

    // 3. Complete
    return complete(session.uploadId);
  }
}

/// Represents an active chunked upload session
class ChunkedUploadSession {
  const ChunkedUploadSession({
    required this.uploadId,
    required this.chunkSize,
    required this.totalChunks,
  });

  final String uploadId;
  final int chunkSize;
  final int totalChunks;
}
