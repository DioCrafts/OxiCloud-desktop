# Optimización de Recursos en OxiCloud Desktop Client

Este documento detalla estrategias específicas para minimizar el consumo de recursos en todas las plataformas. Cada MB cuenta, por lo que estas optimizaciones son críticas para el rendimiento de la aplicación.

## 1. Optimización de Memoria (RAM)

### Estrategias de Caché
```dart
class ResourceAwareCacheManager {
  // Límites adaptativos según dispositivo
  late final int _maxMemoryCacheSize;
  final Map<String, Uint8List> _memoryCache = {};
  final LruQueue<String> _accessQueue = LruQueue<String>(100);
  
  ResourceAwareCacheManager() {
    // Detectar memoria disponible en dispositivo
    _initializeMemoryLimits();
  }
  
  Future<void> _initializeMemoryLimits() async {
    final deviceInfo = await DeviceInfoPlugin().deviceInfo;
    final availableRam = _getAvailableRam(deviceInfo);
    
    // Limitar caché al 5% de RAM disponible, máximo 50MB
    _maxMemoryCacheSize = min(availableRam ~/ 20, 50 * 1024 * 1024);
    debugPrint('Caché limitada a: ${_maxMemoryCacheSize ~/ 1024} KB');
  }
  
  // Almacenamiento en caché con control de tamaño
  void cacheData(String key, Uint8List data) {
    // Evitar cachear archivos demasiado grandes (>1MB)
    if (data.length > 1024 * 1024) return;
    
    // Liberar espacio si es necesario
    _ensureCacheSpace(data.length);
    
    // Almacenar en caché
    _memoryCache[key] = data;
    _accessQueue.add(key);
  }
  
  void _ensureCacheSpace(int requiredBytes) {
    int currentSize = _calculateCacheSize();
    
    // Liberar espacio hasta tener suficiente para el nuevo item
    while (currentSize + requiredBytes > _maxMemoryCacheSize && _accessQueue.isNotEmpty) {
      final oldestKey = _accessQueue.removeFirst();
      final removedSize = _memoryCache[oldestKey]?.length ?? 0;
      _memoryCache.remove(oldestKey);
      currentSize -= removedSize;
    }
  }
  
  // Limpia la caché cuando la app va a segundo plano
  void onAppBackground() {
    _memoryCache.clear();
    _accessQueue.clear();
  }
}
```

### Lazy Loading & View Recycling
```dart
class OptimizedFileList extends StatelessWidget {
  final List<FileEntity> files;
  
  const OptimizedFileList({Key? key, required this.files}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // Renderizar solo los elementos visibles
      itemCount: files.length,
      // Cargar archivos adicionales solo cuando se necesiten
      cacheExtent: 500, // Precarga para scroll suave
      itemBuilder: (context, index) {
        // Devolver widget reutilizable
        return FileListItem(
          key: ValueKey(files[index].id), // Ayuda al framework a reciclar widgets
          file: files[index],
          // Solo cargar vista previa para archivos visibles
          loadPreview: false, // Se activará con IntersectionObserver
        );
      },
    );
  }
}

// Extensión de ListView que libera memoria cuando desaparece de la pantalla
class AutoDisposingListView extends StatefulWidget {
  // Implementación que detecta cuando sale de la vista y libera recursos
}
```

### Imagen y Media Handling
```dart
class EfficientImageLoader extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  
  const EfficientImageLoader({
    Key? key, 
    required this.imageUrl, 
    required this.width, 
    required this.height,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      // Generar placeholder dimensionado correctamente
      placeholder: (context, url) => ColoredBox(
        color: Colors.grey.shade200,
        child: SizedBox(width: width, height: height),
      ),
      // Redimensionar imagen en servidor
      imageBuilder: (context, imageProvider) => Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Cargar imágenes a demanda
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (frame == null) {
            return ColoredBox(
              color: Colors.grey.shade200,
              child: SizedBox(width: width, height: height),
            );
          }
          return child;
        },
      ),
      // Configuración avanzada para minimizar uso de memoria
      memCacheWidth: width.toInt() * 2, // Para pantallas de alta densidad
      memCacheHeight: height.toInt() * 2,
      // Evitar duplicados en caché
      cacheKey: '$imageUrl-${width.toInt()}x${height.toInt()}',
      // Usar formato optimizado
      imageRenderMethodForWeb: ImageRenderMethodForWeb.HtmlImage,
    );
  }
}
```

## 2. Optimización de CPU

### Computación Diferida
```dart
class DeferredComputationManager {
  final Queue<ComputeTask> _taskQueue = Queue();
  bool _isProcessing = false;
  
  // Programar tarea con prioridad
  void scheduleTask(Future<void> Function() task, TaskPriority priority) {
    _taskQueue.add(ComputeTask(task, priority));
    _taskQueue.toList().sort((a, b) => a.priority.index.compareTo(b.priority.index));
    
    if (!_isProcessing) {
      _processQueue();
    }
  }
  
  // Procesar cola respetando frame rate
  Future<void> _processQueue() async {
    if (_taskQueue.isEmpty) {
      _isProcessing = false;
      return;
    }
    
    _isProcessing = true;
    final task = _taskQueue.removeFirst();
    
    // Usar compute para tareas pesadas en thread separado
    if (task.priority == TaskPriority.heavy) {
      await compute(_isolatedTaskRunner, task.task);
    } else {
      // Tareas ligeras en microtasks para no bloquear UI
      await task.task();
    }
    
    // Programar siguiente tarea para el próximo frame
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _processQueue();
    });
  }
  
  // Ejecutar en aislamiento
  static Future<void> _isolatedTaskRunner(
    Future<void> Function() task
  ) async {
    return await task();
  }
  
  // Pausar tareas no críticas cuando la batería es baja
  void adjustForBatteryLevel(int batteryLevel) {
    if (batteryLevel < 20) {
      // Filtrar tareas no críticas
      _taskQueue.removeWhere(
        (task) => task.priority == TaskPriority.low
      );
    }
  }
}

enum TaskPriority { critical, high, normal, low, heavy }

class ComputeTask {
  final Future<void> Function() task;
  final TaskPriority priority;
  
  ComputeTask(this.task, this.priority);
}
```

