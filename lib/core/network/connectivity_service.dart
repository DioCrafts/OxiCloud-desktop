import 'dart:async';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/network_info.dart';

/// Stub service for monitoring network connectivity without connectivity_plus
/// This version just assumes we have a WiFi connection
class ConnectivityService {
  final Logger _logger = LoggingManager.getLogger('ConnectivityService');
  
  final StreamController<NetworkType> _connectionController = StreamController<NetworkType>.broadcast();
  
  NetworkType _lastKnownNetworkType = NetworkType.wifi; // Always assume WiFi
  
  /// Stream of network connection changes
  Stream<NetworkType> get connectionStream => _connectionController.stream;
  
  /// The current network type
  NetworkType get currentNetworkType => _lastKnownNetworkType;
  
  /// Initialize the connectivity service
  ConnectivityService() {
    _initialize();
  }
  
  void _initialize() {
    // Simulate a WiFi connection in this stub implementation
    _connectionController.add(_lastKnownNetworkType);
    _logger.info('Stub connectivity service initialized, assuming WiFi connection');
  }
  
  /// Check if device is currently connected to any network
  Future<bool> isConnected() async {
    return true; // Always assume connected
  }
  
  /// Check if device is currently connected to WiFi
  Future<bool> isWifiConnected() async {
    return true; // Always assume WiFi
  }
  
  /// Get the current connection type
  Future<NetworkType> getConnectionType() async {
    return NetworkType.wifi; // Always return WiFi
  }
  
  /// Dispose resources
  void dispose() {
    _connectionController.close();
  }
}