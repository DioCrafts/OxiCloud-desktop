import 'dart:typed_data';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/domain/entities/conflict_resolution.dart';
import 'package:oxicloud_desktop/domain/entities/file.dart' as file_entity;
import 'package:oxicloud_desktop/domain/entities/folder.dart';
import 'package:oxicloud_desktop/domain/entities/sync_conflict.dart';
import 'package:oxicloud_desktop/domain/repositories/sync_repository.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_file_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_folder_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/services/local_storage_manager.dart';

/// Implements the sync repository using WebDAV for file synchronization
class WebDAVSyncEngine implements SyncRepository {
  final WebDAVFileAdapter _fileAdapter;
  final WebDAVFolderAdapter _folderAdapter;
  final LocalStorageManager _storageManager;
  final ConnectivityService _connectivityService;
  final Logger _logger = LoggingManager.getLogger('WebDAVSyncEngine');
  
  /// Create a WebDAVSyncEngine
  WebDAVSyncEngine(
    this._fileAdapter,
    this._folderAdapter,
    this._storageManager,
    this._connectivityService,
  );
  
  /// Key for last sync timestamp
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  
  /// Key for pending changes
  static const String _pendingChangesKey = 'pending_changes';
  
  @override
  Future<SyncChanges> getChangesSince(DateTime timestamp) async {
    try {
      // Check connectivity
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        throw Exception('No network connectivity');
      }
      
      final fileChanges = <SyncChange>[];
      final folderChanges = <SyncChange>[];
      
      // Fetch changes from the server
      // Note: This is a simplified implementation
      // In a real implementation, you would use WebDAV specific features
      // to get changes since a timestamp
      
      // 1. Get all folders and files recursively
      final folderList = await _getFoldersList();
      final fileList = await _getFilesList();
      
      // 2. Compare with local cache to detect changes
      for (final folder in folderList) {
        // Check if folder is new or modified since last sync
        if (folder.modifiedAt.isAfter(timestamp)) {
          // Detect change type
          final changeType = _detectChangeType(folder.id, folder.modifiedAt);
          
          folderChanges.add(SyncChange(
            type: changeType,
            itemId: folder.id,
            isFolder: true,
            item: folder,
            timestamp: folder.modifiedAt,
          ));
        }
      }
      
      for (final file in fileList) {
        // Check if file is new or modified since last sync
        if (file.modifiedAt.isAfter(timestamp)) {
          // Detect change type
          final changeType = _detectChangeType(file.id, file.modifiedAt);
          
          fileChanges.add(SyncChange(
            type: changeType,
            itemId: file.id,
            isFolder: false,
            item: file,
            timestamp: file.modifiedAt,
          ));
        }
      }
      
      // 3. Detect deletions (items in local cache but not on server)
      // This is a simplified implementation
      // In a real implementation, you would track deletes from the server
      
      return SyncChanges(
        fileChanges: fileChanges,
        folderChanges: folderChanges,
      );
    } catch (e) {
      _logger.warning('Failed to get changes since $timestamp: $e');
      rethrow;
    }
  }
  
  /// Get a list of all folders (simplified)
  Future<List<Folder>> _getFoldersList() async {
    try {
      // Start with root folder
      final rootFolder = await _folderAdapter.getRootFolder();
      return [rootFolder];
      
      // In a real implementation, you would recursively fetch all folders
      // This is simplified for brevity
    } catch (e) {
      _logger.warning('Failed to get folders list: $e');
      return [];
    }
  }
  
  /// Get a list of all files (simplified)
  Future<List<file_entity.File>> _getFilesList() async {
    try {
      // Start with root folder
      final rootFolder = await _folderAdapter.getRootFolder();
      return await _fileAdapter.listFiles(rootFolder.id);
      
      // In a real implementation, you would recursively fetch all files
      // This is simplified for brevity
    } catch (e) {
      _logger.warning('Failed to get files list: $e');
      return [];
    }
  }
  
  /// Detect the type of change for an item
  ChangeType _detectChangeType(String itemId, DateTime modifiedAt) {
    // This is a simplified implementation
    // In a real implementation, you would track item history
    
    // Default to "modified" for existing items
    return ChangeType.modified;
  }
  
  @override
  Future<void> applyRemoteChanges(SyncChanges changes) async {
    try {
      // Process folder changes first (in the right order: creations before modifications)
      // Sort folder changes by type and timestamp
      final sortedFolderChanges = List<SyncChange>.from(changes.folderChanges)
        ..sort((a, b) {
          if (a.type != b.type) {
            // Process creations first, then modifications, then deletions
            return a.type.index - b.type.index;
          }
          return a.timestamp.compareTo(b.timestamp);
        });
      
      for (final change in sortedFolderChanges) {
        await _applyFolderChange(change);
      }
      
      // Process file changes
      for (final change in changes.fileChanges) {
        await _applyFileChange(change);
      }
    } catch (e) {
      _logger.warning('Failed to apply remote changes: $e');
      rethrow;
    }
  }
  
  /// Apply a folder change
  Future<void> _applyFolderChange(SyncChange change) async {
    try {
      switch (change.type) {
        case ChangeType.created:
        case ChangeType.modified:
          // For created or modified folders, ensure they exist locally
          final folder = change.item as Folder;
          // In a real implementation, you would update local database
          break;
        case ChangeType.deleted:
          // For deleted folders, remove them from local storage
          // In a real implementation, you would update local database
          break;
        case ChangeType.moved:
          // For moved folders, update their path
          // In a real implementation, you would update local database
          break;
      }
    } catch (e) {
      _logger.warning('Failed to apply folder change: ${change.itemId} - $e');
      throw Exception('Failed to apply folder change: ${change.itemId}');
    }
  }
  
  /// Apply a file change
  Future<void> _applyFileChange(SyncChange change) async {
    try {
      switch (change.type) {
        case ChangeType.created:
        case ChangeType.modified:
          // For created or modified files, download them and update local cache
          final file = change.item as file_entity.File;
          
          // Check if file should be kept offline
          final isOffline = false; // In a real implementation, check if marked for offline use
          
          if (isOffline) {
            // Download and store offline
            final fileData = await _fileAdapter.downloadFile(file.id);
            await _storageManager.ensureOffline(file.id, fileData, name: file.name);
          } else {
            // Check if it's in the cache
            final cachedFile = await _storageManager.getCachedFile(file.id);
            if (cachedFile != null) {
              // If cached, update it
              final fileData = await _fileAdapter.downloadFile(file.id);
              await _storageManager.cacheFile(file.id, fileData, name: file.name);
            }
            // If not cached, don't download (save bandwidth)
          }
          
          // In a real implementation, you would update local database
          break;
        case ChangeType.deleted:
          // For deleted files, remove them from local storage
          await _storageManager.removeFromCache(change.itemId);
          
          // In a real implementation, you would update local database
          break;
        case ChangeType.moved:
          // For moved files, update their path
          // In a real implementation, you would update local database
          break;
      }
    } catch (e) {
      _logger.warning('Failed to apply file change: ${change.itemId} - $e');
      throw Exception('Failed to apply file change: ${change.itemId}');
    }
  }
  
  @override
  Future<SyncChanges> getLocalChanges() async {
    try {
      // Retrieve pending changes from storage
      final pendingChanges = _storageManager.getSyncState(_pendingChangesKey);
      
      if (pendingChanges == null) {
        // No pending changes
        return const SyncChanges();
      }
      
      // Deserialize pending changes
      // In a real implementation, you would deserialize the changes
      // from the stored format
      
      return const SyncChanges();
    } catch (e) {
      _logger.warning('Failed to get local changes: $e');
      return const SyncChanges();
    }
  }
  
  @override
  Future<void> pushLocalChanges(SyncChanges changes) async {
    try {
      // Check connectivity
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        // Store the changes for later
        await _storePendingChanges(changes);
        throw Exception('No network connectivity');
      }
      
      // Process folder changes first
      for (final change in changes.folderChanges) {
        await _pushFolderChange(change);
      }
      
      // Process file changes
      for (final change in changes.fileChanges) {
        await _pushFileChange(change);
      }
      
      // Clear pending changes
      await _storageManager.storeSyncState(_pendingChangesKey, null);
    } catch (e) {
      _logger.warning('Failed to push local changes: $e');
      // If there was an error, store the changes for later
      await _storePendingChanges(changes);
      rethrow;
    }
  }
  
  /// Store pending changes for later synchronization
  Future<void> _storePendingChanges(SyncChanges changes) async {
    try {
      // Merge with existing pending changes
      final existingChanges = await getLocalChanges();
      
      // In a real implementation, you would merge the changes
      // and remove any duplicates
      
      // Store the merged changes
      await _storageManager.storeSyncState(_pendingChangesKey, changes);
    } catch (e) {
      _logger.warning('Failed to store pending changes: $e');
    }
  }
  
  /// Push a folder change to the server
  Future<void> _pushFolderChange(SyncChange change) async {
    try {
      switch (change.type) {
        case ChangeType.created:
          final folder = change.item as Folder;
          
          // Create the folder on the server
          await _folderAdapter.createFolder(
            parentFolderId: folder.parentId ?? '/',
            name: folder.name,
          );
          break;
        case ChangeType.modified:
          final folder = change.item as Folder;
          
          // Rename the folder on the server
          await _folderAdapter.renameFolder(folder.id, folder.name);
          break;
        case ChangeType.deleted:
          // Delete the folder on the server
          await _folderAdapter.deleteFolder(change.itemId);
          break;
        case ChangeType.moved:
          final folder = change.item as Folder;
          
          // Move the folder on the server
          await _folderAdapter.moveFolder(folder.id, folder.parentId ?? '/');
          break;
      }
    } catch (e) {
      _logger.warning('Failed to push folder change: ${change.itemId} - $e');
      throw Exception('Failed to push folder change: ${change.itemId}');
    }
  }
  
  /// Push a file change to the server
  Future<void> _pushFileChange(SyncChange change) async {
    try {
      switch (change.type) {
        case ChangeType.created:
          final file = change.item as file_entity.File;
          
          // Get file data from local cache
          final cachedFile = await _storageManager.getCachedFile(file.id);
          if (cachedFile == null) {
            throw Exception('File not found in local cache: ${file.id}');
          }
          
          // Read file data
          final data = await cachedFile.readAsBytes();
          
          // Upload the file to the server
          await _fileAdapter.uploadFile(
            parentFolderId: file.parentPath,
            name: file.name,
            data: data,
          );
          break;
        case ChangeType.modified:
          final file = change.item as file_entity.File;
          
          // Get file data from local cache
          final cachedFile = await _storageManager.getCachedFile(file.id);
          if (cachedFile == null) {
            throw Exception('File not found in local cache: ${file.id}');
          }
          
          // Read file data
          final data = await cachedFile.readAsBytes();
          
          // Update the file on the server
          await _fileAdapter.updateFile(
            fileId: file.id,
            data: data,
          );
          break;
        case ChangeType.deleted:
          // Delete the file on the server
          await _fileAdapter.deleteFile(change.itemId);
          break;
        case ChangeType.moved:
          final file = change.item as file_entity.File;
          
          // Move the file on the server
          await _fileAdapter.moveFile(file.id, file.parentPath);
          break;
      }
    } catch (e) {
      _logger.warning('Failed to push file change: ${change.itemId} - $e');
      throw Exception('Failed to push file change: ${change.itemId}');
    }
  }
  
  @override
  Future<void> resolveConflict({
    required String itemId,
    required ConflictResolution resolution,
  }) async {
    try {
      // Get conflict information
      final conflict = _getConflict(itemId);
      if (conflict == null) {
        throw Exception('No conflict found for item: $itemId');
      }
      
      switch (resolution) {
        case ConflictResolution.keepLocal:
          // Push local version to server
          if (conflict.isFolder) {
            await _pushFolderChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: true,
              item: conflict.localVersion,
              timestamp: DateTime.now(),
            ));
          } else {
            await _pushFileChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: false,
              item: conflict.localVersion,
              timestamp: DateTime.now(),
            ));
          }
          break;
        case ConflictResolution.keepRemote:
          // Apply remote version locally
          if (conflict.isFolder) {
            await _applyFolderChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: true,
              item: conflict.remoteVersion,
              timestamp: DateTime.now(),
            ));
          } else {
            await _applyFileChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: false,
              item: conflict.remoteVersion,
              timestamp: DateTime.now(),
            ));
          }
          break;
        case ConflictResolution.keepBoth:
          // Rename local version
          if (conflict.isFolder) {
            // For folders, rename the local version
            final localFolder = conflict.localVersion as Folder;
            final newName = '${localFolder.name} (local)';
            
            // Create a new folder with the local version
            await _folderAdapter.createFolder(
              parentFolderId: localFolder.parentId ?? '/',
              name: newName,
            );
            
            // Apply remote version to original item
            await _applyFolderChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: true,
              item: conflict.remoteVersion,
              timestamp: DateTime.now(),
            ));
          } else {
            // For files, rename the local version
            final localFile = conflict.localVersion as file_entity.File;
            final newName = '${localFile.name} (local)';
            
            // Get file data from local cache
            final cachedFile = await _storageManager.getCachedFile(localFile.id);
            if (cachedFile == null) {
              throw Exception('File not found in local cache: ${localFile.id}');
            }
            
            // Read file data
            final data = await cachedFile.readAsBytes();
            
            // Upload as a new file
            await _fileAdapter.uploadFile(
              parentFolderId: localFile.parentPath,
              name: newName,
              data: data,
            );
            
            // Apply remote version to original item
            await _applyFileChange(SyncChange(
              type: ChangeType.modified,
              itemId: itemId,
              isFolder: false,
              item: conflict.remoteVersion,
              timestamp: DateTime.now(),
            ));
          }
          break;
      }
      
      // Clear the conflict
      _clearConflict(itemId);
    } catch (e) {
      _logger.warning('Failed to resolve conflict: $itemId - $e');
      rethrow;
    }
  }
  
  /// Get conflict information
  SyncConflict? _getConflict(String itemId) {
    // In a real implementation, you would store and retrieve
    // conflicts from a local database
    return null;
  }
  
  /// Clear a conflict
  void _clearConflict(String itemId) {
    // In a real implementation, you would remove the conflict
    // from a local database
  }
  
  @override
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final timestamp = _storageManager.getSyncState(_lastSyncTimestampKey);
      
      if (timestamp == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    } catch (e) {
      _logger.warning('Failed to get last sync timestamp: $e');
      return null;
    }
  }
  
  @override
  Future<void> updateLastSyncTimestamp(DateTime timestamp) async {
    try {
      await _storageManager.storeSyncState(
        _lastSyncTimestampKey,
        timestamp.millisecondsSinceEpoch,
      );
    } catch (e) {
      _logger.warning('Failed to update last sync timestamp: $e');
    }
  }
}