### Throttling y Debouncing
```dart
class ResourceEfficientInput extends StatefulWidget {
  final Function(String) onSearch;
  
  const ResourceEfficientInput({Key? key, required this.onSearch}) : super(key: key);
  
  @override
  _ResourceEfficientInputState createState() => _ResourceEfficientInputState();
}

class _ResourceEfficientInputState extends State<ResourceEfficientInput> {
  Timer? _debounceTimer;
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  void _onTextChanged(String text) {
    // Cancelar timer anterior
    _debounceTimer?.cancel();
    
    // Esperar 300ms de inactividad antes de ejecutar búsqueda
    _debounceTimer = Timer(Duration(milliseconds: 300), () {
      widget.onSearch(text);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: _onTextChanged,
      decoration: InputDecoration(
        hintText: 'Buscar...',
      ),
    );
  }
}
```

### Event Coalescing
```dart
class OptimizedSyncQueue {
  final Map<String, SyncOperation> _pendingOperations = {};
  Timer? _processingTimer;
  
  void scheduleFileUpload(String fileId, List<int> data) {
    // Reemplazar operación previa sobre el mismo archivo
    _pendingOperations[fileId] = SyncOperation(
      type: OperationType.upload,
      resourceId: fileId,
      data: data,
    );
    
    _scheduleProcessing();
  }
  
  void scheduleFileUpdate(String fileId, List<int> data) {
    // Si ya hay un upload pendiente para este archivo, no necesitamos una actualización
    if (_pendingOperations[fileId]?.type == OperationType.upload) {
      // Actualizar datos en la operación existente
      _pendingOperations[fileId]?.data = data;
      return;
    }
    
    _pendingOperations[fileId] = SyncOperation(
      type: OperationType.update,
      resourceId: fileId,
      data: data,
    );
    
    _scheduleProcessing();
  }
  
  void _scheduleProcessing() {
    _processingTimer?.cancel();
    // Procesar cada 5 segundos o cuando acumule 10 operaciones
    if (_pendingOperations.length >= 10) {
      _processOperations();
    } else {
      _processingTimer = Timer(const Duration(seconds: 5), _processOperations);
    }
  }
  
  Future<void> _processOperations() async {
    final operations = _pendingOperations.values.toList();
    _pendingOperations.clear();
    
    // Agrupar operaciones por tipo
    final uploads = operations.where((op) => op.type == OperationType.upload);
    final updates = operations.where((op) => op.type == OperationType.update);
    
    // Procesar en batch para minimizar sobrecarga de red
    await _processUploadBatch(uploads.toList());
    await _processUpdateBatch(updates.toList());
  }
}
```

## 3. Optimización de Batería

### Sync Adaptativo
```dart
class BatteryAwareSyncStrategy {
  final BatteryInfo _batteryInfo;
  final NetworkInfo _networkInfo;
  
  BatteryAwareSyncStrategy(this._batteryInfo, this._networkInfo);
  
  Future<SyncConfig> determineSyncStrategy() async {
    final batteryLevel = await _batteryInfo.getBatteryLevel();
    final isCharging = await _batteryInfo.isCharging();
    final connectionType = await _networkInfo.getConnectionType();
    
    // Estrategia basada en condiciones actuales
    if (isCharging) {
      // Dispositivo cargando, podemos ser más agresivos
      return SyncConfig(
        syncInterval: Duration(minutes: 15),
        enableBackgroundSync: true,
        downloadThumbnails: true,
        preloadDepth: 2, // Precargar dos niveles de carpetas
        maxConcurrentOperations: 3,
      );
    } else if (batteryLevel > 50 && connectionType == ConnectionType.wifi) {
      // Batería decente y WiFi
      return SyncConfig(
        syncInterval: Duration(minutes: 30),
        enableBackgroundSync: true,
        downloadThumbnails: true,
        preloadDepth: 1,
        maxConcurrentOperations: 2,
      );
    } else if (batteryLevel > 20) {
      // Batería media
      return SyncConfig(
        syncInterval: Duration(hours: 1),
        enableBackgroundSync: false,
        downloadThumbnails: false,
        preloadDepth: 0,
        maxConcurrentOperations: 1,
      );
    } else {
      // Modo de ahorro extremo
      return SyncConfig(
        syncInterval: Duration(hours: 3),
        enableBackgroundSync: false,
        downloadThumbnails: false,
        preloadDepth: 0,
        maxConcurrentOperations: 1,
        syncOnlyOnWifi: true,
        syncOnlyWhenCharging: true,
      );
    }
  }
}
```

### Websocket y Push Notifications
```dart
class EfficientRealtimeManager {
  StreamSubscription? _websocketSubscription;
  final BatteryInfo _batteryInfo;
  
  EfficientRealtimeManager(this._batteryInfo);
  
  Future<void> initialize() async {
    await _configurePushNotifications();
    await _configureWebsocket();
    
    // Escuchar cambios de batería
    _batteryInfo.onBatteryLevelChanged.listen(_adjustRealtimeStrategy);
  }
  
  Future<void> _configureWebsocket() async {
    final batteryLevel = await _batteryInfo.getBatteryLevel();
    
    if (batteryLevel < 15) {
      // Usar solo push notifications en batería crítica
      await _disconnectWebsocket();
      return;
    }
    
    // Configurar reconexión exponencial
    final options = WebSocketOptions(
      reconnectInterval: Duration(seconds: 5),
      maxReconnectAttempts: 5,
      pingInterval: Duration(seconds: 30),
    );
    
    // Iniciar websocket en modo eficiente
    _websocketSubscription = WebSocketManager.connect(
      'wss://oxicloud.example.com/ws',
      options: options,
    ).listen(_handleRealtimeUpdate);
  }
  
  void _adjustRealtimeStrategy(int batteryLevel) {
    if (batteryLevel < 15 && _websocketSubscription != null) {
      // Desconectar websocket en batería baja
      _disconnectWebsocket();
    } else if (batteryLevel >= 15 && _websocketSubscription == null) {
      // Reconectar cuando la batería se recupere
      _configureWebsocket();
    }
  }
  
  Future<void> _disconnectWebsocket() async {
    await _websocketSubscription?.cancel();
    _websocketSubscription = null;
  }
  
  Future<void> _configurePushNotifications() async {
    // Configurar Firebase Messaging con mensajes de prioridad baja
    // para preservar batería en notificaciones no urgentes
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false, 
      badge: true, 
      sound: false,
    );
  }
}
```

