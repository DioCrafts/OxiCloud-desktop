import 'dart:async';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/application/services/sync_service.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/core/platform/battery_service.dart';
import 'package:oxicloud_desktop/domain/entities/network_type.dart';
import 'package:oxicloud_desktop/domain/entities/sync_conditions.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';
import 'package:workmanager/workmanager.dart' hide NetworkType;
import 'package:workmanager/workmanager.dart' as wm show NetworkType;
import 'package:flutter/foundation.dart';

/// Background service for synchronization
class BackgroundSyncService {
  /// Task name for background sync
  static const String _syncTaskName = 'backgroundSync';
  
  /// Key for storing background sync enabled state
  static const String _backgroundSyncEnabledKey = 'background_sync_enabled';
  
  final Logger _logger = LoggingManager.getLogger('BackgroundSyncService');
  final SyncService _syncService;
  final ResourceManager _resourceManager;
  final ConnectivityService _connectivityService;
  final BatteryService _batteryService;
  
  /// Timer for foreground sync
  Timer? _foregroundSyncTimer;
  
  /// Create a BackgroundSyncService
  BackgroundSyncService(
    this._syncService,
    this._resourceManager,
    this._connectivityService,
    this._batteryService,
  );
  
  /// Initialize the background sync service
  Future<void> initialize() async {
    if (kIsWeb) {
      _logger.info('Background sync not supported on web');
      return;
    }
    
    try {
      // Initialize Workmanager for background tasks
      await Workmanager().initialize(
        backgroundTaskCallback,
        isInDebugMode: kDebugMode,
      );
      
      // Set up foreground sync timer
      _setupForegroundSync();
      
      // Listen for connectivity changes
      _connectivityService.connectionStream.listen(_handleConnectivityChange);
      
      _logger.info('Background sync service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize background sync service: $e');
    }
  }
  
  /// Set up foreground sync timer
  void _setupForegroundSync() {
    // Cancel existing timer
    _foregroundSyncTimer?.cancel();
    
    // Get sync interval from resource manager
    final syncIntervalMinutes = _resourceManager.getSyncIntervalMinutes();
    
    // Create new timer
    _foregroundSyncTimer = Timer.periodic(
      Duration(minutes: syncIntervalMinutes),
      (_) => _performForegroundSync(),
    );
    
    _logger.info('Foreground sync set up with interval: $syncIntervalMinutes minutes');
  }
  
  /// Handle connectivity change
  void _handleConnectivityChange(AppNetworkType networkType) {
    if (networkType != AppNetworkType.none) {
      // We have connectivity, maybe trigger a sync
      _logger.info('Connectivity changed to $networkType, checking if sync needed');
      _checkAndSyncIfNeeded();
    }
  }
  
  /// Check if sync is needed and perform it
  Future<void> _checkAndSyncIfNeeded() async {
    // If already syncing, don't start another sync
    if (_syncService.isSyncing) {
      return;
    }
    
    // Check if background sync is enabled
    final bgSyncEnabled = await isBackgroundSyncEnabled();
    if (!bgSyncEnabled) {
      return;
    }
    
    // Check if we have connectivity
    final isConnected = await _connectivityService.isConnected();
    if (!isConnected) {
      return;
    }
    
    // Check if we should sync based on resource constraints
    final shouldSync = _resourceManager.shouldExecuteOperation(OperationType.normal);
    if (!shouldSync) {
      return;
    }
    
    // Check sync conditions
    final syncConditions = await _checkSyncConditions();
    if (!syncConditions.canSync) {
      _logger.fine('Sync skipped due to conditions: ${syncConditions.reason}');
      return;
    }
    
    // All conditions met, perform sync
    try {
      await _syncService.synchronize();
    } catch (e) {
      _logger.warning('Background sync failed: $e');
    }
  }
  
  /// Perform foreground sync
  Future<void> _performForegroundSync() async {
    _logger.fine('Performing foreground sync check');
    await _checkAndSyncIfNeeded();
  }
  
