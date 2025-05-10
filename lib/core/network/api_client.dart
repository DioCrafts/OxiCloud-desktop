import 'package:dio/dio.dart';
import 'package:oxicloud_desktop/core/config/app_config.dart';
import 'dart:async';

class ApiClient {
  final AppConfig _config;
  late final Dio _dio;
  
  ApiClient(this._config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.apiUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // TODO: Agregar token de autenticación
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          // TODO: Manejar errores específicos
          return handler.next(e);
        },
      ),
    );
  }
  
  // Métodos HTTP base
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Método para subida de archivos
  Future<Response> uploadFile(
    String path,
    String filePath, {
    ProgressCallback? onProgress,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        if (extraData != null) ...extraData,
      });
      
      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Método para descarga de archivos
  Future<Response> downloadFile(
    String path,
    String savePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      return await _dio.download(
        path,
        savePath,
        onReceiveProgress: onProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('La conexión ha expirado');
      case DioExceptionType.badResponse:
        return _handleResponseError(e.response);
      case DioExceptionType.cancel:
        return Exception('La petición fue cancelada');
      default:
        return Exception('Error de conexión');
    }
  }
  
  Exception _handleResponseError(Response? response) {
    if (response == null) {
      return Exception('Error desconocido');
    }
    
    switch (response.statusCode) {
      case 400:
        return Exception('Petición inválida');
      case 401:
        return Exception('No autorizado');
      case 403:
        return Exception('Acceso denegado');
      case 404:
        return Exception('Recurso no encontrado');
      case 500:
        return Exception('Error del servidor');
      default:
        return Exception('Error ${response.statusCode}');
    }
  }
} 