### Suspensión de Procesos
```dart
class BackgroundTaskManager {
  bool _isAppInForeground = true;
  final List<BackgroundProcess> _processes = [];
  
  void registerProcess(BackgroundProcess process) {
    _processes.add(process);
    
    if (!_isAppInForeground) {
      process.pause();
    }
  }
  
  void onAppBackground() {
    _isAppInForeground = false;
    
    // Suspender procesos no críticos
    for (final process in _processes) {
      if (process.priority != ProcessPriority.critical) {
        process.pause();
      } else {
        // Reducir frecuencia de procesos críticos
        process.reducePriority();
      }
    }
  }
  
  void onAppForeground() {
    _isAppInForeground = true;
    
    // Reanudar procesos
    for (final process in _processes) {
      process.resume();
    }
  }
}

class BackgroundProcess {
  final ProcessPriority priority;
  bool _isRunning = true;
  
  BackgroundProcess({this.priority = ProcessPriority.normal});
  
  void pause() {
    _isRunning = false;
    // Lógica para detener timers, streams, etc.
  }
  
  void resume() {
    _isRunning = true;
    // Lógica para reiniciar proceso
  }
  
  void reducePriority() {
    // Reducir frecuencia o intensidad
  }
}

enum ProcessPriority { critical, normal, low }
```

## 4. Optimización de Red y Latencia

### Transferencias Delta
```dart
class DeltaSyncManager {
  final FileHashRepository _hashRepository;
  final FileChunkRepository _chunkRepository;
  
  DeltaSyncManager(this._hashRepository, this._chunkRepository);
  
  Future<void> uploadFile(File file) async {
    final fileId = path.basename(file.path);
    
    // 1. Verificar si el archivo ya existe en el servidor
    final remoteHashes = await _hashRepository.getFileHashes(fileId);
    if (remoteHashes == null) {
      // Archivo nuevo, subir completo
      await _uploadEntireFile(file);
      return;
    }
    
    // 2. Calcular hashes locales en bloques de 1MB
    final localHashes = await _calculateFileHashes(file);
    
    // 3. Encontrar bloques diferentes
    final chunksToUpload = _identifyChangedChunks(localHashes, remoteHashes);
    
    // 4. Subir solo chunks modificados
    if (chunksToUpload.isEmpty) {
      debugPrint('Archivo idéntico, no necesita sincronización');
      return;
    }
    
    // 5. Subir solo los chunks modificados
    for (final chunk in chunksToUpload) {
      final chunkData = await _readChunkData(file, chunk.offset, chunk.size);
      await _chunkRepository.uploadChunk(fileId, chunk.index, chunkData);
    }
    
    // 6. Instruir al servidor para reconstruir el archivo
    await _chunkRepository.reconstructFile(fileId, localHashes);
  }
  
  Future<List<FileHash>> _calculateFileHashes(File file) async {
    final hashes = <FileHash>[];
    final fileSize = await file.length();
    final chunkSize = 1024 * 1024; // 1MB chunks
    
    for (var offset = 0; offset < fileSize; offset += chunkSize) {
      final size = min(chunkSize, fileSize - offset);
      final chunkData = await _readChunkData(file, offset, size);
      
      // Calcular hash de chunk
      final hash = await compute(_calculateSHA256, chunkData);
      
      hashes.add(FileHash(
        index: offset ~/ chunkSize,
        offset: offset,
        size: size,
        hash: hash,
      ));
    }
    
    return hashes;
  }
  
  List<FileHash> _identifyChangedChunks(
    List<FileHash> localHashes, 
    List<FileHash> remoteHashes
  ) {
    final changedChunks = <FileHash>[];
    
    for (final localHash in localHashes) {
      final remoteHash = remoteHashes.firstWhere(
        (h) => h.index == localHash.index,
        orElse: () => FileHash(index: -1, offset: 0, size: 0, hash: ''),
      );
      
      if (remoteHash.index == -1 || remoteHash.hash != localHash.hash) {
        changedChunks.add(localHash);
      }
    }
    
    return changedChunks;
  }
  
  static String _calculateSHA256(List<int> data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }
}
```

### Compresión Adaptativa
```dart
class AdaptiveCompressionService {
  final NetworkInfo _networkInfo;
  
  AdaptiveCompressionService(this._networkInfo);
  
  Future<List<int>> compressData(List<int> data, FileType fileType) async {
    final connectionType = await _networkInfo.getConnectionType();
    final connectionSpeed = await _networkInfo.getConnectionSpeed();
    
    // Ya comprimido o muy pequeño, no comprimir
    if (_isAlreadyCompressed(fileType) || data.length < 10 * 1024) {
      return data;
    }
    
    // Elegir nivel de compresión basado en la red
    int compressionLevel;
    
    if (connectionType == ConnectionType.wifi && connectionSpeed > 5) {
      // WiFi rápido: compresión ligera
      compressionLevel = 1;
    } else if (connectionType == ConnectionType.mobile && connectionSpeed > 1) {
      // Mobile decente: comprensión media
      compressionLevel = 6;
    } else {
      // Conexión lenta: compresión máxima
      compressionLevel = 9;
    }
    
    // Usar compute para no bloquear el hilo principal
    return compute(_compressDataWithLevel, 
      CompressionTask(data, compressionLevel, fileType)
    );
  }
  
  bool _isAlreadyCompressed(FileType fileType) {
    return fileType == FileType.jpeg || 
           fileType == FileType.png ||
           fileType == FileType.mp3 || 
           fileType == FileType.mp4 ||
           fileType == FileType.zip;
  }
  
  static List<int> _compressDataWithLevel(CompressionTask task) {
    // Usar algoritmo apropiado según tipo de archivo
    if (task.fileType == FileType.text || task.fileType == FileType.json) {
      return gzip.encode(task.data, level: task.level);
    } else {
      // Para archivos binarios, usar otro algoritmo
      return ZLibEncoder(level: task.level).encode(task.data);
    }
  }
}

class CompressionTask {
  final List<int> data;
  final int level;
  final FileType fileType;
  
  CompressionTask(this.data, this.level, this.fileType);
}
```

