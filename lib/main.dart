import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();

  // Load saved server URL from secure storage
  await container.read(appConfigProvider.notifier).loadSavedConfig();

  // Check initial connectivity
  await container.read(connectivityProvider).checkConnectivity();

  // Start sync engine only if server is configured
  final config = container.read(appConfigProvider);
  if (config.hasServer) {
    container.read(syncEngineProvider).start();
  }

  runApp(
    UncontrolledProviderScope(container: container, child: const OxiCloudApp()),
  );
}
