/// Represents a synchronization conflict between local and remote versions
class SyncConflict {
  final String itemId;
  final bool isFolder;
  final dynamic localVersion;
  final dynamic remoteVersion;
  
  SyncConflict({
    required this.itemId,
    required this.isFolder,
    required this.localVersion,
    required this.remoteVersion,
  });
}