### HTTP Optimizations
```dart
class OptimizedHttpClient {
  late final Dio _dio;
  final TokenManager _tokenManager;
  final ConnectivityService _connectivityService;
  
  OptimizedHttpClient(this._tokenManager, this._connectivityService) {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.oxicloud.example.com',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 30),
      // Habilitar compresión
      headers: {'Accept-Encoding': 'gzip, deflate'},
    ));
    
    _configureInterceptors();
  }
  
  void _configureInterceptors() {
    // Retry con backoff exponencial
    _dio.interceptors.add(RetryInterceptor(
      dio: _dio,
      logPrint: print,
      retries: 3,
      retryDelays: [
        Duration(milliseconds: 500),
        Duration(seconds: 1),
        Duration(seconds: 3),
      ],
    ));
    
    // Cache HTTP inteligente
    _dio.interceptors.add(DioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(maxSize: 10 * 1024 * 1024), // 10MB
        policy: CachePolicy.refreshForceCache,
        hitCacheOnErrorExcept: [401, 403],
        maxStale: Duration(days: 7),
        priority: CachePriority.normal,
        cipher: null,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      ),
    ));
    
    // Adaptador de conexión
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final connectivityType = await _connectivityService.getConnectionType();
        
        // Ajustar timeouts según tipo de conexión
        if (connectivityType == ConnectionType.mobile) {
          options.connectTimeout = Duration(seconds: 20);
          options.receiveTimeout = Duration(seconds: 60);
          
          // Reducir tamaño de datos en conexión móvil
          if (!options.path.contains('essential')) {
            options.queryParameters['optimize'] = 'true';
            options.queryParameters['quality'] = 'medium';
          }
        }
        
        // Añadir token de auth
        final token = await _tokenManager.getToken();
        options.headers['Authorization'] = 'Bearer $token';
        
        handler.next(options);
      },
    ));
  }
  
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    return _dio.get(path, queryParameters: queryParams);
  }
  
  // Download con soporte para pausar/reanudar
  Future<void> downloadFile(
    String url, 
    String savePath, 
    ProgressCallback onProgress
  ) async {
    final connectivityType = await _connectivityService.getConnectionType();
    
    // Si existe parcial, intentar reanudar
    final File file = File(savePath);
    int startBytes = 0;
    
    if (await file.exists()) {
      startBytes = await file.length();
    }
    
    // En conexiones lentas, usar chunks pequeños
    int chunkSize = connectivityType == ConnectionType.wifi ? 
        512 * 1024 : 128 * 1024; // 512KB o 128KB
    
    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onProgress,
      options: Options(
        headers: {
          'Range': 'bytes=$startBytes-',
        },
      ),
    );
  }
}
```

## 5. Optimización de Almacenamiento

