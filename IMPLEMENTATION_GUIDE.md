# Guía de Implementación - OxiCloud Desktop Client

## Configuración inicial

1. **Instalación de Flutter**
   ```bash
   # Descargar e instalar Flutter SDK
   git clone https://github.com/flutter/flutter.git
   export PATH="$PATH:`pwd`/flutter/bin"
   flutter doctor
   ```

2. **Crear proyecto Flutter**
   ```bash
   flutter create --platforms=android,ios,linux,macos,windows oxicloud_desktop
   cd oxicloud_desktop
   ```

3. **Configurar dependencias base**
   ```yaml
   # pubspec.yaml
   dependencies:
     flutter:
       sdk: flutter
     # Manejo de estado
     flutter_riverpod: ^2.4.0
     # Inyección de dependencias
     get_it: ^7.6.0
     # HTTP y WebDAV
     dio: ^5.3.2
     webdav_client: ^1.2.0
     # Almacenamiento local
     hive_flutter: ^1.1.0
     # Almacenamiento seguro
     flutter_secure_storage: ^9.0.0
     # Paths y sistema de archivos
     path_provider: ^2.1.1
     file_picker: ^6.0.0
     # Utilidades
     intl: ^0.18.1
     logging: ^1.2.0
     connectivity_plus: ^5.0.1
     # Sincronización en background
     workmanager: ^0.5.2
     # UI
     flutter_spinkit: ^5.2.0
     cached_network_image: ^3.3.0
   ```

## Implementación por Capas

### 1. Capa de Dominio

1. **Entidades**
   ```dart
   // lib/domain/entities/file_entity.dart
   class FileEntity {
     final String id;
     final String name;
     final String path;
     final int size;
     final DateTime modifiedAt;
     final String mimeType;
     final bool isShared;
     final bool isFavorite;
     
     const FileEntity({
       required this.id,
       required this.name,
       required this.path,
       required this.size,
       required this.modifiedAt,
       required this.mimeType,
       this.isShared = false,
       this.isFavorite = false,
     });
   }
   ```

2. **Repositorios (interfaces)**
   ```dart
   // lib/domain/repositories/file_repository.dart
   abstract class FileRepository {
     Future<List<FileEntity>> listFiles(String folderId);
     Future<FileEntity> getFile(String fileId);
     Future<FileEntity> uploadFile(String path, List<int> data, {String? parentId});
     Future<void> downloadFile(String fileId, String localPath);
     Future<void> deleteFile(String fileId);
     Future<FileEntity> moveFile(String fileId, String newParentId);
     Future<FileEntity> renameFile(String fileId, String newName);
   }
   ```

3. **Errores de dominio**
   ```dart
   // lib/domain/errors/domain_error.dart
   abstract class DomainError implements Exception {
     final String message;
     final String? code;
     
     const DomainError(this.message, {this.code});
     
     @override
     String toString() => 'DomainError: $message (code: $code)';
   }
   
   class FileNotFoundError extends DomainError {
     const FileNotFoundError(String fileId) 
         : super('File not found: $fileId', code: 'FILE_NOT_FOUND');
   }
   ```

### 2. Capa de Aplicación

1. **DTOs**
   ```dart
   // lib/application/dtos/file_dto.dart
   import 'package:oxicloud_desktop/domain/entities/file_entity.dart';
   
   class FileDTO {
     final String id;
     final String name;
     final String path;
     final int size;
     final String modifiedAt;
     final String mimeType;
     final bool isShared;
     final bool isFavorite;
     
     const FileDTO({
       required this.id,
       required this.name,
       required this.path,
       required this.size,
       required this.modifiedAt,
       required this.mimeType,
       this.isShared = false,
       this.isFavorite = false,
     });
     
     factory FileDTO.fromJson(Map<String, dynamic> json) {
       return FileDTO(
         id: json['id'],
         name: json['name'],
         path: json['path'],
         size: json['size'],
         modifiedAt: json['modified_at'],
         mimeType: json['mime_type'],
         isShared: json['is_shared'] ?? false,
         isFavorite: json['is_favorite'] ?? false,
       );
     }
     
     FileEntity toEntity() {
       return FileEntity(
         id: id,
         name: name,
         path: path,
         size: size,
         modifiedAt: DateTime.parse(modifiedAt),
         mimeType: mimeType,
         isShared: isShared,
         isFavorite: isFavorite,
       );
     }
   }
   ```

