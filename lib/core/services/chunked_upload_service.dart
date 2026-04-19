import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../data/datasources/remote/chunked_upload_datasource.dart';

/// High-level service that splits large files into chunks and manages the upload.
class ChunkedUploadService {
  final ChunkedUploadDatasource _datasource;

  /// Files above this size will use chunked upload (10 MB).
  static const int chunkThreshold = 10 * 1024 * 1024;

  /// Default chunk size (5 MB).
  static const int defaultChunkSize = 5 * 1024 * 1024;

  ChunkedUploadService(this._datasource);

  /// Upload a large file in chunks.
  /// [onProgress] reports 0.0–1.0 progress.
  Future<ChunkedUploadResult> uploadFile({
    required File file,
    required String filename,
    String? folderId,
    String? contentType,
    ValueChanged<double>? onProgress,
  }) async {
    final totalSize = await file.length();

    // 1. Create session
    final session = await _datasource.createSession(
      filename: filename,
      folderId: folderId,
      contentType: contentType,
      totalSize: totalSize,
      chunkSize: defaultChunkSize,
    );

    try {
      final chunkSize = session.chunkSize;
      final totalChunks = session.totalChunks;

      // 2. Upload each chunk
      final raf = await file.open();
      try {
        for (var i = 0; i < totalChunks; i++) {
          final offset = i * chunkSize;
          final length = min(chunkSize, totalSize - offset);

          await raf.setPosition(offset);
          final bytes = await raf.read(length);

          await _datasource.uploadChunk(
            uploadId: session.uploadId,
            chunkIndex: i,
            data: Uint8List.fromList(bytes),
          );

          onProgress?.call((i + 1) / totalChunks);
        }
      } finally {
        await raf.close();
      }

      // 3. Complete
      return await _datasource.complete(session.uploadId);
    } catch (e) {
      // Cancel on failure
      try {
        await _datasource.cancel(session.uploadId);
      } catch (_) {}
      rethrow;
    }
  }
}
