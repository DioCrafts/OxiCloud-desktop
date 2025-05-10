import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'package:oxicloud_desktop/core/theme/app_theme.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/api_auth_repository.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/api_file_repository.dart';
import 'package:oxicloud_desktop/infrastructure/repositories/local_auth_repository.dart';
import 'package:oxicloud_desktop/presentation/providers/auth_provider.dart';
import 'package:oxicloud_desktop/presentation/providers/file_explorer_provider.dart';
import 'package:oxicloud_desktop/presentation/views/file_explorer_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:oxicloud_desktop/infrastructure/database/database_helper.dart';

// Proveedor para el repositorio local de autenticación
final localAuthRepositoryProvider = Provider<LocalAuthRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LocalAuthRepository(dbHelper);
});

// Proveedor de DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  throw UnimplementedError('DatabaseHelper no ha sido inicializado');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar configuración
  final config = AppConfig();
  await config.initialize();
  
  // Inicializar SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Inicializar Dio
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Inicializar la base de datos SQLite
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  runApp(
    ProviderScope(
      overrides: [
        // Otros proveedores
        authRepositoryProvider.overrideWithValue(
          ApiAuthRepository(config.apiClient, prefs),
        ),
        apiFileRepositoryProvider.overrideWithValue(
          ApiFileRepository(dio, 'http://localhost:8080/api'),
        ),
        // Proveedor de DatabaseHelper
        databaseHelperProvider.overrideWithValue(dbHelper),
        // Proveedor de LocalAuthRepository
        localAuthRepositoryProvider.overrideWithValue(
          LocalAuthRepository(dbHelper),
        ),
      ],
      child: MaterialApp(
        title: 'OxiCloud Desktop',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: const FileExplorerView(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OxiCloud Desktop',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FileExplorerView(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Has presionado el botón esta cantidad de veces:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Incrementar',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