2. **Casos de uso**
   ```dart
   // lib/application/services/list_folder_contents_use_case.dart
   import 'package:oxicloud_desktop/domain/entities/file_entity.dart';
   import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
   
   class ListFolderContentsUseCase {
     final FileRepository _fileRepository;
     
     const ListFolderContentsUseCase(this._fileRepository);
     
     Future<List<FileEntity>> execute(String folderId) async {
       try {
         return await _fileRepository.listFiles(folderId);
       } catch (e) {
         // Transformar errores de infraestructura a errores de dominio
         rethrow;
       }
     }
   }
   ```

3. **Puertos**
   ```dart
   // lib/application/ports/auth_port.dart
   abstract class AuthPort {
     Future<String> login(String server, String username, String password);
     Future<String> refreshToken();
     Future<void> logout();
     bool isLoggedIn();
     String? getServer();
   }
   ```

### 3. Capa de Infraestructura

1. **Clientes HTTP**
   ```dart
   // lib/infrastructure/services/http_client.dart
   import 'package:dio/dio.dart';
   
   class HttpClient {
     final Dio _dio;
     final TokenProvider _tokenProvider;
     
     HttpClient(this._tokenProvider) : _dio = Dio() {
       _dio.interceptors.add(TokenInterceptor(_tokenProvider));
     }
     
     Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
       return _dio.get(path, queryParameters: queryParams);
     }
     
     Future<Response> post(String path, {dynamic data}) {
       return _dio.post(path, data: data);
     }
     
     // Otros métodos HTTP...
   }
   
   class TokenInterceptor extends Interceptor {
     final TokenProvider _tokenProvider;
     
     TokenInterceptor(this._tokenProvider);
     
     @override
     void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
       final token = _tokenProvider.getToken();
       if (token != null) {
         options.headers['Authorization'] = 'Bearer $token';
       }
       handler.next(options);
     }
     
     @override
     void onError(DioException err, ErrorInterceptorHandler handler) async {
       if (err.response?.statusCode == 401) {
         try {
           await _tokenProvider.refreshToken();
           // Reintentar solicitud
           final opts = err.requestOptions;
           final token = _tokenProvider.getToken();
           opts.headers['Authorization'] = 'Bearer $token';
           final response = await Dio().fetch(opts);
           handler.resolve(response);
           return;
         } catch (e) {
           // Error al refrescar token
         }
       }
       handler.next(err);
     }
   }
   ```

2. **Adaptadores WebDAV**
   ```dart
   // lib/infrastructure/adapters/webdav_adapter.dart
   import 'package:webdav_client/webdav_client.dart';
   import 'package:oxicloud_desktop/domain/repositories/file_repository.dart';
   import 'package:oxicloud_desktop/domain/entities/file_entity.dart';
   
   class WebDAVFileRepository implements FileRepository {
     final Client _client;
     final String _baseUrl;
     
     WebDAVFileRepository(this._client, this._baseUrl);
     
     @override
     Future<List<FileEntity>> listFiles(String folderId) async {
       try {
         final files = await _client.readDir('$_baseUrl/$folderId');
         return files.map((f) => FileEntity(
           id: f.name,
           name: f.name.split('/').last,
           path: f.path,
           size: f.size,
           modifiedAt: f.mTime,
           mimeType: f.mimeType ?? 'application/octet-stream',
         )).toList();
       } catch (e) {
         // Transformar error de WebDAV a error de dominio
         throw FileNotFoundError(folderId);
       }
     }
     
     // Implementación de otros métodos...
   }
   ```

