import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';

import '../../domain/ports/auth_repository.dart';
import '../../domain/models/user.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._dio, this._prefs);

  @override
  Future<User> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      final user = User.fromJson(response.data);
      await _prefs.setString('token', user.token);
      return user;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _prefs.remove('token');
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      final token = _prefs.getString('token');
      if (token == null) {
        throw Exception('No hay sesión activa');
      }
      
      final response = await _dio.get('/auth/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener el usuario actual: $e');
    }
  }
} 