### Almacenamiento Inteligente
```dart
class SmartStorageManager {
  final Directory _cacheDir;
  final int _maxCacheSize;
  final Map<String, FileMetadata> _fileMetadata = {};
  
  SmartStorageManager(this._cacheDir, {int maxCacheMB = 100})
      : _maxCacheSize = maxCacheMB * 1024 * 1024;
  
  Future<void> initialize() async {
    // Cargar metadata de archivo de índice
    final metadataFile = File('${_cacheDir.path}/metadata.json');
    if (await metadataFile.exists()) {
      final content = await metadataFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      
      json.forEach((key, value) {
        _fileMetadata[key] = FileMetadata.fromJson(value);
      });
    }
    
    // Verificar tamaño actual y limpiar si es necesario
    await _cleanupIfNeeded();
  }
  
  Future<File> getCachedFile(String fileId) async {
    final file = File('${_cacheDir.path}/$fileId');
    
    if (await file.exists()) {
      // Actualizar último acceso
      _fileMetadata[fileId] = _fileMetadata[fileId]?.copyWith(
        lastAccessed: DateTime.now(),
        accessCount: (_fileMetadata[fileId]?.accessCount ?? 0) + 1,
      ) ?? FileMetadata(
        fileId: fileId,
        size: await file.length(),
        lastAccessed: DateTime.now(),
        accessCount: 1,
      );
      
      // Guardar metadata actualizada
      await _saveMetadata();
      
      return file;
    }
    
    throw FileNotFoundException(fileId);
  }
  
  Future<File> cacheFile(String fileId, List<int> data) async {
    final file = File('${_cacheDir.path}/$fileId');
    
    // Asegurar espacio suficiente
    await _ensureSpace(data.length);
    
    // Escribir archivo
    await file.writeAsBytes(data, flush: true);
    
    // Actualizar metadata
    _fileMetadata[fileId] = FileMetadata(
      fileId: fileId,
      size: data.length,
      lastAccessed: DateTime.now(),
      accessCount: 1,
    );
    
    await _saveMetadata();
    
    return file;
  }
  
  Future<void> _ensureSpace(int requiredBytes) async {
    final currentSize = _calculateTotalSize();
    
    if (currentSize + requiredBytes <= _maxCacheSize) {
      return; // Hay espacio suficiente
    }
    
    // Ordenar archivos por score (combinación de tiempo y frecuencia)
    final files = _fileMetadata.values.toList()
      ..sort((a, b) => a.getCacheScore().compareTo(b.getCacheScore()));
    
    int freedSpace = 0;
    int index = 0;
    
    // Eliminar archivos hasta tener espacio suficiente
    while (freedSpace < requiredBytes && index < files.length) {
      final metadata = files[index];
      final file = File('${_cacheDir.path}/${metadata.fileId}');
      
      if (await file.exists()) {
        final size = metadata.size;
        await file.delete();
        _fileMetadata.remove(metadata.fileId);
        freedSpace += size;
      }
      
      index++;
    }
    
    await _saveMetadata();
  }
  
  Future<void> _cleanupIfNeeded() async {
    final totalSize = _calculateTotalSize();
    
    // Si excedemos 90% del límite, limpiar
    if (totalSize > _maxCacheSize * 0.9) {
      await _ensureSpace(totalSize - (_maxCacheSize * 0.7).toInt());
    }
  }
  
  int _calculateTotalSize() {
    return _fileMetadata.values
        .fold(0, (sum, metadata) => sum + metadata.size);
  }
  
  Future<void> _saveMetadata() async {
    final metadataFile = File('${_cacheDir.path}/metadata.json');
    final Map<String, dynamic> json = {};
    
    _fileMetadata.forEach((key, value) {
      json[key] = value.toJson();
    });
    
    await metadataFile.writeAsString(jsonEncode(json));
  }
}

class FileMetadata {
  final String fileId;
  final int size;
  final DateTime lastAccessed;
  final int accessCount;
  
  FileMetadata({
    required this.fileId,
    required this.size,
    required this.lastAccessed,
    required this.accessCount,
  });
  
  // Score para determinar qué archivos eliminar primero
  // Mayor valor = más probable que se elimine
  double getCacheScore() {
    final daysOld = DateTime.now().difference(lastAccessed).inHours / 24;
    // Fórmula que balancea frecuencia y tiempo
    return daysOld / (accessCount * 0.5);
  }
  
  FileMetadata copyWith({
    String? fileId,
    int? size,
    DateTime? lastAccessed,
    int? accessCount,
  }) {
    return FileMetadata(
      fileId: fileId ?? this.fileId,
      size: size ?? this.size,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      accessCount: accessCount ?? this.accessCount,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'fileId': fileId,
      'size': size,
      'lastAccessed': lastAccessed.toIso8601String(),
      'accessCount': accessCount,
    };
  }
  
  factory FileMetadata.fromJson(Map<String, dynamic> json) {
    return FileMetadata(
      fileId: json['fileId'],
      size: json['size'],
      lastAccessed: DateTime.parse(json['lastAccessed']),
      accessCount: json['accessCount'],
    );
  }
}
```

### Compresión de Base de Datos
```dart
class CompressedDBProvider {
  late final Database _db;
  final Uint8List _encryptionKey;
  
  CompressedDBProvider(this._encryptionKey);
  
  Future<void> initialize() async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = '${dbPath.path}/oxicloud.db';
    
    // Opciones optimizadas
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      singleInstance: true,
      
      // Optimizaciones críticas
      readOnly: false,
      // Solo en caché durante operaciones
      inMemory: false,
      // Reducir frecuencia de sync
      synchronousMode: SynchronousMode.OFF,
      // Compresión de datos
      compressionAlgorithm: CompressionAlgorithm.zlib,
      // Cifrado con SQLCipher
      password: base64Encode(_encryptionKey),
    );
  }
  
  // Método batch optimizado para inserción de muchos ítems
  Future<void> batchInsertFiles(List<FileEntity> files) async {
    // Usar transacción para acelerar
    await _db.transaction((txn) async {
      final batch = txn.batch();
      
      for (final file in files) {
        batch.insert(
          'files',
          _fileToMap(file),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      await batch.commit(noResult: true);
    });
  }
  
  // Optimizar consultas con índices
  Future<List<FileEntity>> searchFiles(String query) async {
    final results = await _db.query(
      'files',
      where: 'name LIKE ? OR path LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      // Usar índice para búsqueda rápida
      indexedBy: 'idx_files_name_path',
      // Limitar resultados para rendimiento
      limit: 100,
    );
    
    return results.map(_mapToFile).toList();
  }
  
  // Compactar periódicamente para ahorrar espacio
  Future<void> optimizeStorage() async {
    // Vacuum compacta la base de datos
    await _db.execute('VACUUM');
    
    // Análisis para actualizar estadísticas y mejorar rendimiento
    await _db.execute('ANALYZE');
  }
}
```

## 6. Optimización de UI y Experiencia de Usuario

### Renderizado Eficiente
```dart
class EfficientListView extends StatelessWidget {
  final List<dynamic> items;
  final IndexedWidgetBuilder itemBuilder;
  
  const EfficientListView({
    Key? key,
    required this.items,
    required this.itemBuilder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Para pequeñas cantidades, ListView normal
    if (items.length < 100) {
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: itemBuilder,
      );
    }
    
    // Para grandes cantidades, ListView con optimizaciones
    return ListView.builder(
      // Construir solo los elementos visibles
      itemCount: items.length,
      // Aumentar caché para scroll suave
      cacheExtent: 1000,
      // Eliminar elementos fuera de la vista
      addAutomaticKeepAlives: false,
      // Eliminar repintados cuando no es necesario
      addRepaintBoundaries: true,
      // Tamaño promedio para elementos para optimizar scroll
      itemExtent: 72.0,
      // Construir items 
      itemBuilder: itemBuilder,
    );
  }
}
```

