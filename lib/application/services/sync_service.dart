import 'dart:async';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/core/network/network_info.dart';
import 'package:oxicloud_desktop/domain/repositories/sync_repository.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';

/// Status of the synchronization process
enum SyncStatus {
  /// Sync in progress
  syncing,
  
  /// Last sync was successful
  synced,
  
  /// Last sync failed
  failed,
  
  /// Sync is paused
  paused,
  
  /// Sync has conflicts that need resolution
  conflict,
  
  /// No previous sync
  initial,
}

/// Statistics about a sync operation
class SyncStats {
  /// Number of files uploaded
  final int filesUploaded;
  
  /// Number of files downloaded
  final int filesDownloaded;
  
  /// Number of files deleted
  final int filesDeleted;
  
  /// Number of folders created
  final int foldersCreated;
  
  /// Number of folders deleted
  final int foldersDeleted;
  
  /// Number of conflicts
  final int conflicts;
  
  /// Total bytes uploaded
  final int bytesUploaded;
  
  /// Total bytes downloaded
  final int bytesDownloaded;
  
  /// Duration of the sync operation
  final Duration duration;
  
  /// Timestamp of the sync
  final DateTime timestamp;
  
  /// Creates sync statistics
  const SyncStats({
    this.filesUploaded = 0,
    this.filesDownloaded = 0,
    this.filesDeleted = 0,
    this.foldersCreated = 0,
    this.foldersDeleted = 0,
    this.conflicts = 0,
    this.bytesUploaded = 0,
    this.bytesDownloaded = 0,
    required this.duration,
    required this.timestamp,
  });
  
  /// Creates sync statistics with all values set to 0
  factory SyncStats.initial() {
    return SyncStats(
      duration: Duration.zero,
      timestamp: DateTime.now(),
    );
  }
  
  /// Get a string representation of the sync stats
  String get summary {
    final parts = <String>[];
    
    if (filesUploaded > 0) {
      parts.add('$filesUploaded files uploaded');
    }
    if (filesDownloaded > 0) {
      parts.add('$filesDownloaded files downloaded');
    }
    if (filesDeleted > 0) {
      parts.add('$filesDeleted files deleted');
    }
    if (foldersCreated > 0) {
      parts.add('$foldersCreated folders created');
    }
    if (foldersDeleted > 0) {
      parts.add('$foldersDeleted folders deleted');
    }
    if (conflicts > 0) {
      parts.add('$conflicts conflicts');
    }
    
    if (parts.isEmpty) {
      return 'No changes';
    }
    
    return parts.join(', ');
  }
}

/// Application service for synchronization operations
class SyncService {
  final SyncRepository _syncRepository;
  final ConnectivityService _connectivityService;
  final ResourceManager _resourceManager;
  final Logger _logger = LoggingManager.getLogger('SyncService');
  
  final StreamController<SyncStatus> _statusController = 
      StreamController<SyncStatus>.broadcast();
  
  final StreamController<SyncStats> _statsController = 
      StreamController<SyncStats>.broadcast();
  
  Timer? _syncTimer;
  SyncStatus _currentStatus = SyncStatus.initial;
  SyncStats _lastStats = SyncStats.initial();
  DateTime? _lastSyncTime;
  bool _syncInProgress = false;
  
  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream => _statusController.stream;
  
  /// Stream of sync statistics
  Stream<SyncStats> get statsStream => _statsController.stream;
  
  /// Current sync status
  SyncStatus get currentStatus => _currentStatus;
  
  /// Last sync statistics
  SyncStats get lastStats => _lastStats;
  
  /// Last sync time
  DateTime? get lastSyncTime => _lastSyncTime;
  
  /// Whether a sync is currently in progress
  bool get isSyncing => _syncInProgress;
  
  /// Create a SyncService
  SyncService(
    this._syncRepository,
    this._connectivityService,
    this._resourceManager,
  ) {
    _initialize();
  }
  
  /// Initialize the service
  Future<void> _initialize() async {
    // Load last sync time
    _lastSyncTime = await _syncRepository.getLastSyncTimestamp();
    
    // Set initial status
    _updateStatus(_lastSyncTime == null ? SyncStatus.initial : SyncStatus.synced);
    
    // Start periodic sync if enabled
    _setupPeriodicSync();
    
    // Listen for connectivity changes
    _connectivityService.connectionStream.listen(_handleConnectivityChange);
    
    _logger.info('Sync service initialized, last sync: $_lastSyncTime');
  }
  
  /// Set up periodic synchronization
  void _setupPeriodicSync() {
    _syncTimer?.cancel();
    
    // Get the sync interval from resource manager
    final syncIntervalMinutes = _resourceManager.getSyncIntervalMinutes();
    
    // Set up a timer for periodic sync
    _syncTimer = Timer.periodic(
      Duration(minutes: syncIntervalMinutes),
      (timer) => _maybeRunPeriodicSync(),
    );
    
    _logger.info('Periodic sync set up with interval: $syncIntervalMinutes minutes');
  }
  
