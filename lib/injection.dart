import 'package:get_it/get_it.dart';

import 'core/repositories/auth_repository.dart';
import 'core/repositories/favorites_repository.dart';
import 'core/repositories/file_browser_repository.dart';
import 'core/repositories/recent_repository.dart';
import 'core/repositories/search_repository.dart';
import 'core/repositories/share_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'core/repositories/trash_repository.dart';
import 'data/datasources/api_client.dart';
import 'data/datasources/chunked_upload_datasource.dart';
import 'data/datasources/favorites_api_datasource.dart';
import 'data/datasources/file_browser_api_datasource.dart';
import 'data/datasources/recent_api_datasource.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'data/datasources/search_api_datasource.dart';
import 'data/datasources/share_api_datasource.dart';
import 'data/datasources/trash_api_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/favorites_repository_impl.dart';
import 'data/repositories/file_browser_repository_impl.dart';
import 'data/repositories/recent_repository_impl.dart';
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

  getIt.registerLazySingleton<RustBridgeDataSource>(
    () => RustBridgeDataSource(),
  );

  getIt.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  getIt.registerLazySingleton<FileBrowserApiDataSource>(
    () => FileBrowserApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<TrashApiDataSource>(
    () => TrashApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ShareApiDataSource>(
    () => ShareApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<SearchApiDataSource>(
    () => SearchApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<FavoritesApiDataSource>(
    () => FavoritesApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<RecentApiDataSource>(
    () => RecentApiDataSource(getIt<ApiClient>()),
  );

  getIt.registerLazySingleton<ChunkedUploadDataSource>(
    () => ChunkedUploadDataSource(getIt<ApiClient>()),
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

  getIt.registerLazySingleton<FavoritesRepository>(
    () => FavoritesRepositoryImpl(getIt<FavoritesApiDataSource>()),
  );

  getIt.registerLazySingleton<RecentRepository>(
    () => RecentRepositoryImpl(getIt<RecentApiDataSource>()),
  );

  // ============================================================================
  // Platform services
  // ============================================================================

  getIt.registerLazySingleton<SystemTrayService>(
    () => SystemTrayService(),
  );
}
