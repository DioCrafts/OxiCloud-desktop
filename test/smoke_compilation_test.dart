// Smoke test: importing every major module forces Dart compilation of ALL code.
// If this test compiles and runs, the entire codebase is valid.

import 'package:flutter_test/flutter_test.dart';

// Core
import 'package:oxicloud/core/network/api_endpoints.dart';
import 'package:oxicloud/core/auth/secure_storage.dart';
import 'package:oxicloud/core/config/app_config.dart';
import 'package:oxicloud/core/network/api_client.dart';

// Datasources
import 'package:oxicloud/data/datasources/remote/auth_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/file_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/folder_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/trash_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/favorites_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/recent_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/search_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/share_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/photos_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/chunked_upload_datasource.dart';
import 'package:oxicloud/data/datasources/remote/batch_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/oidc_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/dedup_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/playlist_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/admin_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/app_password_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/device_auth_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/i18n_remote_datasource.dart';
import 'package:oxicloud/data/datasources/remote/public_share_remote_datasource.dart';

// Providers
import 'package:oxicloud/providers.dart';

// Pages
import 'package:oxicloud/presentation/features/auth/connect_page.dart';
import 'package:oxicloud/presentation/features/auth/login_page.dart';
import 'package:oxicloud/presentation/features/auth/setup_page.dart';
import 'package:oxicloud/presentation/features/auth/device_login_page.dart';
import 'package:oxicloud/presentation/features/file_browser/file_browser_page.dart';
import 'package:oxicloud/presentation/features/favorites/favorites_page.dart';
import 'package:oxicloud/presentation/features/recent/recent_page.dart';
import 'package:oxicloud/presentation/features/photos/photos_page.dart';
import 'package:oxicloud/presentation/features/trash/trash_page.dart';
import 'package:oxicloud/presentation/features/search/search_page.dart';
import 'package:oxicloud/presentation/features/shares/shares_page.dart';
import 'package:oxicloud/presentation/features/playlists/playlists_page.dart';
import 'package:oxicloud/presentation/features/admin/admin_page.dart';
import 'package:oxicloud/presentation/features/settings/settings_page.dart';
import 'package:oxicloud/presentation/features/public_share/public_share_page.dart';

// Shell
import 'package:oxicloud/presentation/shell/adaptive_shell.dart';
import 'package:oxicloud/presentation/shell/desktop/desktop_sidebar.dart';
import 'package:oxicloud/presentation/shell/mobile/mobile_drawer.dart';
import 'package:oxicloud/presentation/shell/mobile/mobile_bottom_nav.dart';

// Router
import 'package:oxicloud/app_router.dart';

void main() {
  test('All modules compile successfully', () {
    // If we reach this point, ALL imports compiled correctly.
    // Verify key endpoint constants exist:
    expect(ApiEndpoints.authStatus, '/auth/status');
    expect(ApiEndpoints.i18nLocales, '/i18n/locales');
    expect(ApiEndpoints.searchCache, '/search/cache');
    expect(ApiEndpoints.version, '/version');
    expect(ApiEndpoints.adminGeneral, '/admin/settings/general');
    expect(ApiEndpoints.publicShareAccess('abc'), '/s/abc');
    expect(ApiEndpoints.publicShareVerify('abc'), '/s/abc/verify');
    expect(ApiEndpoints.publicShareDownload('abc'), '/s/abc/download');
    expect(ApiEndpoints.favoritesBatch, '/favorites/batch');
  });
}