3. **Servicios de sincronización**
   ```dart
   // lib/infrastructure/services/sync_service.dart
   class SyncService {
     final FileRepository _remoteRepo;
     final LocalRepository _localRepo;
     final SyncStateRepository _syncStateRepo;
     
     SyncService(this._remoteRepo, this._localRepo, this._syncStateRepo);
     
     Future<void> synchronize() async {
       // 1. Obtener cambios locales
       final localChanges = await _localRepo.getChanges();
       
       // 2. Subir cambios locales
       for (final change in localChanges) {
         try {
           await _uploadChange(change);
           await _syncStateRepo.markSynced(change.id);
         } catch (e) {
           await _syncStateRepo.markFailed(change.id, e.toString());
         }
       }
       
       // 3. Obtener cambios remotos
       final lastSync = await _syncStateRepo.getLastSyncTimestamp();
       final remoteChanges = await _remoteRepo.getChangesSince(lastSync);
       
       // 4. Aplicar cambios remotos
       for (final change in remoteChanges) {
         try {
           await _applyRemoteChange(change);
         } catch (e) {
           // Log error y continuar
         }
       }
       
       // 5. Actualizar timestamp de sincronización
       await _syncStateRepo.updateLastSyncTimestamp();
     }
     
     // Métodos auxiliares para sincronización...
   }
   ```

### 4. Capa de Presentación

1. **Proveedores de estado**
   ```dart
   // lib/presentation/providers/file_list_provider.dart
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:oxicloud_desktop/domain/entities/file_entity.dart';
   import 'package:oxicloud_desktop/application/services/list_folder_contents_use_case.dart';
   
   final fileListProvider = StateNotifierProvider.family<FileListNotifier, AsyncValue<List<FileEntity>>, String>(
     (ref, folderId) => FileListNotifier(ref.read(listFolderContentsProvider), folderId),
   );
   
   class FileListNotifier extends StateNotifier<AsyncValue<List<FileEntity>>> {
     final ListFolderContentsUseCase _listFolderContents;
     final String _folderId;
     
     FileListNotifier(this._listFolderContents, this._folderId) : super(const AsyncValue.loading()) {
       _loadFiles();
     }
     
     Future<void> _loadFiles() async {
       try {
         state = const AsyncValue.loading();
         final files = await _listFolderContents.execute(_folderId);
         state = AsyncValue.data(files);
       } catch (e, stack) {
         state = AsyncValue.error(e, stack);
       }
     }
     
     Future<void> refresh() => _loadFiles();
   }
   ```

2. **Widgets de UI**
   ```dart
   // lib/presentation/widgets/file_list_item.dart
   import 'package:flutter/material.dart';
   import 'package:oxicloud_desktop/domain/entities/file_entity.dart';
   
   class FileListItem extends StatelessWidget {
     final FileEntity file;
     final VoidCallback onTap;
     final VoidCallback? onLongPress;
     
     const FileListItem({
       Key? key,
       required this.file,
       required this.onTap,
       this.onLongPress,
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return ListTile(
         leading: _buildIcon(),
         title: Text(file.name),
         subtitle: Text(_formatSize(file.size)),
         trailing: _buildTrailing(),
         onTap: onTap,
         onLongPress: onLongPress,
       );
     }
     
     Widget _buildIcon() {
       // Lógica para determinar el icono basado en mime type
       IconData iconData;
       if (file.mimeType.startsWith('image/')) {
         iconData = Icons.image;
       } else if (file.mimeType.startsWith('video/')) {
         iconData = Icons.video_file;
       } else {
         iconData = Icons.insert_drive_file;
       }
       
       return Icon(iconData);
     }
     
     Widget _buildTrailing() {
       return Row(
         mainAxisSize: MainAxisSize.min,
         children: [
           if (file.isShared)
             const Icon(Icons.share, size: 16),
           if (file.isFavorite)
             const Icon(Icons.star, size: 16),
         ],
       );
     }
     
     String _formatSize(int bytes) {
       // Lógica para formatear tamaño en bytes, KB, MB, etc.
       if (bytes < 1024) return '$bytes B';
       if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
       return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
     }
   }
   ```