  /// Schedule background sync
  Future<void> scheduleBackgroundSync() async {
    if (kIsWeb) {
      _logger.info('Background sync not supported on web');
      return;
    }
    
    try {
      // Check if background sync is enabled
      final isEnabled = await isBackgroundSyncEnabled();
      if (!isEnabled) {
        return;
      }
      
      // Get sync interval
      final syncIntervalMinutes = _resourceManager.getSyncIntervalMinutes();
      
      // Schedule periodic task
      await Workmanager().registerPeriodicTask(
        _syncTaskName,
        _syncTaskName,
        frequency: Duration(minutes: syncIntervalMinutes),
        constraints: Constraints(
          networkType: wm.NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
      );
      
      _logger.info('Background sync scheduled with interval: $syncIntervalMinutes minutes');
    } catch (e) {
      _logger.warning('Failed to schedule background sync: $e');
    }
  }
  
  /// Cancel background sync
  Future<void> cancelBackgroundSync() async {
    if (kIsWeb) {
      return;
    }
    
    try {
      await Workmanager().cancelByUniqueName(_syncTaskName);
      _logger.info('Background sync canceled');
    } catch (e) {
      _logger.warning('Failed to cancel background sync: $e');
    }
  }
  
  /// Check if background sync is enabled
  Future<bool> isBackgroundSyncEnabled() async {
    // Check if background sync is enabled in settings
    final currentProfile = _resourceManager.currentProfile;
    return currentProfile?.enableBackgroundSync ?? false;
  }
  
  /// Enable or disable background sync
  Future<void> setBackgroundSyncEnabled(bool enabled) async {
    if (kIsWeb) {
      return;
    }
    
    try {
      if (enabled) {
        await scheduleBackgroundSync();
      } else {
        await cancelBackgroundSync();
      }
      
      _logger.info('Background sync ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      _logger.warning('Failed to ${enabled ? 'enable' : 'disable'} background sync: $e');
    }
  }
  
  /// Update sync interval
  Future<void> updateSyncInterval() async {
    _logger.info('Updating sync interval');
    
    // Update foreground sync
    _setupForegroundSync();
    
    // Update background sync
    await scheduleBackgroundSync();
    
    // Update sync service
    _syncService.updateSyncInterval();
  }
  
  /// Check if sync conditions are met
  Future<SyncConditions> _checkSyncConditions() async {
    // Check if device is charging
    final isCharging = await _batteryService.isCharging();
    
    // Check battery level
    final batteryLevel = await _batteryService.getBatteryLevel();
    
    // Check network type
    final networkType = await _connectivityService.getConnectionType();
    
    // Get resource profile
    final profile = _resourceManager.currentProfile;
    
    // If profile is null, we can't determine sync conditions
    if (profile == null) {
      return SyncConditions(
        canSync: false,
        reason: 'No resource profile available',
      );
    }
    
    // Check if sync should only happen on WiFi
    if (profile.syncOnWifiOnly && !networkType.toAppNetworkType().isHighSpeed) {
      return SyncConditions(
        canSync: false,
        reason: 'Sync only allowed on WiFi',
      );
    }
    
    // Check if battery is critically low
    if (batteryLevel < 10 && !isCharging) {
      return SyncConditions(
        canSync: false,
        reason: 'Battery level too low',
      );
    }
    
    // All conditions met
    return SyncConditions(
      canSync: true,
    );
  }
  
  /// Perform a manual sync
  Future<void> syncNow() async {
    await _syncService.syncNow();
  }
  
  /// Dispose resources
  void dispose() {
    _foregroundSyncTimer?.cancel();
  }
}

/// Background task callback for Workmanager
@pragma('vm:entry-point')
void backgroundTaskCallback() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == 'backgroundSync') {
      // Initialize necessary services
      await _initializeForBackground();
      
      // Get service instances
      final syncService = _getSyncService();
      
      // Perform sync
      try {
        await syncService.synchronize();
        return true;
      } catch (e) {
        print('Background sync failed: $e');
        return false;
      }
    }
    
    return false;
  });
}

/// Initialize services for background execution
Future<void> _initializeForBackground() async {
  // Initialize logging
  await LoggingManager.initialize();
  
  // Initialize other services
  // This is a simplified implementation
  // In a real implementation, you would initialize all necessary services
}

/// Get sync service instance for background execution
SyncService _getSyncService() {
  // This is a simplified implementation
  // In a real implementation, you would get the instance from a DI container
  throw UnimplementedError('SyncService not available in background');
}