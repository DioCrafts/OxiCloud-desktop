import 'dart:async';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/core/network/network_info.dart';
import 'package:oxicloud_desktop/core/platform/battery_service.dart';
import 'package:oxicloud_desktop/core/platform/device_info_service.dart';

/// Different usage modes that adjust resource consumption
enum UsageMode {
  /// Optimized for performance, using more resources
  performance,
  
  /// Balanced usage of resources
  normal,
  
  /// Optimized for saving data usage
  dataSave,
  
  /// Optimized for saving power
  powerSave,
  
  /// Minimal resource usage for background operation
  minimal,
  
  /// Critical battery mode, minimal functionality
  critical,
}

/// Resource profile that defines resource usage limits
class ResourceProfile {
  /// Device classification (low, medium, high)
  final DeviceClass deviceClass;
  
  /// Current network type
  final NetworkType networkType;
  
  /// Current battery level (0-100)
  final int batteryLevel;
  
  /// Whether the device is currently charging
  final bool isCharging;
  
  /// Current application state (foreground, background)
  final bool isInForeground;
  
  /// Current usage mode
  final UsageMode usageMode;
  
  /// Maximum cache size in bytes
  final int maxCacheSize;
  
  /// Maximum concurrent operations
  final int maxConcurrentOperations;
  
  /// Preload depth for folder contents
  final int preloadDepth;
  
  /// Synchronization interval in minutes
  final int syncIntervalMinutes;
  
  /// Whether to use thumbnails
  final bool useThumbnails;
  
  /// Whether to download files automatically
  final bool autoDownload;
  
  /// Whether to use compression
  final bool useCompression;
  
  /// Whether to use delta sync
  final bool useDeltaSync;
  
  /// Whether background sync is enabled
  final bool enableBackgroundSync;
  
  /// Whether syncing should only happen on WiFi
  final bool syncOnWifiOnly;
  
  const ResourceProfile({
    required this.deviceClass,
    required this.networkType,
    required this.batteryLevel,
    required this.isCharging,
    required this.isInForeground,
    required this.usageMode,
    required this.maxCacheSize,
    required this.maxConcurrentOperations,
    required this.preloadDepth,
    required this.syncIntervalMinutes,
    required this.useThumbnails,
    required this.autoDownload,
    required this.useCompression,
    required this.useDeltaSync,
    this.enableBackgroundSync = true,
    this.syncOnWifiOnly = true,
  });
  
  @override
  String toString() => 'ResourceProfile('
      'deviceClass: $deviceClass, '
      'networkType: $networkType, '
      'batteryLevel: $batteryLevel, '
      'isCharging: $isCharging, '
      'isInForeground: $isInForeground, '
      'usageMode: $usageMode, '
      'maxCacheSize: ${(maxCacheSize / (1024 * 1024)).toStringAsFixed(2)} MB, '
      'maxConcurrentOperations: $maxConcurrentOperations, '
      'preloadDepth: $preloadDepth, '
      'syncIntervalMinutes: $syncIntervalMinutes, '
      'useThumbnails: $useThumbnails, '
      'autoDownload: $autoDownload, '
      'useCompression: $useCompression, '
      'useDeltaSync: $useDeltaSync)';
}

/// Manages resource allocation and optimization based on device state
class ResourceManager {
  final DeviceInfoService _deviceInfoService;
  final ConnectivityService _connectivityService;
  final BatteryService _batteryService;
  final Logger _logger = LoggingManager.getLogger('ResourceManager');
  
  final StreamController<ResourceProfile> _profileController = 
      StreamController<ResourceProfile>.broadcast();
  
  ResourceProfile? _currentProfile;
  
  /// Stream of resource profile updates
  Stream<ResourceProfile> get profileStream => _profileController.stream;
  
  /// The current resource profile
  ResourceProfile? get currentProfile => _currentProfile;
  
  /// Create a ResourceManager
  ResourceManager(
    this._deviceInfoService,
    this._connectivityService,
    this._batteryService,
  ) {
    _initialize();
  }
  
  /// Initialize the resource manager
  void _initialize() async {
    // Generate initial profile
    await _updateResourceProfile(
      isInForeground: true,
    );
    
    // Listen for connectivity changes
    _connectivityService.connectionStream.listen((networkType) {
      _updateResourceProfile(
        networkType: networkType,
      );
    });
    
    // Listen for battery changes
    _batteryService.batteryStream.listen((batteryInfo) {
      _updateResourceProfile(
        batteryLevel: batteryInfo.level,
        isCharging: batteryInfo.isCharging,
      );
    });
    
    _logger.info('Resource manager initialized');
  }
  
