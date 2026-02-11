import 'package:get_it/get_it.dart';

import 'core/repositories/auth_repository.dart';
import 'core/repositories/file_browser_repository.dart';
import 'core/repositories/search_repository.dart';
import 'core/repositories/share_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'core/repositories/trash_repository.dart';
import 'data/datasources/api_client.dart';
import 'data/datasources/file_browser_api_datasource.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'data/datasources/search_api_datasource.dart';
import 'data/datasources/share_api_datasource.dart';
import 'data/datasources/trash_api_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/file_browser_repository_impl.dart';
import 'data/repositories/search_repository_impl.dart';
import 'data/repositories/share_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';
import 'data/repositories/trash_repository_impl.dart';
import 'platform/system_tray_service.dart';

final getIt = GetIt.instance;

/// Configure all dependencies
Future<void> configureDependencies() async {
  // ============================================================================
  // Data Sources
  // ============================================================================
  
  // Rust Bridge Data Source - connects to native Rust code
  getIt.registerLazySingleton<RustBridgeDataSource>(
    () => RustBridgeDataSource(),
  );

  // HTTP API client for REST calls (file browser, etc.)
  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  // File browser API data source
  getIt.registerLazySingleton<FileBrowserApiDataSource>(
    () => FileBrowserApiDataSource(getIt<ApiClient>()),
  );

  // Trash API data source
  getIt.registerLazySingleton<TrashApiDataSource>(
    () => TrashApiDataSource(getIt<ApiClient>()),
  );

  // Share API data source
  getIt.registerLazySingleton<ShareApiDataSource>(
    () => ShareApiDataSource(getIt<ApiClient>()),
  );

  // Search API data source
  getIt.registerLazySingleton<SearchApiDataSource>(
    () => SearchApiDataSource(getIt<ApiClient>()),
  );

  // ============================================================================
  // Repositories
  // ============================================================================
  
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      getIt<RustBridgeDataSource>(),
      getIt<ApiClient>(),
    ),
  );

  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(getIt<RustBridgeDataSource>()),
  );

  getIt.registerLazySingleton<FileBrowserRepository>(
    () => FileBrowserRepositoryImpl(getIt<FileBrowserApiDataSource>()),
  );

  getIt.registerLazySingleton<TrashRepository>(
    () => TrashRepositoryImpl(getIt<TrashApiDataSource>()),
  );

  getIt.registerLazySingleton<ShareRepository>(
    () => ShareRepositoryImpl(getIt<ShareApiDataSource>()),
  );

  getIt.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(getIt<SearchApiDataSource>()),
  );

  // ============================================================================
  // Platform services
  // ============================================================================

  getIt.registerLazySingleton<SystemTrayService>(
    () => SystemTrayService(),
  );
}
