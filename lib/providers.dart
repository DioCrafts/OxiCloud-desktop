import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'core/auth/secure_storage.dart';
import 'core/config/app_config.dart';
import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/network/connectivity_service.dart';
import 'core/sync/sync_engine.dart';
import 'data/datasources/remote/admin_remote_datasource.dart';
import 'data/datasources/remote/app_password_remote_datasource.dart';
import 'data/datasources/remote/auth_remote_datasource.dart';
import 'data/datasources/remote/batch_remote_datasource.dart';
import 'data/datasources/remote/chunked_upload_datasource.dart';
import 'data/datasources/remote/dedup_remote_datasource.dart';
import 'data/datasources/remote/device_auth_remote_datasource.dart';
import 'data/datasources/remote/favorites_remote_datasource.dart';
import 'data/datasources/remote/file_remote_datasource.dart';
import 'data/datasources/remote/folder_remote_datasource.dart';
import 'data/datasources/remote/i18n_remote_datasource.dart';
import 'data/datasources/remote/oidc_remote_datasource.dart';
import 'data/datasources/remote/playlist_remote_datasource.dart';
import 'data/datasources/remote/recent_remote_datasource.dart';
import 'data/datasources/remote/search_remote_datasource.dart';
import 'data/datasources/remote/share_remote_datasource.dart';
import 'data/datasources/remote/photos_remote_datasource.dart';
import 'data/datasources/remote/public_share_remote_datasource.dart';
import 'data/datasources/remote/trash_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/favorites_repository_impl.dart';
import 'data/repositories/file_repository_impl.dart';
import 'data/repositories/folder_repository_impl.dart';
import 'data/repositories/photos_repository_impl.dart';
import 'data/repositories/recent_repository_impl.dart';
import 'data/repositories/search_repository_impl.dart';
import 'data/repositories/share_repository_impl.dart';
import 'data/repositories/trash_repository_impl.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/favorites_repository.dart';
import 'domain/repositories/file_repository.dart';
import 'domain/repositories/folder_repository.dart';
import 'domain/repositories/photos_repository.dart';
import 'domain/repositories/recent_repository.dart';
import 'domain/repositories/search_repository.dart';
import 'domain/repositories/share_repository.dart';
import 'domain/repositories/trash_repository.dart';

// --- Core ---

/// Notifier that manages AppConfig at runtime.
/// Loads the serverUrl from SecureStorage and allows updating it.
class AppConfigNotifier extends Notifier<AppConfig> {
  late final SecureStorage _secureStorage;

  @override
  AppConfig build() {
    _secureStorage = ref.watch(secureStorageProvider);
    return const AppConfig(serverUrl: '');
  }

  /// Load the saved serverUrl from secure storage. Call once at startup.
  Future<void> loadSavedConfig() async {
    final savedUrl = await _secureStorage.getServerUrl();
    if (savedUrl != null && savedUrl.isNotEmpty) {
      state = state.copyWith(serverUrl: savedUrl);
    }
  }

  /// Update the server URL, persist it, and rebuild dependent providers.
  Future<void> setServerUrl(String url) async {
    final normalized = url.trimRight().endsWith('/')
        ? url.trimRight().substring(0, url.trimRight().length - 1)
        : url.trimRight();
    await _secureStorage.saveServerUrl(normalized);
    state = state.copyWith(serverUrl: normalized);
  }
}

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final connectivityProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provides the application support directory path for the database.
final dbPathProvider = FutureProvider<String>((ref) async {
  final dir = await getApplicationSupportDirectory();
  return dir.path;
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final dbPathAsync = ref.watch(dbPathProvider);
  final path = dbPathAsync.maybeWhen(data: (p) => p, orElse: () => '');
  final db = AppDatabase(openDatabase(path));
  ref.onDispose(db.close);
  return db;
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  final client = ApiClient(config: config, secureStorage: secureStorage);
  return client.dio;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityProvider),
    fileRepo: ref.watch(fileRepositoryProvider),
    folderRepo: ref.watch(folderRepositoryProvider),
    favoritesRepo: ref.watch(favoritesRepositoryProvider),
    trashRepo: ref.watch(trashRepositoryProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
});

// --- Datasources ---

final authRemoteProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.watch(dioProvider));
});

