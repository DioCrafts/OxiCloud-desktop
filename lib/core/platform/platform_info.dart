import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class PlatformInfo {
  PlatformInfo._();

  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;

  static String get platformName {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}

class FileSystem {
  FileSystem._();

  static Future<String> get downloadDir async {
    if (PlatformInfo.isDesktop) {
      final dir = await getDownloadsDirectory();
      return dir?.path ?? (await getApplicationDocumentsDirectory()).path;
    }
    return (await getApplicationDocumentsDirectory()).path;
  }

  static Future<String> get cacheDir async {
    final dir = await getApplicationCacheDirectory();
    return dir.path;
  }

  static Future<String> get appDataDir async {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }

  static Future<String> get offlineCacheDir async {
    final cache = await cacheDir;
    final dir = Directory(p.join(cache, 'offline_files'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get thumbnailCacheDir async {
    final cache = await cacheDir;
    final dir = Directory(p.join(cache, 'thumbnails'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  static Future<String> get databaseDir async {
    final data = await appDataDir;
    final dir = Directory(p.join(data, 'db'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }
}