3. **Pantallas**
   ```dart
   // lib/presentation/pages/file_browser_page.dart
   import 'package:flutter/material.dart';
   import 'package:flutter_riverpod/flutter_riverpod.dart';
   import 'package:oxicloud_desktop/presentation/providers/file_list_provider.dart';
   import 'package:oxicloud_desktop/presentation/widgets/file_list_item.dart';
   
   class FileBrowserPage extends ConsumerWidget {
     final String folderId;
     
     const FileBrowserPage({Key? key, required this.folderId}) : super(key: key);
     
     @override
     Widget build(BuildContext context, WidgetRef ref) {
       final fileListState = ref.watch(fileListProvider(folderId));
       
       return Scaffold(
         appBar: AppBar(
           title: const Text('Files'),
           actions: [
             IconButton(
               icon: const Icon(Icons.refresh),
               onPressed: () => ref.read(fileListProvider(folderId).notifier).refresh(),
             ),
           ],
         ),
         body: fileListState.when(
           data: (files) => ListView.builder(
             itemCount: files.length,
             itemBuilder: (context, index) {
               final file = files[index];
               return FileListItem(
                 file: file,
                 onTap: () => _handleFileTap(context, file),
                 onLongPress: () => _showFileOptions(context, file),
               );
             },
           ),
           loading: () => const Center(child: CircularProgressIndicator()),
           error: (error, stack) => Center(
             child: Text('Error: ${error.toString()}'),
           ),
         ),
         floatingActionButton: FloatingActionButton(
           onPressed: () => _showAddOptions(context),
           child: const Icon(Icons.add),
         ),
       );
     }
     
     void _handleFileTap(BuildContext context, FileEntity file) {
       // Lógica para abrir archivo o carpeta
     }
     
     void _showFileOptions(BuildContext context, FileEntity file) {
       // Mostrar menú contextual con opciones
     }
     
     void _showAddOptions(BuildContext context) {
       // Mostrar opciones para crear carpeta o subir archivo
     }
   }
   ```

## Implementación de Eficiencia en Recursos

### Optimización de Memoria

```dart
// lib/infrastructure/services/memory_optimization_service.dart
class MemoryOptimizationService {
  final int maxCacheSize;
  final Map<String, Uint8List> _cache = {};
  final Map<String, DateTime> _lastAccessed = {};
  
  MemoryOptimizationService({this.maxCacheSize = 50 * 1024 * 1024}); // 50MB default
  
  Uint8List? getFromCache(String key) {
    final data = _cache[key];
    if (data != null) {
      _lastAccessed[key] = DateTime.now();
    }
    return data;
  }
  
  void addToCache(String key, Uint8List data) {
    // Verificar si excedemos el límite de caché
    int currentSize = _getTotalCacheSize();
    if (currentSize + data.length > maxCacheSize) {
      _evictOldestEntries(data.length);
    }
    
    _cache[key] = data;
    _lastAccessed[key] = DateTime.now();
  }
  
  int _getTotalCacheSize() {
    return _cache.values.fold(0, (sum, data) => sum + data.length);
  }
  
  void _evictOldestEntries(int requiredSpace) {
    // Ordenar por tiempo de último acceso
    final entries = _lastAccessed.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    int freedSpace = 0;
    for (final entry in entries) {
      if (freedSpace >= requiredSpace) break;
      
      final key = entry.key;
      final data = _cache[key];
      if (data != null) {
        freedSpace += data.length;
        _cache.remove(key);
        _lastAccessed.remove(key);
      }
    }
  }
  
  void clearCache() {
    _cache.clear();
    _lastAccessed.clear();
  }
}
```

### Sincronización Eficiente

