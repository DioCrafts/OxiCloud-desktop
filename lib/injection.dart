import 'package:get_it/get_it.dart';

import 'core/repositories/auth_repository.dart';
import 'core/repositories/sync_repository.dart';
import 'data/datasources/rust_bridge_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';

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

  // ============================================================================
  // Repositories
  // ============================================================================
  
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<RustBridgeDataSource>()),
  );

  getIt.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(getIt<RustBridgeDataSource>()),
  );
}
