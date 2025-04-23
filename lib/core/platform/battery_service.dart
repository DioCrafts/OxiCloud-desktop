import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';

/// Battery information data class
class BatteryInfo {
  /// Battery level in percent (0-100)
  final int level;
  
  /// Whether the device is currently charging
  final bool isCharging;
  
  const BatteryInfo({
    required this.level,
    required this.isCharging,
  });
  
  @override
  String toString() => 'BatteryInfo(level: $level%, isCharging: $isCharging)';
}

/// Service for monitoring battery status
class BatteryService {
  final Battery _battery = Battery();
  final Logger _logger = LoggingManager.getLogger('BatteryService');
  
  /// Controller for battery level events
  final StreamController<BatteryInfo> _batteryController = StreamController<BatteryInfo>.broadcast();
  
  /// Stream of battery information updates
  Stream<BatteryInfo> get batteryStream => _batteryController.stream;
  
  BatteryInfo? _lastKnownInfo;
  StreamSubscription? _batteryLevelSubscription;
  StreamSubscription? _batteryStateSubscription;
  
  /// The last known battery info
  BatteryInfo? get lastKnownInfo => _lastKnownInfo;
  
  /// Initialize the battery service
  BatteryService() {
    _initialize();
  }
  
  void _initialize() async {
    // Get initial battery information
    _updateBatteryInfo();
    
    // Listen for battery level changes
    _batteryLevelSubscription = _battery.onBatteryStateChanged.listen((_) {
      _updateBatteryInfo();
    });
    
    _logger.info('Battery service initialized');
  }
  
  /// Update battery information
  Future<void> _updateBatteryInfo() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;
      
      final isCharging = batteryState == BatteryState.charging || 
                        batteryState == BatteryState.full;
      
      final batteryInfo = BatteryInfo(
        level: batteryLevel,
        isCharging: isCharging,
      );
      
      // Only notify if the information has changed
      if (_lastKnownInfo?.level != batteryInfo.level || 
          _lastKnownInfo?.isCharging != batteryInfo.isCharging) {
        _lastKnownInfo = batteryInfo;
        _batteryController.add(batteryInfo);
        _logger.fine('Battery info updated: $batteryInfo');
      }
    } catch (e) {
      _logger.warning('Failed to update battery info: $e');
    }
  }
  
  /// Get the current battery level (0-100)
  Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      _logger.warning('Failed to get battery level: $e');
      return 100; // Assume full battery if can't determine
    }
  }
  
  /// Check if the device is currently charging
  Future<bool> isCharging() async {
    try {
      final state = await _battery.batteryState;
      return state == BatteryState.charging || state == BatteryState.full;
    } catch (e) {
      _logger.warning('Failed to check if charging: $e');
      return false; // Assume not charging if can't determine
    }
  }
  
  /// Check if battery is in low state (below 20%)
  Future<bool> isLowBattery() async {
    final level = await getBatteryLevel();
    return level < 20;
  }
  
  /// Check if battery is in critical state (below 10%)
  Future<bool> isCriticalBattery() async {
    final level = await getBatteryLevel();
    return level < 10;
  }
  
  /// Get current battery information
  Future<BatteryInfo> getBatteryInfo() async {
    final level = await getBatteryLevel();
    final charging = await isCharging();
    
    return BatteryInfo(
      level: level,
      isCharging: charging,
    );
  }
  
  /// Dispose resources
  void dispose() {
    _batteryLevelSubscription?.cancel();
    _batteryStateSubscription?.cancel();
    _batteryController.close();
  }
}