### Multithreading para UI Responsive
```dart
class ResponsiveUIManager {
  // Ejecutar tareas pesadas en un isolate
  Future<List<T>> runHeavyComputation<T, P>(
    ComputeCallback<P, List<T>> callback,
    P param,
  ) {
    return compute(callback, param);
  }
  
  // Generar thumbnails sin bloquear UI
  Future<Uint8List> generateThumbnail(String filePath) async {
    return compute(_generateThumbnailIsolate, filePath);
  }
  
  // Batch processing para operaciones múltiples
  Future<List<FileEntity>> processFiles(List<String> filePaths) async {
    // Dividir tareas en chunks para mejor respuesta
    final results = <FileEntity>[];
    final chunks = _splitIntoChunks(filePaths, 10);
    
    for (final chunk in chunks) {
      // Procesar en paralelo pero mantener UI responsive
      final chunkResults = await compute(_processFilesIsolate, chunk);
      results.addAll(chunkResults);
      
      // Permitir que la UI responda entre chunks
      await Future.delayed(Duration.zero);
    }
    
    return results;
  }
  
  List<List<T>> _splitIntoChunks<T>(List<T> items, int chunkSize) {
    final result = <List<T>>[];
    for (var i = 0; i < items.length; i += chunkSize) {
      result.add(
        items.sublist(i, min(i + chunkSize, items.length)),
      );
    }
    return result;
  }
  
  static Uint8List _generateThumbnailIsolate(String filePath) {
    // Implementación de generación de thumbnail
    // ...
    return Uint8List(0);
  }
  
  static List<FileEntity> _processFilesIsolate(List<String> filePaths) {
    // Procesamiento por lote
    // ...
    return [];
  }
}
```

## 7. Monitoreo y Optimización Continua

### Métricas de Rendimiento
```dart
class PerformanceMonitor {
  final Map<String, List<PerformanceMetric>> _metrics = {};
  
  void startMeasurement(String operationName) {
    if (!_metrics.containsKey(operationName)) {
      _metrics[operationName] = [];
    }
    
    _metrics[operationName]!.add(PerformanceMetric(
      startTime: DateTime.now(),
    ));
  }
  
  void endMeasurement(String operationName, {int? dataSize}) {
    if (!_metrics.containsKey(operationName) || _metrics[operationName]!.isEmpty) {
      return;
    }
    
    final metric = _metrics[operationName]!.last;
    metric.endTime = DateTime.now();
    metric.dataSize = dataSize;
  }
  
  Map<String, PerformanceSummary> getPerformanceSummary() {
    final summary = <String, PerformanceSummary>{};
    
    _metrics.forEach((operation, metrics) {
      final validMetrics = metrics.where((m) => m.endTime != null).toList();
      
      if (validMetrics.isEmpty) return;
      
      final durations = validMetrics
          .map((m) => m.endTime!.difference(m.startTime).inMilliseconds)
          .toList();
      
      summary[operation] = PerformanceSummary(
        averageDuration: durations.average(),
        minDuration: durations.min(),
        maxDuration: durations.max(),
        count: validMetrics.length,
        // Calcular throughput en MB/s para operaciones con tamaño
        throughput: _calculateThroughput(validMetrics),
      );
    });
    
    return summary;
  }
  
  double _calculateThroughput(List<PerformanceMetric> metrics) {
    final metricsWithSize = metrics.where((m) => 
      m.endTime != null && m.dataSize != null
    ).toList();
    
    if (metricsWithSize.isEmpty) return 0;
    
    double totalMB = 0;
    double totalSeconds = 0;
    
    for (final metric in metricsWithSize) {
      final durationSec = metric.endTime!.difference(metric.startTime).inMilliseconds / 1000;
      final sizeMB = (metric.dataSize ?? 0) / (1024 * 1024);
      
      totalMB += sizeMB;
      totalSeconds += durationSec;
    }
    
    return totalSeconds > 0 ? totalMB / totalSeconds : 0;
  }
  
  void logPerformance() {
    final summary = getPerformanceSummary();
    
    summary.forEach((operation, metrics) {
      debugPrint('$operation: avg=${metrics.averageDuration.toStringAsFixed(2)}ms, '
          'min=${metrics.minDuration}ms, max=${metrics.maxDuration}ms, '
          'count=${metrics.count}, throughput=${metrics.throughput.toStringAsFixed(2)} MB/s');
    });
  }
  
  // Alertar si el rendimiento cae por debajo de umbrales
  void checkForPerformanceIssues() {
    final summary = getPerformanceSummary();
    
    summary.forEach((operation, metrics) {
      if (operation == 'fileDownload' && metrics.throughput < 0.5) {
        debugPrint('WARNING: File download throughput is very low: ${metrics.throughput.toStringAsFixed(2)} MB/s');
      }
      
      if (operation == 'uiRendering' && metrics.averageDuration > 16) {
        debugPrint('WARNING: UI rendering is exceeding 16ms, may cause jank');
      }
    });
  }
}

class PerformanceMetric {
  final DateTime startTime;
  DateTime? endTime;
  int? dataSize; // en bytes
  
  PerformanceMetric({required this.startTime});
}

class PerformanceSummary {
  final double averageDuration;
  final int minDuration;
  final int maxDuration;
  final int count;
  final double throughput; // MB/s
  
  PerformanceSummary({
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.count,
    required this.throughput,
  });
}
```

