import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/core/network/network_info.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Logger _logger = LoggingManager.getLogger('ConnectivityService');
  
  StreamController<NetworkType> _connectionController = StreamController<NetworkType>.broadcast();
  StreamSubscription? _connectivitySubscription;
  
  NetworkType _lastKnownNetworkType = NetworkType.unknown;
  
  /// Stream of network connection changes
  Stream<NetworkType> get connectionStream => _connectionController.stream;
  
  /// The current network type
  NetworkType get currentNetworkType => _lastKnownNetworkType;
  
  /// Initialize the connectivity service
  ConnectivityService() {
    _initialize();
  }
  
  void _initialize() {
    // Get initial connectivity state
    _connectivity.checkConnectivity().then(_updateConnectionStatus);
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    
    _logger.info('Connectivity service initialized');
  }
  
  /// Update connection status when it changes
  void _updateConnectionStatus(ConnectivityResult result) {
    final previousType = _lastKnownNetworkType;
    
    switch (result) {
      case ConnectivityResult.wifi:
        _lastKnownNetworkType = NetworkType.wifi;
        break;
      case ConnectivityResult.mobile:
        _lastKnownNetworkType = NetworkType.mobile;
        break;
      case ConnectivityResult.ethernet:
        _lastKnownNetworkType = NetworkType.ethernet;
        break;
      case ConnectivityResult.bluetooth:
        _lastKnownNetworkType = NetworkType.other;
        break;
      case ConnectivityResult.vpn:
        // Don't change the type based on VPN as it's an overlay connection
        break;
      case ConnectivityResult.none:
        _lastKnownNetworkType = NetworkType.none;
        break;
      default:
        _lastKnownNetworkType = NetworkType.unknown;
    }
    
    // Only notify if the type has changed
    if (previousType != _lastKnownNetworkType) {
      _logger.info('Network connectivity changed: $previousType -> $_lastKnownNetworkType');
      _connectionController.add(_lastKnownNetworkType);
    }
  }
  
  /// Check if device is currently connected to any network
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
  
  /// Check if device is currently connected to WiFi
  Future<bool> isWifiConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.wifi || result == ConnectivityResult.ethernet;
  }
  
  /// Get the current connection type
  Future<NetworkType> getConnectionType() async {
    final result = await _connectivity.checkConnectivity();
    
    switch (result) {
      case ConnectivityResult.wifi:
        return NetworkType.wifi;
      case ConnectivityResult.mobile:
        return NetworkType.mobile;
      case ConnectivityResult.ethernet:
        return NetworkType.ethernet;
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.vpn:
        return NetworkType.other;
      case ConnectivityResult.none:
        return NetworkType.none;
      default:
        return NetworkType.unknown;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectionController.close();
  }
}