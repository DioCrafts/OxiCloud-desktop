class Constants {
  Constants._();

  static const String appName = 'OxiCloud';
  static const String appVersion = '0.1.0';

  // Cache
  static const int fileCacheMaxMB = 512;
  static const int thumbnailCacheMaxItems = 5000;

  // Sync
  static const int syncQueueMaxRetries = 5;
  static const Duration syncRetryBaseDelay = Duration(seconds: 2);
  static const Duration syncPollInterval = Duration(seconds: 30);

  // Upload
  static const int defaultChunkSize = 5 * 1024 * 1024; // 5 MB
  static const int chunkedUploadThreshold = 10 * 1024 * 1024; // 10 MB

  // Pagination
  static const int defaultPageSize = 50;
  static const int searchPageSize = 30;

  // UI
  static const double desktopSidebarWidth = 240.0;
  static const double desktopMinWidth = 800.0;
  static const double desktopDetailPanelWidth = 320.0;
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;

  // Secure storage keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyServerUrl = 'server_url';
  static const String keyUserId = 'user_id';
  static const String keyTokenExpiry = 'token_expiry';
}
