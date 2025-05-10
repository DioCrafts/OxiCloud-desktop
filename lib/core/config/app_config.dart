import 'package:shared_preferences/shared_preferences.dart';
import 'package:oxicloud_desktop/core/network/api_client.dart';

class AppConfig {
  static const String _apiUrlKey = 'api_url';
  static const String _defaultApiUrl = 'http://localhost:8080';
  
  late SharedPreferences _prefs;
  late ApiClient apiClient;
  String _apiUrl = _defaultApiUrl;
  
  String get apiUrl => _apiUrl;
  
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _apiUrl = _prefs.getString(_apiUrlKey) ?? _defaultApiUrl;
    apiClient = ApiClient(this);
  }
  
  Future<void> setApiUrl(String url) async {
    _apiUrl = url;
    await _prefs.setString(_apiUrlKey, url);
  }
  
  // Configuración de caché
  static const int fileCacheDuration = 60 * 60 * 24; // 24 horas
  static const int metadataCacheDuration = 60 * 5; // 5 minutos
  
  // Configuración de red
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
  
  // Configuración de archivos
  static const int maxFileSize = 1024 * 1024 * 1024; // 1 GB
  static const int chunkSize = 1024 * 1024; // 1 MB
  
  // Configuración de UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const Duration animationDuration = Duration(milliseconds: 300);
  
  // Configuración de seguridad
  static const int tokenExpirationTime = 60 * 60 * 24; // 24 horas
  static const int refreshTokenExpirationTime = 60 * 60 * 24 * 7; // 7 días
  
  // Configuración de sincronización
  static const int syncInterval = 60 * 5; // 5 minutos
  static const int maxRetryAttempts = 3;
  
  // Configuración de modo offline
  static const bool enableOfflineMode = true;
  static const int offlineCacheSize = 1024 * 1024 * 100; // 100 MB
} 