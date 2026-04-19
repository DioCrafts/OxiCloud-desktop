import 'dart:typed_data';

import '../../core/database/app_database.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/repositories/file_repository.dart';
import '../datasources/remote/file_remote_datasource.dart';
import '../mappers/file_mapper.dart';
import 'package:drift/drift.dart';

class FileRepositoryImpl implements FileRepository {
  final FileRemoteDatasource _remote;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  FileRepositoryImpl({
    required FileRemoteDatasource remote,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _db = db,
        _connectivity = connectivity;

  @override
  Future<List<FileEntity>> listFiles({String? folderId}) async {
    if (_connectivity.isOnline) {
      try {
        final dtos = await _remote.listFiles(folderId: folderId);
        final entities = FileMapper.fromDtoList(dtos);

        // Cache in local DB
        final companions = entities.map((e) => _entityToCompanion(e)).toList();
        await _db.upsertFiles(companions);

        return entities;
      } catch (_) {
        // Fallback to local cache on error
        return _getLocalFiles(folderId);
      }
    }
    return _getLocalFiles(folderId);
  }

  @override
  Future<FileEntity> getFile(String id) async {
    if (_connectivity.isOnline) {
      final dto = await _remote.getFile(id);
      final entity = FileMapper.fromDto(dto);
      await _db.upsertFile(_entityToCompanion(entity));
      return entity;
    }
    final local = await _db.getFileById(id);
    if (local == null) throw Exception('File not found in local cache');
    return _dataToEntity(local);
  }

  @override
  Future<FileEntity> uploadFile({
    required String name,
    required String? folderId,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String mimeType,
  }) async {
    final dto = await _remote.uploadFile(
      name: name,
      folderId: folderId,
      fileStream: fileStream,
      fileSize: fileSize,
      mimeType: mimeType,
    );
    final entity = FileMapper.fromDto(dto);
    await _db.upsertFile(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<Stream<List<int>>> downloadFile(String id) async {
    final body = await _remote.downloadFile(id);
    return body.stream;
  }

  @override
  Future<String> downloadFileToPath(String id, String localPath) async {
    await _remote.downloadFileToPath(id, localPath);
    return localPath;
  }

  @override
  Future<void> deleteFile(String id) async {
    if (_connectivity.isOnline) {
      await _remote.deleteFile(id);
    }
    await _db.deleteFileById(id);
  }

  @override
  Future<FileEntity> renameFile(String id, String newName) async {
    final dto = await _remote.renameFile(id, newName);
    final entity = FileMapper.fromDto(dto);
    await _db.upsertFile(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<FileEntity> moveFile(String id, String targetFolderId) async {
    final dto = await _remote.moveFile(id, targetFolderId);
    final entity = FileMapper.fromDto(dto);
    await _db.upsertFile(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<Uint8List> getThumbnail(String id, {String size = '256'}) {
    return _remote.getThumbnail(id, size: size);
  }

  // --- Private helpers ---

  Future<List<FileEntity>> _getLocalFiles(String? folderId) async {
    final rows = await _db.getFilesInFolder(folderId);
    return rows.map(_dataToEntity).toList();
  }

  FileEntity _dataToEntity(FilesTableData row) {
    return FileEntity(
      id: row.id,
      name: row.name,
      path: row.path,
      size: row.size,
      mimeType: row.mimeType,
      folderId: row.folderId,
      ownerId: row.ownerId,
      hash: row.hash,
      etag: row.etag,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
      isFavorite: row.isFavorite,
      isAvailableOffline: row.isAvailableOffline,
      localCachePath: row.localCachePath,
    );
  }

  FilesTableCompanion _entityToCompanion(FileEntity e) {
    return FilesTableCompanion(
      id: Value(e.id),
      name: Value(e.name),
      path: Value(e.path),
      size: Value(e.size),
      mimeType: Value(e.mimeType),
      folderId: Value(e.folderId),
      ownerId: Value(e.ownerId),
      hash: Value(e.hash),
      etag: Value(e.etag),
      createdAt: Value(e.createdAt),
      modifiedAt: Value(e.modifiedAt),
      isFavorite: Value(e.isFavorite),
      isAvailableOffline: Value(e.isAvailableOffline),
      localCachePath: Value(e.localCachePath),
    );
  }
}
