import 'package:oxicloud_desktop/domain/entities/file.dart';
import 'package:oxicloud_desktop/domain/entities/folder.dart';

/// Repository interface for synchronization operations
abstract class SyncRepository {
  /// Get changes since a timestamp
  Future<SyncChanges> getChangesSince(DateTime timestamp);
  
  /// Apply remote changes locally
  Future<void> applyRemoteChanges(SyncChanges changes);
  
  /// Get local changes
  Future<SyncChanges> getLocalChanges();
  
  /// Push local changes to server
  Future<void> pushLocalChanges(SyncChanges changes);
  
  /// Resolve conflict between local and remote versions
  Future<void> resolveConflict({
    required String itemId,
    required ConflictResolution resolution,
  });
  
  /// Get the timestamp of the last synchronization
  Future<DateTime?> getLastSyncTimestamp();
  
  /// Update the timestamp of the last synchronization
  Future<void> updateLastSyncTimestamp(DateTime timestamp);
}

/// Types of sync changes
enum ChangeType {
  /// Item created
  created,
  
  /// Item modified
  modified,
  
  /// Item deleted
  deleted,
  
  /// Item moved
  moved,
}

/// Represents a sync change
class SyncChange {
  /// Type of change
  final ChangeType type;
  
  /// Item ID
  final String itemId;
  
  /// Whether the item is a folder
  final bool isFolder;
  
  /// New item (for created/modified)
  final dynamic item;
  
  /// Old path (for moved)
  final String? oldPath;
  
  /// New path (for moved)
  final String? newPath;
  
  /// Timestamp of the change
  final DateTime timestamp;
  
  /// Creates a sync change
  const SyncChange({
    required this.type,
    required this.itemId,
    required this.isFolder,
    this.item,
    this.oldPath,
    this.newPath,
    required this.timestamp,
  });
}

/// Represents a collection of sync changes
class SyncChanges {
  /// File changes
  final List<SyncChange> fileChanges;
  
  /// Folder changes
  final List<SyncChange> folderChanges;
  
  /// Creates a collection of sync changes
  const SyncChanges({
    this.fileChanges = const [],
    this.folderChanges = const [],
  });
  
  /// Check if there are any changes
  bool get hasChanges => fileChanges.isNotEmpty || folderChanges.isNotEmpty;
  
  /// Get all changes
  List<SyncChange> get allChanges => [...folderChanges, ...fileChanges];
  
  /// Get the number of changes
  int get changeCount => fileChanges.length + folderChanges.length;
}

/// Conflict resolution strategies
enum ConflictResolution {
  /// Keep the local version
  keepLocal,
  
  /// Keep the remote version
  keepRemote,
  
  /// Keep both versions (rename local)
  keepBoth,
}