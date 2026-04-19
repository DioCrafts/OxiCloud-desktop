import 'package:dio/dio.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/network/api_endpoints.dart';

// --- DTOs ---

class PlaylistDto {
  final String id;
  final String name;
  final String? description;
  final String userId;
  final int trackCount;
  final int totalDuration;
  final String createdAt;
  final String updatedAt;

  const PlaylistDto({
    required this.id,
    required this.name,
    this.description,
    required this.userId,
    required this.trackCount,
    required this.totalDuration,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistDto.fromJson(Map<String, dynamic> json) {
    return PlaylistDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      userId: json['user_id'] as String,
      trackCount: json['track_count'] as int? ?? 0,
      totalDuration: json['total_duration'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class PlaylistTrackDto {
  final String fileId;
  final String filename;
  final int position;
  final int? duration;
  final String? title;
  final String? artist;
  final String? album;

  const PlaylistTrackDto({
    required this.fileId,
    required this.filename,
    required this.position,
    this.duration,
    this.title,
    this.artist,
    this.album,
  });

  factory PlaylistTrackDto.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackDto(
      fileId: json['file_id'] as String,
      filename: json['filename'] as String,
      position: json['position'] as int,
      duration: json['duration'] as int?,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
    );
  }
}

class AudioMetadataDto {
  final String fileId;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? trackNumber;
  final int? year;
  final int? duration;
  final int? bitrate;
  final int? sampleRate;
  final int? channels;
  final String? format;

  const AudioMetadataDto({
    required this.fileId,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.trackNumber,
    this.year,
    this.duration,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.format,
  });

  factory AudioMetadataDto.fromJson(Map<String, dynamic> json) {
    return AudioMetadataDto(
      fileId: json['file_id'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      genre: json['genre'] as String?,
      trackNumber: json['track_number'] as int?,
      year: json['year'] as int?,
      duration: json['duration'] as int?,
      bitrate: json['bitrate'] as int?,
      sampleRate: json['sample_rate'] as int?,
      channels: json['channels'] as int?,
      format: json['format'] as String?,
    );
  }
}

class PlaylistShareDto {
  final String userId;
  final String permission; // "read" | "write"

  const PlaylistShareDto({required this.userId, required this.permission});

  factory PlaylistShareDto.fromJson(Map<String, dynamic> json) {
    return PlaylistShareDto(
      userId: json['user_id'] as String,
      permission: json['permission'] as String,
    );
  }
}

// --- Datasource ---

class PlaylistRemoteDatasource {
  final Dio _dio;

  PlaylistRemoteDatasource(this._dio);

  // CRUD

  Future<List<PlaylistDto>> getAll() async {
    try {
      final response = await _dio.get(ApiEndpoints.playlists);
      return (response.data as List<dynamic>)
          .map((e) => PlaylistDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<PlaylistDto> getById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.playlistById(id));
      return PlaylistDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<PlaylistDto> create({
    required String name,
    String? description,
  }) async {
    try {
      final response = await _dio.post(ApiEndpoints.playlists, data: {
        'name': name,
        if (description != null) 'description': description,
      });
      return PlaylistDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<PlaylistDto> update(String id,
      {String? name, String? description}) async {
    try {
      final response = await _dio.put(ApiEndpoints.playlistById(id), data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
      });
      return PlaylistDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete(ApiEndpoints.playlistById(id));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Tracks

  Future<List<PlaylistTrackDto>> getTracks(String playlistId) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.playlistTracks(playlistId));
      return (response.data as List<dynamic>)
          .map((e) => PlaylistTrackDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> addTrack(String playlistId, String fileId,
      {int? position}) async {
    try {
      await _dio.post(ApiEndpoints.playlistTracks(playlistId), data: {
        'file_id': fileId,
        if (position != null) 'position': position,
      });
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> removeTrack(String playlistId, String fileId) async {
    try {
      await _dio.delete(ApiEndpoints.playlistTrack(playlistId, fileId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> reorderTracks(
      String playlistId, List<String> fileIds) async {
    try {
      await _dio.put(ApiEndpoints.playlistReorder(playlistId), data: {
        'track_order': fileIds,
      });
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Sharing

  Future<void> shareWith(
      String playlistId, String userId, String permission) async {
    try {
      await _dio.post(ApiEndpoints.playlistShare(playlistId), data: {
        'user_id': userId,
        'permission': permission,
      });
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<void> unshare(String playlistId, String userId) async {
    try {
      await _dio.delete(
          ApiEndpoints.playlistShareUser(playlistId, userId));
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  Future<List<PlaylistShareDto>> getShares(String playlistId) async {
    try {
      final response =
          await _dio.get(ApiEndpoints.playlistShares(playlistId));
      return (response.data as List<dynamic>)
          .map((e) => PlaylistShareDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }

  // Audio metadata

  Future<AudioMetadataDto> getAudioMetadata(String fileId) async {
    try {
      final response = await _dio.get(ApiEndpoints.audioMetadata(fileId));
      return AudioMetadataDto.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ErrorHandler.mapDioToServerException(e);
    }
  }
}