  /// Update the resource profile
  Future<void> _updateResourceProfile({
    NetworkType? networkType,
    int? batteryLevel,
    bool? isCharging,
    bool? isInForeground,
  }) async {
    // Get current values for parameters that weren't specified
    if (_currentProfile == null) {
      // Initialize with default values
      networkType ??= await _connectivityService.getConnectionType();
      final batteryInfo = await _batteryService.getBatteryInfo();
      batteryLevel ??= batteryInfo.level;
      isCharging ??= batteryInfo.isCharging;
      isInForeground ??= true;
    } else {
      // Use current values for unspecified parameters
      networkType ??= _currentProfile!.networkType;
      batteryLevel ??= _currentProfile!.batteryLevel;
      isCharging ??= _currentProfile!.isCharging;
      isInForeground ??= _currentProfile!.isInForeground;
    }
    
    // Get device capability information
    final deviceCapability = await _deviceInfoService.getDeviceCapability();
    
    // Determine usage mode
    final usageMode = _determineUsageMode(
      networkType, 
      batteryLevel!, 
      isCharging!, 
      isInForeground!,
    );
    
    // Create resource profile
    _currentProfile = ResourceProfile(
      deviceClass: deviceCapability.deviceClass,
      networkType: networkType,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      isInForeground: isInForeground,
      usageMode: usageMode,
      maxCacheSize: _calculateMaxCacheSize(deviceCapability.deviceClass, usageMode),
      maxConcurrentOperations: _calculateMaxConcurrentOperations(deviceCapability.cpuCores, usageMode),
      preloadDepth: _calculatePreloadDepth(usageMode, networkType),
      syncIntervalMinutes: _calculateSyncInterval(usageMode, networkType),
      useThumbnails: _shouldUseThumbnails(usageMode, networkType),
      autoDownload: _shouldAutoDownload(usageMode, networkType),
      useCompression: _shouldUseCompression(usageMode, networkType),
      useDeltaSync: _shouldUseDeltaSync(usageMode),
      enableBackgroundSync: usageMode != UsageMode.critical && usageMode != UsageMode.minimal,
      syncOnWifiOnly: usageMode == UsageMode.dataSave || networkType.isMetered,
    );
    
    // Notify listeners
    _profileController.add(_currentProfile!);
    _logger.info('Resource profile updated: $_currentProfile');
  }
  
  /// Determine usage mode based on device state
  UsageMode _determineUsageMode(
    NetworkType networkType,
    int batteryLevel,
    bool isCharging,
    bool isInForeground,
  ) {
    // App in background: conserve resources
    if (!isInForeground) {
      return UsageMode.minimal;
    }
    
    // Charging: can use more resources
    if (isCharging) {
      if (networkType.isHighSpeed) {
        return UsageMode.performance;
      }
      return UsageMode.normal;
    }
    
    // Critical battery: extreme conservation
    if (batteryLevel < 10) {
      return UsageMode.critical;
    }
    
    // Low battery: conserve power
    if (batteryLevel < 20) {
      return UsageMode.powerSave;
    }
    
    // Metered connection: conserve data
    if (networkType.isMetered) {
      return UsageMode.dataSave;
    }
    
    // Default: balanced usage
    return UsageMode.normal;
  }
  
  /// Calculate maximum cache size based on device class and usage mode
  int _calculateMaxCacheSize(DeviceClass deviceClass, UsageMode usageMode) {
    // Base cache size depends on device class
    int baseCacheSizeMB;
    switch (deviceClass) {
      case DeviceClass.high:
        baseCacheSizeMB = 200;
        break;
      case DeviceClass.medium:
        baseCacheSizeMB = 100;
        break;
      case DeviceClass.low:
        baseCacheSizeMB = 50;
        break;
    }
    
    // Adjust based on usage mode
    double multiplier;
    switch (usageMode) {
      case UsageMode.performance:
        multiplier = 1.0;
        break;
      case UsageMode.normal:
        multiplier = 0.8;
        break;
      case UsageMode.dataSave:
        multiplier = 0.6;
        break;
      case UsageMode.powerSave:
        multiplier = 0.4;
        break;
      case UsageMode.minimal:
        multiplier = 0.2;
        break;
      case UsageMode.critical:
        multiplier = 0.1;
        break;
    }
    
    return (baseCacheSizeMB * multiplier * 1024 * 1024).toInt();
  }
  
  /// Calculate maximum concurrent operations
  int _calculateMaxConcurrentOperations(int cpuCores, UsageMode usageMode) {
    switch (usageMode) {
      case UsageMode.performance:
        return cpuCores ~/ 2;
      case UsageMode.normal:
        return (cpuCores ~/ 2).clamp(1, 3);
      case UsageMode.dataSave:
      case UsageMode.powerSave:
        return 2.clamp(1, 2);
      case UsageMode.minimal:
      case UsageMode.critical:
        return 1;
    }
  }
  
