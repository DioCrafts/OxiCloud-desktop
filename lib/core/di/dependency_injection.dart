import 'package:get_it/get_it.dart';
import 'package:oxicloud_desktop/application/services/auth_service.dart';
import 'package:oxicloud_desktop/application/services/file_service.dart';
import 'package:oxicloud_desktop/application/services/folder_service.dart';
import 'package:oxicloud_desktop/application/services/native_fs_service.dart';
import 'package:oxicloud_desktop/application/services/sync_service.dart';
import 'package:oxicloud_desktop/application/services/trash_service.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/network/connectivity_service.dart';
import 'package:oxicloud_desktop/core/platform/battery_service.dart';
import 'package:oxicloud_desktop/core/platform/device_info_service.dart';
import 'package:oxicloud_desktop/core/storage/secure_storage.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';
import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
import 'package:oxicloud_desktop/domain/repositories/folder_repository.dart';
import 'package:oxicloud_desktop/domain/repositories/native_fs_repository.dart';
import 'package:oxicloud_desktop/domain/repositories/sync_repository.dart';
import 'package:oxicloud_desktop/domain/repositories/trash_repository.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/auth_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/native_fs_adapter_factory.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_file_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_folder_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/adapters/webdav_trash_adapter.dart';
import 'package:oxicloud_desktop/infrastructure/services/background_sync_service.dart';
import 'package:oxicloud_desktop/infrastructure/services/http_client.dart';
import 'package:oxicloud_desktop/infrastructure/services/local_storage_manager.dart';
import 'package:oxicloud_desktop/infrastructure/services/resource_manager.dart';
import 'package:oxicloud_desktop/infrastructure/services/webdav_sync_engine.dart';

/// Global ServiceLocator instance
final GetIt getIt = GetIt.instance;

/// Setup all dependencies
Future<void> setupDependencies() async {
  // App config
  getIt.registerSingletonAsync<AppConfig>(() async {
    final config = AppConfig();
    await config.load();
    return config;
  });
  
  // Core services - platform specific
  getIt.registerLazySingleton<DeviceInfoService>(() => DeviceInfoService());
  getIt.registerLazySingleton<BatteryService>(() => BatteryService());
  getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  
  // Wait for app config to be loaded
  await getIt.isReady<AppConfig>();
  
  // Storage
  getIt.registerSingletonAsync<SecureStorage>(() async {
    final storage = SecureStorage();
    await storage.initialize();
    return storage;
  });
  
  // Wait for secure storage to be initialized
  await getIt.isReady<SecureStorage>();
  
  // Client services
  getIt.registerLazySingleton<OxiHttpClient>(() => OxiHttpClient(
    getIt<AppConfig>(),
    getIt<SecureStorage>(),
  ));
  
  // Resource management
  getIt.registerLazySingleton<ResourceManager>(() => ResourceManager(
    getIt<DeviceInfoService>(),
    getIt<ConnectivityService>(),
    getIt<BatteryService>(),
  ));
  
  // Authentication
  getIt.registerLazySingleton<AuthRepository>(() => AuthAdapter(
    getIt<OxiHttpClient>(),
    getIt<SecureStorage>(),
  ));
  
  getIt.registerLazySingleton<AuthService>(() => AuthService(
    getIt<AuthRepository>(),
  ));
  
  // Local storage
  getIt.registerSingletonAsync<LocalStorageManager>(() async {
    final manager = LocalStorageManager(getIt<ResourceManager>());
    await manager.initialize();
    return manager;
  });
  
  // Wait for local storage to be initialized
  await getIt.isReady<LocalStorageManager>();
  
  // File and folder repositories
  getIt.registerLazySingleton<FileRepository>(() => WebDAVFileAdapter(
    getIt<AppConfig>(),
    getIt<SecureStorage>(),
  ));
  
  getIt.registerLazySingleton<FolderRepository>(() => WebDAVFolderAdapter(
    getIt<AppConfig>(),
    getIt<SecureStorage>(),
  ));
  
  // Sync repository
  getIt.registerLazySingleton<SyncRepository>(() => WebDAVSyncEngine(
    getIt<WebDAVFileAdapter>() as WebDAVFileAdapter,
    getIt<WebDAVFolderAdapter>() as WebDAVFolderAdapter,
    getIt<LocalStorageManager>(),
    getIt<ConnectivityService>(),
  ));
  
  // Trash repository
  getIt.registerLazySingleton<TrashRepository>(() => WebDAVTrashAdapter(
    getIt<AppConfig>(),
    getIt<SecureStorage>(),
    getIt<WebDAVFileAdapter>() as WebDAVFileAdapter,
    getIt<WebDAVFolderAdapter>() as WebDAVFolderAdapter,
  ));
  
  // Application services
  getIt.registerLazySingleton<FileService>(() => FileService(
    getIt<FileRepository>(),
    getIt<ResourceManager>(),
  ));
  
  getIt.registerLazySingleton<FolderService>(() => FolderService(
    getIt<FolderRepository>(),
    getIt<ResourceManager>(),
  ));
  
  getIt.registerLazySingleton<TrashService>(() => TrashService(
    getIt<TrashRepository>(),
  ));
  
  getIt.registerLazySingleton<SyncService>(() => SyncService(
    getIt<SyncRepository>(),
    getIt<ConnectivityService>(),
    getIt<ResourceManager>(),
  ));
  
  // Background sync
  getIt.registerLazySingleton<BackgroundSyncService>(() => BackgroundSyncService(
    getIt<SyncService>(),
    getIt<ResourceManager>(),
    getIt<ConnectivityService>(),
    getIt<BatteryService>(),
  ));
  
  // Native file system integration
  getIt.registerLazySingletonAsync<NativeFileSystemRepository>(() async {
    // Get local sync folder from LocalStorageManager
    final localStorageManager = getIt<LocalStorageManager>();
    final syncFolder = await localStorageManager.getSyncFolderPath();
    
    // Create platform-specific implementation
    final factory = NativeFileSystemAdapterFactory();
    final repository = factory.create(getIt<SecureStorage>(), syncFolder);
    
    // Initialize
    await repository.initialize();
    
    return repository;
  });
  
  getIt.registerLazySingletonAsync<NativeFileSystemService>(() async {
    // Wait for NativeFileSystemRepository to be initialized
    await getIt.isReady<NativeFileSystemRepository>();
    
    return NativeFileSystemService(getIt<NativeFileSystemRepository>());
  });
}