  /// Run periodic sync if conditions are right
  Future<void> _maybeRunPeriodicSync() async {
    // Don't run if a sync is already in progress
    if (_syncInProgress) {
      _logger.fine('Skipping periodic sync because a sync is already in progress');
      return;
    }
    
    // Check if we have network connectivity
    final networkType = await _connectivityService.getConnectionType();
    if (networkType == NetworkType.none) {
      _logger.fine('Skipping periodic sync because there is no network connectivity');
      return;
    }
    
    // Check resource constraints
    final shouldExecute = _resourceManager.shouldExecuteOperation(OperationType.normal);
    if (!shouldExecute) {
      _logger.fine('Skipping periodic sync due to resource constraints');
      return;
    }
    
    // Check if sync is allowed on current network type
    final profile = _resourceManager.currentProfile;
    if (profile != null) {
      if (profile.syncOnWifiOnly && !networkType.isHighSpeed) {
        _logger.fine('Skipping periodic sync because not on WiFi');
        return;
      }
    }
    
    // All conditions met, run sync
    _logger.fine('Running periodic sync');
    await synchronize();
  }
  
  /// Handle connectivity change
  void _handleConnectivityChange(NetworkType networkType) {
    if (networkType != NetworkType.none) {
      // If we just got connectivity, attempt a sync
      if (_currentStatus == SyncStatus.paused) {
        _logger.info('Connectivity restored, attempting sync');
        
        // Delay sync to ensure connection is stable
        Future.delayed(const Duration(seconds: 5), () {
          if (!_syncInProgress) {
            synchronize();
          }
        });
      }
    } else {
      // If we lost connectivity and a sync is in progress, pause it
      if (_syncInProgress) {
        _logger.info('Lost connectivity, pausing sync');
        _updateStatus(SyncStatus.paused);
      }
    }
  }
  
  /// Run a complete synchronization
  Future<void> synchronize() async {
    if (_syncInProgress) {
      _logger.warning('Sync already in progress, skipping');
      return;
    }
    
    _syncInProgress = true;
    _updateStatus(SyncStatus.syncing);
    
    final stopwatch = Stopwatch()..start();
    final stats = SyncStats.initial();
    
    try {
      // Check connectivity
      final isConnected = await _connectivityService.isConnected();
      if (!isConnected) {
        _logger.warning('No network connectivity, cannot sync');
        _updateStatus(SyncStatus.paused);
        _syncInProgress = false;
        return;
      }
      
      // 1. Push local changes to server
      final localChanges = await _syncRepository.getLocalChanges();
      if (localChanges.hasChanges) {
        _logger.info('Pushing ${localChanges.changeCount} local changes to server');
        await _syncRepository.pushLocalChanges(localChanges);
        
        // Update stats
        //stats = stats.copyWith(...); // Update with actual stats
      }
      
      // 2. Get changes from server
      final lastSync = await _syncRepository.getLastSyncTimestamp();
      final remoteChanges = await _syncRepository.getChangesSince(lastSync ?? DateTime(2000));
      
      if (remoteChanges.hasChanges) {
        _logger.info('Applying ${remoteChanges.changeCount} remote changes');
        await _syncRepository.applyRemoteChanges(remoteChanges);
        
        // Update stats
        //stats = stats.copyWith(...); // Update with actual stats
      }
      
      // 3. Update last sync timestamp
      final now = DateTime.now();
      await _syncRepository.updateLastSyncTimestamp(now);
      _lastSyncTime = now;
      
      // 4. Update sync status
      _updateStatus(SyncStatus.synced);
      
      stopwatch.stop();
      
      // Update and publish stats
      final finalStats = SyncStats(
        filesUploaded: 0, // Replace with actual counts
        filesDownloaded: 0, // Replace with actual counts
        filesDeleted: 0, // Replace with actual counts
        foldersCreated: 0, // Replace with actual counts
        foldersDeleted: 0, // Replace with actual counts
        conflicts: 0, // Replace with actual conflicts
        bytesUploaded: 0, // Replace with actual bytes
        bytesDownloaded: 0, // Replace with actual bytes
        duration: stopwatch.elapsed,
        timestamp: now,
      );
      
      _lastStats = finalStats;
      _statsController.add(finalStats);
      
      _logger.info('Sync completed in ${stopwatch.elapsed.inSeconds}s: ${finalStats.summary}');
    } catch (e) {
      _logger.severe('Sync failed: $e');
      _updateStatus(SyncStatus.failed);
    } finally {
      _syncInProgress = false;
    }
  }
  
  /// Update the sync status
  void _updateStatus(SyncStatus status) {
    if (_currentStatus != status) {
      _currentStatus = status;
      _statusController.add(status);
      _logger.info('Sync status updated: $status');
    }
  }
  
  /// Manually trigger synchronization
  Future<void> syncNow() async {
    if (_syncInProgress) {
      _logger.warning('Sync already in progress, skipping manual sync');
      return;
    }
    
    _logger.info('Manual sync triggered');
    await synchronize();
  }
  
  /// Resolve a sync conflict
  Future<void> resolveConflict({
    required String itemId,
    required ConflictResolution resolution,
  }) async {
    try {
      _logger.info('Resolving conflict for item $itemId with resolution: $resolution');
      await _syncRepository.resolveConflict(
        itemId: itemId,
        resolution: resolution,
      );
    } catch (e) {
      _logger.warning('Failed to resolve conflict: $itemId - $e');
      rethrow;
    }
  }
  
  /// Update the sync interval
  void updateSyncInterval() {
    _setupPeriodicSync();
  }
  
  /// Dispose resources
  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
    _statsController.close();
  }
}