import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../../domain/repositories/file_repository.dart';
import '../../domain/repositories/folder_repository.dart';
import '../../domain/repositories/trash_repository.dart';
import '../database/app_database.dart';
import '../network/connectivity_service.dart';
import 'sync_models.dart';

class SyncEngine extends ChangeNotifier {
  final AppDatabase _db;
  final ConnectivityService _connectivity;
  final FileRepository _fileRepo;
  final FolderRepository _folderRepo;
  final FavoritesRepository _favoritesRepo;
  final TrashRepository _trashRepo;
  StreamSubscription<bool>? _connectivitySub;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncEngine({
    required AppDatabase db,
    required ConnectivityService connectivity,
    required FileRepository fileRepo,
    required FolderRepository folderRepo,
    required FavoritesRepository favoritesRepo,
    required TrashRepository trashRepo,
  })  : _db = db,
        _connectivity = connectivity,
        _fileRepo = fileRepo,
        _folderRepo = folderRepo,
        _favoritesRepo = favoritesRepo,
        _trashRepo = trashRepo {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((_) => _onConnectivityChanged());
  }

  void start({Duration interval = const Duration(seconds: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => sync());
    sync();
  }

  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> sync() async {
    if (_isSyncing || !_connectivity.isOnline) {
      _setStatus(_connectivity.isOnline ? SyncStatus.idle : SyncStatus.offline);
      return;
    }

    _isSyncing = true;
    _setStatus(SyncStatus.syncing);

    try {
      final pendingOps = await _db.getPendingSyncOps();
      _pendingCount = pendingOps.length;
      notifyListeners();

      for (final op in pendingOps) {
        if (!_connectivity.isOnline) break;
        await _processOp(op);
      }

      _setStatus(SyncStatus.idle);
    } catch (e) {
      _setStatus(SyncStatus.error);
    } finally {
      _isSyncing = false;
      _pendingCount = (await _db.getPendingSyncOps()).length;
      notifyListeners();
    }
  }

  Future<void> enqueue(SyncTask task) async {
    final now = DateTime.now();
    await _db.insertSyncOp(SyncQueueTableCompanion.insert(
      operationType: task.operation.name,
      itemId: task.entityId,
      itemType: task.entityType,
      payload: task.payload?.toString() ?? '{}',
      createdAt: task.createdAt,
      updatedAt: now,
    ));
    _pendingCount++;
    notifyListeners();
    if (_connectivity.isOnline) {
      await sync();
    }
  }

  Future<void> _processOp(SyncQueueTableData op) async {
    try {
      await _db.updateSyncOpStatus(op.id, 'inProgress');
      final payload = json.decode(op.payload) as Map<String, dynamic>;

      switch (op.operationType) {
        // --- File operations ---
        case 'delete':
          await _fileRepo.deleteFile(op.itemId);
        case 'rename':
          final newName = payload['new_name'] as String;
          await _fileRepo.renameFile(op.itemId, newName);
        case 'move':
          final targetFolderId = payload['target_folder_id'] as String;
          await _fileRepo.moveFile(op.itemId, targetFolderId);

        // --- Folder operations ---
        case 'createFolder':
          final name = payload['name'] as String;
          final parentId = payload['parent_id'] as String?;
          await _folderRepo.createFolder(name: name, parentId: parentId);
        case 'deleteFolder':
          await _folderRepo.deleteFolder(op.itemId);
        case 'renameFolder':
          final newName = payload['new_name'] as String;
          await _folderRepo.renameFolder(op.itemId, newName);
        case 'moveFolder':
          final newParentId = payload['new_parent_id'] as String?;
          await _folderRepo.moveFolder(op.itemId, newParentId);

        // --- Favorites ---
        case 'favorite':
          await _favoritesRepo.addFavorite(op.itemType, op.itemId);
        case 'unfavorite':
          await _favoritesRepo.removeFavorite(op.itemType, op.itemId);

        // --- Trash ---
        case 'trash':
          if (op.itemType == 'file') {
            await _fileRepo.deleteFile(op.itemId);
          } else {
            await _folderRepo.deleteFolder(op.itemId);
          }
        case 'restore':
          await _trashRepo.restoreItem(op.itemId);

        default:
          await _db.updateSyncOpStatus(op.id, 'failed',
              errorMessage: 'Unknown operation: ${op.operationType}');
          return;
      }

      await _db.updateSyncOpStatus(op.id, 'completed');
    } catch (e) {
      final newRetryCount = op.retryCount + 1;
      if (newRetryCount >= 5) {
        await _db.updateSyncOpStatus(op.id, 'failed',
            errorMessage: e.toString());
        // Record as sync conflict for user resolution
        await _db.insertSyncConflict(SyncConflictsTableCompanion.insert(
          itemId: op.itemId,
          itemType: op.itemType,
          operationType: op.operationType,
          payload: op.payload,
          errorMessage: Value(e.toString()),
          createdAt: DateTime.now(),
        ));
      } else {
        await _db.incrementSyncOpRetry(op.id);
      }
    }
  }

  void _onConnectivityChanged() {
    if (_connectivity.isOnline) {
      sync();
    } else {
      _setStatus(SyncStatus.offline);
    }
  }

  void _setStatus(SyncStatus s) {
    if (_status != s) {
      _status = s;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stop();
    _connectivitySub?.cancel();
    super.dispose();
  }
}