  /// Calculate preload depth
  int _calculatePreloadDepth(UsageMode usageMode, NetworkType networkType) {
    if (usageMode == UsageMode.critical || usageMode == UsageMode.minimal) {
      return 0;
    }
    
    if (usageMode == UsageMode.powerSave || usageMode == UsageMode.dataSave) {
      return 0;
    }
    
    if (usageMode == UsageMode.performance && networkType.isHighSpeed) {
      return 2;
    }
    
    return 1;
  }
  
  /// Calculate sync interval in minutes
  int _calculateSyncInterval(UsageMode usageMode, NetworkType networkType) {
    // No connection: very long interval
    if (networkType == NetworkType.none) {
      return 60;
    }
    
    switch (usageMode) {
      case UsageMode.performance:
        return networkType.isHighSpeed ? 15 : 30;
      case UsageMode.normal:
        return networkType.isHighSpeed ? 30 : 45;
      case UsageMode.dataSave:
        return 60;
      case UsageMode.powerSave:
        return 90;
      case UsageMode.minimal:
        return 120;
      case UsageMode.critical:
        return 240;
    }
  }
  
  /// Determine if thumbnails should be used
  bool _shouldUseThumbnails(UsageMode usageMode, NetworkType networkType) {
    if (usageMode == UsageMode.critical) {
      return false;
    }
    
    if (usageMode == UsageMode.dataSave && networkType.isMetered) {
      return false;
    }
    
    return true;
  }
  
  /// Determine if files should be downloaded automatically
  bool _shouldAutoDownload(UsageMode usageMode, NetworkType networkType) {
    if (usageMode == UsageMode.critical || usageMode == UsageMode.minimal) {
      return false;
    }
    
    if (usageMode == UsageMode.dataSave && networkType.isMetered) {
      return false;
    }
    
    return true;
  }
  
  /// Determine if compression should be used
  bool _shouldUseCompression(UsageMode usageMode, NetworkType networkType) {
    // Always use compression on metered connections
    if (networkType.isMetered) {
      return true;
    }
    
    // Don't use compression in performance mode on high-speed connections
    if (usageMode == UsageMode.performance && networkType.isHighSpeed) {
      return false;
    }
    
    return true;
  }
  
  /// Determine if delta sync should be used
  bool _shouldUseDeltaSync(UsageMode usageMode) {
    // Always use delta sync except in performance mode
    return usageMode != UsageMode.performance;
  }
  
  /// Notify the resource manager of app state changes
  void setAppForegroundState(bool isInForeground) {
    _updateResourceProfile(isInForeground: isInForeground);
  }
  
  /// Get recommended cache size in bytes
  int getRecommendedCacheSize() {
    return _currentProfile?.maxCacheSize ?? 50 * 1024 * 1024;
  }
  
  /// Get sync interval in minutes
  int getSyncIntervalMinutes() {
    return _currentProfile?.syncIntervalMinutes ?? 30;
  }
  
  /// Check if operations should be executed in the current state
  bool shouldExecuteOperation(OperationType operationType) {
    if (_currentProfile == null) {
      return false;
    }
    
    // Critical battery: only allow essential operations
    if (_currentProfile!.usageMode == UsageMode.critical) {
      return operationType == OperationType.critical;
    }
    
    // Minimal mode: allow essential and high priority operations
    if (_currentProfile!.usageMode == UsageMode.minimal) {
      return operationType == OperationType.critical || 
             operationType == OperationType.highPriority;
    }
    
    // Power save: prevent background operations
    if (_currentProfile!.usageMode == UsageMode.powerSave) {
      return operationType != OperationType.background;
    }
    
    // Data save on metered connection: prevent background operations
    if (_currentProfile!.usageMode == UsageMode.dataSave && 
        _currentProfile!.networkType.isMetered) {
      return operationType != OperationType.background;
    }
    
    // All other cases: allow operation
    return true;
  }
  
  /// Dispose resources
  void dispose() {
    _profileController.close();
  }
}

/// Types of operations for resource prioritization
enum OperationType {
  /// Critical operations that must be executed (authentication, etc.)
  critical,
  
  /// High priority operations (user-initiated actions)
  highPriority,
  
  /// Normal operations (regular sync, etc.)
  normal,
  
  /// Low priority operations (prefetching, etc.)
  lowPriority,
  
  /// Background operations (cleanup, maintenance, etc.)
  background,
}