/// Application-wide constants.
///
/// Centralizes magic values scattered across the codebase.
class AppConstants {
  const AppConstants._();

  // ── App metadata ──────────────────────────────────────────────────────────
  static const String appName = 'OxiCloud Desktop';
  static const String appVersion = '0.1.0';

  // ── Sync defaults ─────────────────────────────────────────────────────────
  static const int defaultSyncIntervalSeconds = 300;
  static const int defaultMaxUploadKbps = 0; // 0 = unlimited
  static const int defaultMaxDownloadKbps = 0;
  static const int deltaSyncMinSizeBytes = 1048576; // 1 MB

  // ── Storage keys (SharedPreferences) ──────────────────────────────────────
  static const String keyServerUrl = 'server_url';
  static const String keyUsername = 'username';

  // ── UI ────────────────────────────────────────────────────────────────────
  static const double windowMinWidth = 900;
  static const double windowMinHeight = 600;
  static const double sidebarWidth = 220;
}
