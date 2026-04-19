import '../../core/database/app_database.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/entities/file_entity.dart';
import '../../domain/entities/folder_entity.dart';
import '../../domain/repositories/folder_repository.dart';
import '../datasources/remote/folder_remote_datasource.dart';
import '../dtos/folders/folder_dtos.dart';
import '../mappers/file_mapper.dart';
import '../mappers/folder_mapper.dart';
import 'package:drift/drift.dart';

class FolderRepositoryImpl implements FolderRepository {
  final FolderRemoteDatasource _remote;
  final AppDatabase _db;
  final ConnectivityService _connectivity;

  FolderRepositoryImpl({
    required FolderRemoteDatasource remote,
    required AppDatabase db,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _db = db,
        _connectivity = connectivity;

  @override
  Future<List<FolderEntity>> listRootFolders() async {
    if (_connectivity.isOnline) {
      try {
        final dtos = await _remote.listRootFolders();
        final entities = FolderMapper.fromDtoList(dtos);
        await _cacheFolders(entities);
        return entities;
      } catch (_) {
        return _getLocalFolders(null);
      }
    }
    return _getLocalFolders(null);
  }

  @override
  Future<FolderContents> listFolderContents(String folderId) async {
    if (_connectivity.isOnline) {
      try {
        final result = await _remote.listFolderContents(folderId);
        final folders = FolderMapper.fromDtoList(result.folders);
        final files = FileMapper.fromDtoList(result.files);
        await _cacheFolders(folders);
        return FolderContents(folders: folders, files: files);
      } catch (_) {
        return _getLocalContents(folderId);
      }
    }
    return _getLocalContents(folderId);
  }

  @override
  Future<FolderEntity> getFolder(String id) async {
    if (_connectivity.isOnline) {
      final dto = await _remote.getFolder(id);
      final entity = FolderMapper.fromDto(dto);
      await _db.upsertFolder(_entityToCompanion(entity));
      return entity;
    }
    final local = await _db.getFolderById(id);
    if (local == null) throw Exception('Folder not found in local cache');
    return _dataToEntity(local);
  }

  @override
  Future<FolderEntity> createFolder({
    required String name,
    String? parentId,
  }) async {
    final dto = await _remote.createFolder(
      CreateFolderRequestDto(name: name, parentId: parentId),
    );
    final entity = FolderMapper.fromDto(dto);
    await _db.upsertFolder(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<FolderEntity> renameFolder(String id, String newName) async {
    final dto = await _remote.renameFolder(id, newName);
    final entity = FolderMapper.fromDto(dto);
    await _db.upsertFolder(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<FolderEntity> moveFolder(String id, String? newParentId) async {
    final dto = await _remote.moveFolder(id, newParentId);
    final entity = FolderMapper.fromDto(dto);
    await _db.upsertFolder(_entityToCompanion(entity));
    return entity;
  }

  @override
  Future<void> deleteFolder(String id) async {
    if (_connectivity.isOnline) {
      await _remote.deleteFolder(id);
    }
    await _db.deleteFolderById(id);
  }

  @override
  Future<Stream<List<int>>> downloadFolderZip(String id) async {
    final body = await _remote.downloadFolderZip(id);
    return body.stream;
  }

  // --- Private helpers ---

  Future<FolderContents> _getLocalContents(String folderId) async {
    final folderRows = await _db.getFoldersInParent(folderId);
    final fileRows = await _db.getFilesInFolder(folderId);
    return FolderContents(
      folders: folderRows.map(_dataToEntity).toList(),
      files: fileRows
          .map(
            (r) => FileEntity(
              id: r.id,
              name: r.name,
              path: r.path,
              size: r.size,
              mimeType: r.mimeType,
              folderId: r.folderId,
              createdAt: r.createdAt,
              modifiedAt: r.modifiedAt,
              isFavorite: r.isFavorite,
              isAvailableOffline: r.isAvailableOffline,
              localCachePath: r.localCachePath,
            ),
          )
          .toList(),
    );
  }

  Future<List<FolderEntity>> _getLocalFolders(String? parentId) async {
    final rows = await _db.getFoldersInParent(parentId);
    return rows.map(_dataToEntity).toList();
  }

  Future<void> _cacheFolders(List<FolderEntity> folders) async {
    final companions = folders.map(_entityToCompanion).toList();
    await _db.upsertFolders(companions);
  }

  FolderEntity _dataToEntity(FoldersTableData row) {
    return FolderEntity(
      id: row.id,
      name: row.name,
      path: row.path,
      parentId: row.parentId,
      ownerId: row.ownerId,
      isRoot: row.isRoot,
      createdAt: row.createdAt,
      modifiedAt: row.modifiedAt,
    );
  }

  FoldersTableCompanion _entityToCompanion(FolderEntity e) {
    return FoldersTableCompanion(
      id: Value(e.id),
      name: Value(e.name),
      path: Value(e.path),
      parentId: Value(e.parentId),
      ownerId: Value(e.ownerId),
      isRoot: Value(e.isRoot),
      createdAt: Value(e.createdAt),
      modifiedAt: Value(e.modifiedAt),
    );
  }
}
