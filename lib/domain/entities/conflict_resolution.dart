/// Represents the possible ways to resolve a sync conflict
enum ConflictResolution {
  /// Keep the local version and overwrite the remote version
  keepLocal,
  
  /// Keep the remote version and overwrite the local version
  keepRemote,
  
  /// Keep both versions by renaming the local version
  keepBoth
}