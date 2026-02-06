import 'package:equatable/equatable.dart';

/// User entity
class User extends Equatable {
  final String id;
  final String username;
  final String serverUrl;
  final ServerInfo serverInfo;

  const User({
    required this.id,
    required this.username,
    required this.serverUrl,
    required this.serverInfo,
  });

  @override
  List<Object?> get props => [id, username, serverUrl, serverInfo];
}

/// Server information
class ServerInfo extends Equatable {
  final String url;
  final String version;
  final String name;
  final String webdavUrl;
  final int quotaTotal;
  final int quotaUsed;
  final bool supportsDeltaSync;
  final bool supportsChunkedUpload;

  const ServerInfo({
    required this.url,
    required this.version,
    required this.name,
    required this.webdavUrl,
    required this.quotaTotal,
    required this.quotaUsed,
    required this.supportsDeltaSync,
    required this.supportsChunkedUpload,
  });

  /// Available quota in bytes
  int get quotaAvailable => quotaTotal - quotaUsed;

  /// Quota usage percentage
  double get quotaPercent =>
      quotaTotal > 0 ? (quotaUsed / quotaTotal) * 100 : 0;

  /// Format quota for display
  String get quotaFormatted =>
      '${_formatBytes(quotaUsed)} / ${_formatBytes(quotaTotal)}';

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  List<Object?> get props => [
        url,
        version,
        name,
        webdavUrl,
        quotaTotal,
        quotaUsed,
        supportsDeltaSync,
        supportsChunkedUpload,
      ];
}

/// Authentication credentials
class AuthCredentials {
  final String serverUrl;
  final String username;
  final String password;

  const AuthCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  /// Validate credentials
  String? validate() {
    if (serverUrl.isEmpty) return 'Server URL is required';
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      return 'Server URL must start with http:// or https://';
    }
    if (username.isEmpty) return 'Username is required';
    if (password.isEmpty) return 'Password is required';
    return null;
  }
}
