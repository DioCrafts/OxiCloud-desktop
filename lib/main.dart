import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/core/di/dependency_injection.dart';
import 'package:oxicloud_desktop/core/logging/logging_manager.dart';
import 'package:oxicloud_desktop/infrastructure/services/background_sync_service.dart';
import 'package:oxicloud_desktop/presentation/routes/app_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging
  await LoggingManager.initialize();
  
  // Initialize dependencies
  await setupDependencies();
  
  // Initialize background sync service
  final backgroundSyncService = getIt<BackgroundSyncService>();
  await backgroundSyncService.initialize();
  
  // Run the app
  runApp(
    const ProviderScope(
      child: OxiCloudApp(),
    ),
  );
}

class OxiCloudApp extends ConsumerWidget {
  const OxiCloudApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'OxiCloud Desktop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}