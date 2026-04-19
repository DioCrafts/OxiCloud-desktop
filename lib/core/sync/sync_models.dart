enum SyncStatus { idle, syncing, error, offline }

enum SyncOperation { upload, download, delete, rename, move }

class SyncTask {
  final String id;
  final SyncOperation operation;
  final String entityType; // 'file' or 'folder'
  final String entityId;
  final Map<String, dynamic>? payload;
  final int retryCount;
  final DateTime createdAt;

  const SyncTask({
    required this.id,
    required this.operation,
    required this.entityType,
    required this.entityId,
    this.payload,
    this.retryCount = 0,
    required this.createdAt,
  });
}
