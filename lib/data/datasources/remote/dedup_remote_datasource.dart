import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

/// Dedup check result.
class DedupCheckResult {
  final bool exists;
  final String? fileId;

  const DedupCheckResult({required this.exists, this.fileId});

  factory DedupCheckResult.fromJson(Map<String, dynamic> json) {
    return DedupCheckResult(
      exists: json['exists'] as bool,
      fileId: json['file_id'] as String?,
    );
  }
}

/// Dedup upload result.
class DedupUploadResult {
  final String fileId;
  final bool deduplicated;
  final int savedBytes;

  const DedupUploadResult({
    required this.fileId,
    required this.deduplicated,
    required this.savedBytes,
  });

  factory DedupUploadResult.fromJson(Map<String, dynamic> json) {
    return DedupUploadResult(
      fileId: json['file_id'] as String,
      deduplicated: json['deduplicated'] as bool? ?? false,
      savedBytes: json['saved_bytes'] as int? ?? 0,
    );
  }
}

/// Dedup stats (admin).
class DedupStats {
  final int totalFiles;
  final int uniqueBlobs;
  final int totalSizeBytes;
  final int dedupedSizeBytes;
  final double savingsPercent;

  const DedupStats({
    required this.totalFiles,
    required this.uniqueBlobs,
    required this.totalSizeBytes,
    required this.dedupedSizeBytes,
    required this.savingsPercent,
  });

  factory DedupStats.fromJson(Map<String, dynamic> json) {
    return DedupStats(
      totalFiles: json['total_files'] as int? ?? 0,
      uniqueBlobs: json['unique_blobs'] as int? ?? 0,
      totalSizeBytes: json['total_size_bytes'] as int? ?? 0,
      dedupedSizeBytes: json['deduped_size_bytes'] as int? ?? 0,
      savingsPercent: (json['savings_percent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DedupRemoteDatasource {
  final Dio _dio;

  DedupRemoteDatasource(this._dio);

  /// Check if a file with the given BLAKE3 hash already exists.
  Future<DedupCheckResult> check(String hash) async {
    try {
      final response = await _dio.get(ApiEndpoints.dedupCheck(hash));
      return DedupCheckResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Upload a file with dedup support (multipart).
  Future<DedupUploadResult> upload({
    required String filename,
    required String hash,
    required Uint8List fileBytes,
    required String folderId,
    String? contentType,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: filename,
          contentType: contentType != null
              ? DioMediaType.parse(contentType)
              : null,
        ),
        'hash': hash,
        'folder_id': folderId,
      });
      final response =
          await _dio.post(ApiEndpoints.dedupUpload, data: formData);
      return DedupUploadResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Get dedup statistics (admin only).
  Future<DedupStats> getStats() async {
    try {
      final response = await _dio.get(ApiEndpoints.dedupStats);
      return DedupStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  /// Download a blob by hash.
  Future<Uint8List> getBlob(String hash) async {
    try {
      final response = await _dio.get<List<int>>(
        ApiEndpoints.dedupBlob(hash),
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
