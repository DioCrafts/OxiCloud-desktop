/// Represents the type of network connection
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
}