```dart
// lib/infrastructure/services/adaptive_sync_service.dart
class AdaptiveSyncService {
  final SyncService _syncService;
  final ConnectivityService _connectivityService;
  final BatteryService _batteryService;
  
  AdaptiveSyncService(
    this._syncService,
    this._connectivityService,
    this._batteryService,
  );
  
  Future<void> performSync() async {
    final syncConfig = await _determineSyncConfig();
    await _syncService.synchronize(
      fullSync: syncConfig.fullSync,
      includeThumbnails: syncConfig.includeThumbnails,
      maxFileSize: syncConfig.maxFileSize,
    );
  }
  
  Future<SyncConfig> _determineSyncConfig() async {
    final connectivity = await _connectivityService.getConnectivityType();
    final batteryLevel = await _batteryService.getBatteryLevel();
    final isCharging = await _batteryService.isCharging();
    
    // Configuración óptima basada en condiciones actuales
    if (connectivity == ConnectivityType.wifi && (isCharging || batteryLevel > 50)) {
      // Sincronización completa en condiciones ideales
      return SyncConfig(
        fullSync: true,
        includeThumbnails: true,
        maxFileSize: null, // Sin límite
      );
    } else if (connectivity == ConnectivityType.mobile && batteryLevel > 30) {
      // Sincronización limitada en datos móviles
      return SyncConfig(
        fullSync: false,
        includeThumbnails: false,
        maxFileSize: 5 * 1024 * 1024, // 5MB
      );
    } else {
      // Sincronización mínima en batería baja
      return SyncConfig(
        fullSync: false,
        includeThumbnails: false,
        maxFileSize: 1 * 1024 * 1024, // 1MB
      );
    }
  }
}

class SyncConfig {
  final bool fullSync;
  final bool includeThumbnails;
  final int? maxFileSize;
  
  SyncConfig({
    required this.fullSync,
    required this.includeThumbnails,
    this.maxFileSize,
  });
}
```

## Configuración de Dependency Injection

```dart
// lib/core/di/dependency_injection.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // Servicios core
  getIt.registerSingleton<LoggingService>(LoggingService());
  getIt.registerSingleton<SecureStorageService>(SecureStorageService());
  
  // Servicios de infraestructura
  final secureStorage = getIt<SecureStorageService>();
  getIt.registerSingleton<TokenProvider>(TokenProvider(secureStorage));
  getIt.registerSingleton<HttpClient>(HttpClient(getIt<TokenProvider>()));
  
  // Adaptadores
  getIt.registerFactory<FileRepository>(() => WebDAVFileRepository(
    getIt<HttpClient>(),
    'https://server.example.com/webdav',
  ));
  
  // Casos de uso
  getIt.registerFactory<ListFolderContentsUseCase>(() => 
    ListFolderContentsUseCase(getIt<FileRepository>())
  );
  
  // Servicios de optimización
  getIt.registerSingleton<MemoryOptimizationService>(MemoryOptimizationService());
  getIt.registerSingleton<ConnectivityService>(ConnectivityService());
  getIt.registerSingleton<BatteryService>(BatteryService());
  getIt.registerSingleton<AdaptiveSyncService>(AdaptiveSyncService(
    getIt<SyncService>(),
    getIt<ConnectivityService>(),
    getIt<BatteryService>(),
  ));
}
```

## Notas de Implementación

- **Configuración de Flutter**: Asegúrate de configurar correctamente Flutter para todas las plataformas objetivo.
- **Permisos**: Configura los permisos necesarios en cada plataforma (almacenamiento, red, notificaciones).
- **Background Sync**: Usa Workmanager o plugins específicos por plataforma para sincronización en segundo plano.
- **Testing**: Implementa tests unitarios y de integración para cada capa.
- **Multiplatforma**: Usa abstracciones para código específico de plataforma y adapta la UI según el tamaño de pantalla.
- **Seguridad**: Implementa cifrado para datos sensibles en disco y en memoria.