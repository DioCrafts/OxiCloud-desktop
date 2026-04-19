import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class AppConfig {
  final String serverUrl;
  final Environment environment;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int chunkSizeBytes;
  final int chunkThresholdBytes;
  final int maxConcurrentUploads;
  final int maxConcurrentDownloads;
  final int syncIntervalSeconds;
  final int maxRetries;

  const AppConfig({
    required this.serverUrl,
    this.environment = Environment.prod,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 60),
    this.chunkSizeBytes = 5 * 1024 * 1024, // 5 MB
    this.chunkThresholdBytes = 10 * 1024 * 1024, // 10 MB
    this.maxConcurrentUploads = 3,
    this.maxConcurrentDownloads = 5,
    this.syncIntervalSeconds = 30,
    this.maxRetries = 3,
  });

  String get apiBaseUrl => '$serverUrl/api';

  bool get isDebug => environment == Environment.dev;

  bool get hasServer => serverUrl.isNotEmpty;

  AppConfig copyWith({String? serverUrl, Environment? environment}) {
    return AppConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      environment: environment ?? this.environment,
    );
  }

  @override
  String toString() => 'AppConfig(server: $serverUrl, env: ${describeEnum(environment)})';
}