### Resource Monitoring
```dart
class ResourceMonitor {
  final StreamController<ResourceSnapshot> _snapshotController = 
    StreamController<ResourceSnapshot>.broadcast();
  
  Stream<ResourceSnapshot> get snapshotStream => _snapshotController.stream;
  Timer? _monitorTimer;
  
  void startMonitoring({Duration interval = const Duration(seconds: 30)}) {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(interval, (_) => _captureSnapshot());
  }
  
  Future<void> _captureSnapshot() async {
    try {
      final memoryInfo = await _getMemoryInfo();
      final batteryInfo = await _getBatteryInfo();
      final storageInfo = await _getStorageInfo();
      final cpuInfo = await _getCpuInfo();
      
      final snapshot = ResourceSnapshot(
        timestamp: DateTime.now(),
        memoryUsage: memoryInfo,
        batteryLevel: batteryInfo,
        storageUsage: storageInfo,
        cpuUsage: cpuInfo,
      );
      
      _snapshotController.add(snapshot);
      
      // Detectar problemas y ajustar comportamiento
      _analyzeAndOptimize(snapshot);
    } catch (e) {
      debugPrint('Error capturing resource snapshot: $e');
    }
  }
  
  void _analyzeAndOptimize(ResourceSnapshot snapshot) {
    // Optimizar según recursos actuales
    if (snapshot.memoryUsage.usedBytes > 150 * 1024 * 1024) {
      // Alto uso de memoria, reducir caché
      debugPrint('High memory usage detected, reducing cache size');
      ServiceLocator.get<CacheManager>().trimCache();
    }
    
    if (snapshot.batteryLevel < 20 && !snapshot.isCharging) {
      // Batería baja, activar modo de ahorro extremo
      debugPrint('Low battery detected, activating extreme power saving');
      ServiceLocator.get<PowerManager>().activateLowPowerMode();
    }
    
    if (snapshot.storageUsage.availableBytes < 100 * 1024 * 1024) {
      // Poco espacio disponible, limpiar caché
      debugPrint('Low storage detected, clearing non-essential cache');
      ServiceLocator.get<StorageManager>().clearNonEssentialCache();
    }
  }
  
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }
  
  // Implementar para cada plataforma
  Future<MemoryInfo> _getMemoryInfo() async {
    // Implementación específica por plataforma
    return MemoryInfo(
      totalBytes: 0,
      usedBytes: 0,
      appBytes: 0,
    );
  }
  
  Future<double> _getBatteryInfo() async {
    // Implementación específica por plataforma
    return 100.0;
  }
  
  Future<StorageInfo> _getStorageInfo() async {
    // Implementación específica por plataforma
    return StorageInfo(
      totalBytes: 0,
      availableBytes: 0,
      appCacheBytes: 0,
    );
  }
  
  Future<double> _getCpuInfo() async {
    // Implementación específica por plataforma
    return 0.0;
  }
}

class ResourceSnapshot {
  final DateTime timestamp;
  final MemoryInfo memoryUsage;
  final double batteryLevel;
  final StorageInfo storageUsage;
  final double cpuUsage;
  final bool isCharging;
  
  ResourceSnapshot({
    required this.timestamp,
    required this.memoryUsage,
    required this.batteryLevel,
    required this.storageUsage,
    required this.cpuUsage,
    this.isCharging = false,
  });
}

class MemoryInfo {
  final int totalBytes;
  final int usedBytes;
  final int appBytes;
  
  MemoryInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.appBytes,
  });
}

class StorageInfo {
  final int totalBytes;
  final int availableBytes;
  final int appCacheBytes;
  
  StorageInfo({
    required this.totalBytes,
    required this.availableBytes,
    required this.appCacheBytes,
  });
}
```

## 8. Manejo Inteligente de Recursos

