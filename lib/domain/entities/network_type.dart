/// Network connection type
enum NetworkType {
  none,
  mobile,
  wifi,
  ethernet,
  vpn,
  other;
  
  /// Whether this network type is considered high-speed
  bool get isHighSpeed => this == NetworkType.wifi || this == NetworkType.ethernet;
}