final fileRemoteProvider = Provider<FileRemoteDatasource>((ref) {
  return FileRemoteDatasource(ref.watch(dioProvider));
});

final folderRemoteProvider = Provider<FolderRemoteDatasource>((ref) {
  return FolderRemoteDatasource(ref.watch(dioProvider));
});

final trashRemoteProvider = Provider<TrashRemoteDatasource>((ref) {
  return TrashRemoteDatasource(ref.watch(dioProvider));
});

final favoritesRemoteProvider = Provider<FavoritesRemoteDatasource>((ref) {
  return FavoritesRemoteDatasource(ref.watch(dioProvider));
});

final recentRemoteProvider = Provider<RecentRemoteDatasource>((ref) {
  return RecentRemoteDatasource(ref.watch(dioProvider));
});

final searchRemoteProvider = Provider<SearchRemoteDatasource>((ref) {
  return SearchRemoteDatasource(ref.watch(dioProvider));
});

final shareRemoteProvider = Provider<ShareRemoteDatasource>((ref) {
  return ShareRemoteDatasource(ref.watch(dioProvider));
});

// --- Repositories ---

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.watch(authRemoteProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  return FileRepositoryImpl(
    remote: ref.watch(fileRemoteProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl(
    remote: ref.watch(folderRemoteProvider),
    db: ref.watch(databaseProvider),
    connectivity: ref.watch(connectivityProvider),
  );
});

final trashRepositoryProvider = Provider<TrashRepository>((ref) {
  return TrashRepositoryImpl(remote: ref.watch(trashRemoteProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(remote: ref.watch(favoritesRemoteProvider));
});

final recentRepositoryProvider = Provider<RecentRepository>((ref) {
  return RecentRepositoryImpl(remote: ref.watch(recentRemoteProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(remote: ref.watch(searchRemoteProvider));
});

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepositoryImpl(remote: ref.watch(shareRemoteProvider));
});

final photosRemoteProvider = Provider<PhotosRemoteDatasource>((ref) {
  return PhotosRemoteDatasource(ref.watch(dioProvider));
});

final photosRepositoryProvider = Provider<PhotosRepository>((ref) {
  return PhotosRepositoryImpl(remote: ref.watch(photosRemoteProvider));
});

// --- Chunked Uploads ---

final chunkedUploadDatasourceProvider = Provider<ChunkedUploadDatasource>((
  ref,
) {
  return ChunkedUploadDatasource(ref.watch(dioProvider));
});

// --- Batch ---

final batchRemoteDatasourceProvider = Provider<BatchRemoteDatasource>((ref) {
  return BatchRemoteDatasource(ref.watch(dioProvider));
});

// --- OIDC ---

final oidcRemoteDatasourceProvider = Provider<OidcRemoteDatasource>((ref) {
  return OidcRemoteDatasource(ref.watch(dioProvider));
});

// --- Dedup ---

final dedupRemoteDatasourceProvider = Provider<DedupRemoteDatasource>((ref) {
  return DedupRemoteDatasource(ref.watch(dioProvider));
});

// --- Playlists ---

final playlistRemoteDatasourceProvider = Provider<PlaylistRemoteDatasource>((
  ref,
) {
  return PlaylistRemoteDatasource(ref.watch(dioProvider));
});

// --- Admin ---

final adminRemoteDatasourceProvider = Provider<AdminRemoteDatasource>((ref) {
  return AdminRemoteDatasource(ref.watch(dioProvider));
});

// --- App Passwords ---

final appPasswordRemoteDatasourceProvider =
    Provider<AppPasswordRemoteDatasource>((ref) {
      return AppPasswordRemoteDatasource(ref.watch(dioProvider));
    });

// --- Device Auth ---

final deviceAuthRemoteDatasourceProvider = Provider<DeviceAuthRemoteDatasource>(
  (ref) {
    return DeviceAuthRemoteDatasource(ref.watch(dioProvider));
  },
);

// --- i18n ---

final i18nRemoteDatasourceProvider = Provider<I18nRemoteDatasource>((ref) {
  return I18nRemoteDatasource(ref.watch(dioProvider));
});

// --- Public Share ---

final publicShareRemoteDatasourceProvider =
    Provider<PublicShareRemoteDatasource>((ref) {
      return PublicShareRemoteDatasource(ref.watch(dioProvider));
    });