### Context-Aware Resource Management
```dart
class ResourceManager {
  final DeviceCapabilityService _deviceCapability;
  final NetworkMonitor _networkMonitor;
  final BatteryMonitor _batteryMonitor;
  final AppStateMonitor _appStateMonitor;
  
  late final ResourceProfile _resourceProfile;
  final StreamController<ResourceProfile> _profileController = 
      StreamController<ResourceProfile>.broadcast();
  
  Stream<ResourceProfile> get profileStream => _profileController.stream;
  
  ResourceManager(
    this._deviceCapability,
    this._networkMonitor,
    this._batteryMonitor,
    this._appStateMonitor,
  ) {
    _initResourceProfile();
    _setupListeners();
  }
  
  Future<void> _initResourceProfile() async {
    // Determinar capacidades del dispositivo
    final totalRam = await _deviceCapability.getTotalRam();
    final cpuCores = await _deviceCapability.getCpuCores();
    final devicePerformance = await _deviceCapability.getDevicePerformanceClass();
    
    // Crear perfil base
    _resourceProfile = ResourceProfile(
      deviceClass: devicePerformance,
      maxCacheSize: _calculateMaxCache(totalRam),
      maxConcurrentOperations: _calculateMaxConcurrentOps(cpuCores),
      preloadDepth: devicePerformance == DeviceClass.high ? 2 : 1,
      thumbnailQuality: devicePerformance == DeviceClass.low ? 
          ThumbnailQuality.low : ThumbnailQuality.medium,
      usageMode: UsageMode.normal,
    );
    
    _profileController.add(_resourceProfile);
  }
  
  void _setupListeners() {
    // Reaccionar a cambios de conexión
    _networkMonitor.connectionStream.listen((connection) {
      _updateResourceProfile(networkType: connection);
    });
    
    // Reaccionar a cambios de batería
    _batteryMonitor.batteryStream.listen((battery) {
      _updateResourceProfile(
        batteryLevel: battery.level,
        isCharging: battery.isCharging,
      );
    });
    
    // Reaccionar a cambios de estado de la app
    _appStateMonitor.appStateStream.listen((state) {
      _updateResourceProfile(appState: state);
    });
  }
  
  void _updateResourceProfile({
    NetworkType? networkType,
    double? batteryLevel,
    bool? isCharging,
    AppState? appState,
  }) {
    // Usar valores actuales para parámetros no especificados
    networkType ??= _resourceProfile.networkType;
    batteryLevel ??= _resourceProfile.batteryLevel;
    isCharging ??= _resourceProfile.isCharging;
    appState ??= _resourceProfile.appState;
    
    // Determinar modo de uso
    UsageMode usageMode = _determineUsageMode(
      networkType, batteryLevel, isCharging, appState
    );
    
    // Crear nuevo perfil
    _resourceProfile = ResourceProfile(
      deviceClass: _resourceProfile.deviceClass,
      networkType: networkType,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      appState: appState,
      usageMode: usageMode,
      
      // Ajustar límites según el modo de uso
      maxCacheSize: _adjustCacheSize(usageMode),
      maxConcurrentOperations: _adjustConcurrentOps(usageMode),
      preloadDepth: _adjustPreloadDepth(usageMode),
      thumbnailQuality: _adjustThumbnailQuality(usageMode),
      syncInterval: _adjustSyncInterval(usageMode, networkType),
    );
    
    // Notificar a los listeners
    _profileController.add(_resourceProfile);
  }
  
  UsageMode _determineUsageMode(
    NetworkType networkType,
    double batteryLevel,
    bool isCharging,
    AppState appState,
  ) {
    // App en background: conservar recursos
    if (appState == AppState.background) {
      return UsageMode.minimal;
    }
    
    // Cargando: podemos ser menos conservadores
    if (isCharging) {
      if (networkType == NetworkType.wifi) {
        return UsageMode.performance;
      }
      return UsageMode.normal;
    }
    
    // Batería muy baja: modo de emergencia
    if (batteryLevel < 15) {
      return UsageMode.critical;
    }
    
    // Batería baja: conservar energía
    if (batteryLevel < 30) {
      return UsageMode.powersave;
    }
    
    // Conexión rápida: modo normal
    if (networkType == NetworkType.wifi || networkType == NetworkType.ethernet) {
      return UsageMode.normal;
    }
    
    // Datos móviles: ahorrar datos
    return UsageMode.datasave;
  }
  
  int _calculateMaxCache(int totalRam) {
    // Dispositivos con <2GB: máximo 50MB
    if (totalRam < 2 * 1024 * 1024 * 1024) {
      return 50 * 1024 * 1024;
    }
    // Dispositivos con <4GB: máximo 100MB
    else if (totalRam < 4 * 1024 * 1024 * 1024) {
      return 100 * 1024 * 1024;
    }
    // Dispositivos con >=4GB: máximo 200MB
    else {
      return 200 * 1024 * 1024;
    }
  }
  
  int _calculateMaxConcurrentOps(int cpuCores) {
    // Limitar operaciones concurrentes según núcleos
    return max(1, cpuCores ~/ 2);
  }
  
  int _adjustCacheSize(UsageMode mode) {
    final baseSize = _calculateMaxCache(_resourceProfile.deviceClass.recommendedRam);
    
    switch (mode) {
      case UsageMode.performance:
        return baseSize;
      case UsageMode.normal:
        return baseSize * 3 ~/ 4;
      case UsageMode.datasave:
        return baseSize ~/ 2;
      case UsageMode.powersave:
        return baseSize ~/ 3;
      case UsageMode.minimal:
        return baseSize ~/ 4;
      case UsageMode.critical:
        return baseSize ~/ 8;
    }
  }
  
  int _adjustConcurrentOps(UsageMode mode) {
    final baseConcurrency = _calculateMaxConcurrentOps(_resourceProfile.deviceClass.cpuCores);
    
    switch (mode) {
      case UsageMode.performance:
        return baseConcurrency;
      case UsageMode.normal:
        return max(1, baseConcurrency - 1);
      case UsageMode.datasave:
      case UsageMode.powersave:
        return 1;
      case UsageMode.minimal:
      case UsageMode.critical:
        return 1;
    }
  }
  
  int _adjustPreloadDepth(UsageMode mode) {
    switch (mode) {
      case UsageMode.performance:
        return 2;
      case UsageMode.normal:
        return 1;
      default:
        return 0;
    }
  }
  
  ThumbnailQuality _adjustThumbnailQuality(UsageMode mode) {
    switch (mode) {
      case UsageMode.performance:
        return ThumbnailQuality.high;
      case UsageMode.normal:
        return ThumbnailQuality.medium;
      default:
        return ThumbnailQuality.low;
    }
  }
  
  Duration _adjustSyncInterval(UsageMode mode, NetworkType network) {
    // Modo crítico: sync manual solamente
    if (mode == UsageMode.critical) {
      return Duration(hours: 24); // Prácticamente desactivado
    }
    
    // Ajustar intervalo según red y modo
    if (network == NetworkType.wifi) {
      switch (mode) {
        case UsageMode.performance:
          return Duration(minutes: 15);
        case UsageMode.normal:
          return Duration(minutes: 30);
        case UsageMode.datasave:
        case UsageMode.powersave:
          return Duration(hours: 1);
        case UsageMode.minimal:
          return Duration(hours: 2);
        default:
          return Duration(hours: 12);
      }
    } else {
      switch (mode) {
        case UsageMode.performance:
          return Duration(minutes: 30);
        case UsageMode.normal:
          return Duration(hours: 1);
        case UsageMode.datasave:
          return Duration(hours: 3);
        case UsageMode.powersave:
        case UsageMode.minimal:
          return Duration(hours: 6);
        default:
          return Duration(hours: 12);
      }
    }
  }
}

enum DeviceClass { low, medium, high }
enum NetworkType { none, mobile, wifi, ethernet }
enum AppState { foreground, background }
enum UsageMode { performance, normal, datasave, powersave, minimal, critical }
enum ThumbnailQuality { low, medium, high }

class ResourceProfile {
  final DeviceClass deviceClass;
  final NetworkType networkType;
  final double batteryLevel;
  final bool isCharging;
  final AppState appState;
  final UsageMode usageMode;
  
  final int maxCacheSize;
  final int maxConcurrentOperations;
  final int preloadDepth;
  final ThumbnailQuality thumbnailQuality;
  final Duration syncInterval;
  
  ResourceProfile({
    this.deviceClass = DeviceClass.medium,
    this.networkType = NetworkType.wifi,
    this.batteryLevel = 100.0,
    this.isCharging = false,
    this.appState = AppState.foreground,
    this.usageMode = UsageMode.normal,
    this.maxCacheSize = 100 * 1024 * 1024,
    this.maxConcurrentOperations = 2,
    this.preloadDepth = 1,
    this.thumbnailQuality = ThumbnailQuality.medium,
    this.syncInterval = Duration(minutes: 30),
  });
}
```

Este documento proporciona implementaciones detalladas y específicas para cada área de optimización. Implementando estas estrategias, tu cliente de escritorio OxiCloud funcionará eficientemente en todas las plataformas, minimizando el consumo de recursos mientras mantiene una experiencia de usuario fluida.