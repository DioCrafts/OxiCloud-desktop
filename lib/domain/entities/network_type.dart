/// Network connection type for app usage
/// 
/// This is used to represent the network connection throughout the app
/// and should not be confused with the NetworkType from workmanager
enum AppNetworkType {
  none,
  mobile,
  wifi,
  ethernet,
  vpn,
  other;
  
  /// Whether this network type is considered high-speed
  bool get isHighSpeed => this == AppNetworkType.wifi || this == AppNetworkType.ethernet;
}