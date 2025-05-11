// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/main.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/api_file_repository.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/api_auth_repository.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/local_auth_repository.dart';
import 'package:oxicloud_desktop/infrastructure/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

void main() {
  testWidgets('FileExplorerView smoke test', (WidgetTester tester) async {
    // Inicializar las dependencias necesarias
    final dio = Dio(BaseOptions(
      baseUrl: 'http://localhost:8080/api',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));

    final dbHelper = DatabaseHelper();
    await dbHelper.database;

    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiFileRepositoryProvider.overrideWithValue(
            ApiFileRepository(dio, 'http://localhost:8080/api'),
          ),
          authRepositoryProvider.overrideWithValue(
            ApiAuthRepository(dio, prefs),
          ),
          databaseHelperProvider.overrideWithValue(dbHelper),
          localAuthRepositoryProvider.overrideWithValue(
            LocalAuthRepository(dbHelper),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verificar que la vista se carga correctamente
    expect(find.byType(FileExplorerView), findsOneWidget);
  });
}
