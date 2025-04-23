import 'package:oxicloud_desktop/domain/entities/network_type.dart';

/// Represents the type of network connection
/// @deprecated Use AppNetworkType from domain/entities/network_type.dart instead
enum NetworkType {
  /// No network connection
  none,
  
  /// Mobile data connection (3G, 4G, 5G, etc.)
  mobile,
  
  /// WiFi connection
  wifi,
  
  /// Ethernet connection (typically desktop only)
  ethernet,
  
  /// Other connection types (Bluetooth, etc.)
  other,
  
  /// Unknown connection type
  unknown,
}

/// Extension methods for NetworkType
extension NetworkTypeExtension on NetworkType {
  /// Returns true if the connection is considered high-speed
  bool get isHighSpeed {
    return this == NetworkType.wifi || this == NetworkType.ethernet;
  }
  
  /// Returns true if the connection is considered metered
  bool get isMetered {
    return this == NetworkType.mobile;
  }
  
  /// Returns true if the connection exists
  bool get isConnected {
    return this != NetworkType.none && this != NetworkType.unknown;
  }
  
  /// Returns the string representation of the network type
  String get displayName {
    switch (this) {
      case NetworkType.none:
        return 'Not Connected';
      case NetworkType.mobile:
        return 'Mobile Data';
      case NetworkType.wifi:
        return 'WiFi';
      case NetworkType.ethernet:
        return 'Ethernet';
      case NetworkType.other:
        return 'Other Connection';
      case NetworkType.unknown:
        return 'Unknown Connection';
    }
  }
  
  /// Convert to AppNetworkType
  AppNetworkType toAppNetworkType() {
    switch (this) {
      case NetworkType.none:
        return AppNetworkType.none;
      case NetworkType.mobile:
        return AppNetworkType.mobile;
      case NetworkType.wifi:
        return AppNetworkType.wifi;
      case NetworkType.ethernet:
        return AppNetworkType.ethernet;
      case NetworkType.other:
        return AppNetworkType.other;
      case NetworkType.unknown:
        return AppNetworkType.other;
    }
  }
}

/// Extension methods for AppNetworkType
extension AppNetworkTypeExtension on AppNetworkType {
  /// Convert to NetworkType
  NetworkType toNetworkType() {
    switch (this) {
      case AppNetworkType.none:
        return NetworkType.none;
      case AppNetworkType.mobile:
        return NetworkType.mobile;
      case AppNetworkType.wifi:
        return NetworkType.wifi;
      case AppNetworkType.ethernet:
        return NetworkType.ethernet;
      case AppNetworkType.vpn:
        return NetworkType.other;
      case AppNetworkType.other:
        return NetworkType.other;
    }
  }
  
  /// Returns true if the connection is considered metered
  bool get isMetered {
    return this == AppNetworkType.mobile;
  }
  
  /// Returns true if the connection exists
  bool get isConnected {
    return this != AppNetworkType.none;
  }
  
  /// Returns the string representation of the network type
  String get displayName {
    switch (this) {
      case AppNetworkType.none:
        return 'Not Connected';
      case AppNetworkType.mobile:
        return 'Mobile Data';
      case AppNetworkType.wifi:
        return 'WiFi';
      case AppNetworkType.ethernet:
        return 'Ethernet';
      case AppNetworkType.vpn:
        return 'VPN';
      case AppNetworkType.other:
        return 'Other Connection';
    }
  }
}