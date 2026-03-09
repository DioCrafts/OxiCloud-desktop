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
import 'data/datasources/batch_api_datasource.dart';
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

  getIt
    ..registerLazySingleton<RustBridgeDataSource>(
      RustBridgeDataSource.new,
    )
    ..registerLazySingleton<ApiClient>(
      ApiClient.new,
    )
    ..registerLazySingleton<FileBrowserApiDataSource>(
      () => FileBrowserApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<TrashApiDataSource>(
      () => TrashApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ShareApiDataSource>(
      () => ShareApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<SearchApiDataSource>(
      () => SearchApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<FavoritesApiDataSource>(
      () => FavoritesApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<RecentApiDataSource>(
      () => RecentApiDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<ChunkedUploadDataSource>(
      () => ChunkedUploadDataSource(getIt<ApiClient>()),
    )
    ..registerLazySingleton<BatchApiDataSource>(
      () => BatchApiDataSource(getIt<ApiClient>()),
    )

    // ==========================================================================
    // Repositories
    // ==========================================================================

    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        getIt<RustBridgeDataSource>(),
        getIt<ApiClient>(),
      ),
    )
    ..registerLazySingleton<SyncRepository>(
      () => SyncRepositoryImpl(getIt<RustBridgeDataSource>()),
    )
    ..registerLazySingleton<FileBrowserRepository>(
      () => FileBrowserRepositoryImpl(
        getIt<FileBrowserApiDataSource>(),
        getIt<ChunkedUploadDataSource>(),
        getIt<BatchApiDataSource>(),
      ),
    )
    ..registerLazySingleton<TrashRepository>(
      () => TrashRepositoryImpl(getIt<TrashApiDataSource>()),
    )
    ..registerLazySingleton<ShareRepository>(
      () => ShareRepositoryImpl(getIt<ShareApiDataSource>()),
    )
    ..registerLazySingleton<SearchRepository>(
      () => SearchRepositoryImpl(getIt<SearchApiDataSource>()),
    )
    ..registerLazySingleton<FavoritesRepository>(
      () => FavoritesRepositoryImpl(getIt<FavoritesApiDataSource>()),
    )
    ..registerLazySingleton<RecentRepository>(
      () => RecentRepositoryImpl(getIt<RecentApiDataSource>()),
    )

    // ==========================================================================
    // Platform services
    // ==========================================================================

    ..registerLazySingleton<SystemTrayService>(
      SystemTrayService.new,
    );
}
