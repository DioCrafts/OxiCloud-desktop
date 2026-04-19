class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authStatus = '/auth/status';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String setup = '/auth/setup';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';
  static const String logout = '/auth/logout';

  // OIDC
  static const String oidcProviders = '/auth/oidc/providers';
  static const String oidcAuthorize = '/auth/oidc/authorize';
  static const String oidcCallback = '/auth/oidc/callback';
  static const String oidcExchange = '/auth/oidc/exchange';

  // Folders
  static const String folders = '/folders';
  static String folderById(String id) => '/folders/$id';
  static String folderContents(String id) => '/folders/$id/contents';
  static String folderContentsPaginated(String id) =>
      '/folders/$id/contents/paginated';
  static String folderRename(String id) => '/folders/$id/rename';
  static String folderMove(String id) => '/folders/$id/move';
  static String folderDownload(String id) => '/folders/$id/download';
  static String folderListing(String id) => '/folders/$id/listing';

  // Files
  static const String files = '/files';
  static const String fileUpload = '/files/upload';
  static String fileById(String id) => '/files/$id';
  static String fileThumbnail(String id, String size) =>
      '/files/$id/thumbnail/$size';
  static String fileMetadata(String id) => '/files/$id/metadata';
  static String fileRename(String id) => '/files/$id/rename';
  static String fileMove(String id) => '/files/$id/move';

  // Chunked uploads
  static const String uploads = '/uploads';
  static String uploadById(String id) => '/uploads/$id';
  static String uploadComplete(String id) => '/uploads/$id/complete';

  // Batch
  static const String batchFilesMove = '/batch/files/move';
  static const String batchFilesCopy = '/batch/files/copy';
  static const String batchFilesDelete = '/batch/files/delete';
  static const String batchFilesGet = '/batch/files/get';
  static const String batchFoldersDelete = '/batch/folders/delete';
  static const String batchFoldersCreate = '/batch/folders/create';
  static const String batchFoldersGet = '/batch/folders/get';
  static const String batchFoldersMove = '/batch/folders/move';
  static const String batchTrash = '/batch/trash';
  static const String batchDownload = '/batch/download';

  // Search
  static const String search = '/search';
  static const String searchSuggest = '/search/suggest';
  static const String searchAdvanced = '/search/advanced';
  static const String searchCache = '/search/cache';

  // Shares
  static const String shares = '/shares';
  static String shareById(String id) => '/shares/$id';

  // Public share access (no /api prefix)
  static String publicShareAccess(String token) => '/s/$token';
  static String publicShareVerify(String token) => '/s/$token/verify';
  static String publicShareDownload(String token) => '/s/$token/download';

  // Favorites
  static const String favorites = '/favorites';
  static const String favoritesBatch = '/favorites/batch';
  static String favorite(String itemType, String itemId) =>
      '/favorites/$itemType/$itemId';

  // Recent
  static const String recent = '/recent';
  static const String recentClear = '/recent/clear';
  static String recentItem(String itemType, String itemId) =>
      '/recent/$itemType/$itemId';

  // Photos
  static const String photos = '/photos';

  // Trash
  static const String trash = '/trash';
  static const String trashEmpty = '/trash/empty';
  static String trashFile(String id) => '/trash/files/$id';
  static String trashFolder(String id) => '/trash/folders/$id';
  static String trashRestore(String id) => '/trash/$id/restore';
  static String trashDelete(String id) => '/trash/$id';

  // Dedup
  static String dedupCheck(String hash) => '/dedup/check/$hash';
  static const String dedupUpload = '/dedup/upload';
  static const String dedupStats = '/dedup/stats';
  static String dedupBlob(String hash) => '/dedup/blob/$hash';
  static const String dedupRecalculate = '/dedup/recalculate';

  // Admin
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static String adminUser(String id) => '/admin/users/$id';
  static String adminUserRole(String id) => '/admin/users/$id/role';
  static String adminUserActive(String id) => '/admin/users/$id/active';
  static String adminUserQuota(String id) => '/admin/users/$id/quota';
  static String adminUserPassword(String id) => '/admin/users/$id/password';
  static const String adminRegistration = '/admin/settings/registration';
  static const String adminOidc = '/admin/settings/oidc';
  static const String adminOidcTest = '/admin/settings/oidc/test';
  static const String adminStorage = '/admin/settings/storage';
  static const String adminStorageTest = '/admin/settings/storage/test';
  static const String adminStorageGenerateKey =
      '/admin/settings/storage/generate-key';
  static const String adminMigration = '/admin/storage/migration';
  static const String adminMigrationStart = '/admin/storage/migration/start';
  static const String adminMigrationPause = '/admin/storage/migration/pause';
  static const String adminMigrationResume = '/admin/storage/migration/resume';
  static const String adminMigrationComplete =
      '/admin/storage/migration/complete';
  static const String adminMigrationVerify = '/admin/storage/migration/verify';
  static const String adminAudioReextract = '/admin/audio/metadata/reextract';

  // App Passwords
  static const String appPasswords = '/auth/app-passwords';
  static String appPassword(String id) => '/auth/app-passwords/$id';

  // Device Auth (RFC 8628)
  static const String deviceAuthorize = '/auth/device/authorize';
  static const String deviceToken = '/auth/device/token';
  static const String deviceVerify = '/auth/device/verify';
  static const String deviceDevices = '/auth/device/devices';
  static String deviceRevoke(String id) => '/auth/device/devices/$id';

  // Playlists
  static const String playlists = '/playlists';
  static String playlistById(String id) => '/playlists/$id';
  static String playlistTracks(String id) => '/playlists/$id/tracks';
  static String playlistTrack(String id, String fileId) =>
      '/playlists/$id/tracks/$fileId';
  static String playlistReorder(String id) => '/playlists/$id/reorder';
  static String playlistShare(String id) => '/playlists/$id/share';
  static String playlistShareUser(String id, String userId) =>
      '/playlists/$id/share/$userId';
  static String playlistShares(String id) => '/playlists/$id/shares';
  static String audioMetadata(String fileId) =>
      '/playlists/audio-metadata/$fileId';

  // i18n
  static const String i18nLocales = '/i18n/locales';
  static const String i18nTranslate = '/i18n/translate';
  static String i18nLocale(String code) => '/i18n/locales/$code';

  // Version
  static const String version = '/version';

  // Admin general settings
  static const String adminGeneral = '/admin/settings/general';
}
