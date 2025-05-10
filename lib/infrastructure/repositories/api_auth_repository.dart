import 'package:oxicloud_desktop/core/network/api_client.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'current_user';

  ApiAuthRepository(this._apiClient, this._prefs);

  @override
  Future<User> login(String username, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['token'] as String;
      final user = User.fromJson(response.data['user']);
      
      await _prefs.setString(_tokenKey, token);
      await _prefs.setString(_userKey, user.toJson().toString());
      
      return user;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_userKey);
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;

    try {
      await _apiClient.get('/auth/validate');
      return true;
    } catch (e) {
      await _prefs.remove(_tokenKey);
      await _prefs.remove(_userKey);
      return false;
    }
  }

  @override
  Future<User> register(String username, String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al registrar usuario: $e');
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final userJson = _prefs.getString(_userKey);
      if (userJson == null) return null;
      
      return User.fromJson(Map<String, dynamic>.from(
        Map<String, dynamic>.from(userJson as Map),
      ));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String> refreshToken() async {
    try {
      final response = await _apiClient.post('/auth/refresh');
      final token = response.data['token'] as String;
      await _prefs.setString(_tokenKey, token);
      return token;
    } catch (e) {
      throw Exception('Error al refrescar token: $e');
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      await _apiClient.post('/auth/reset-password-request', data: {
        'email': email,
      });
    } catch (e) {
      throw Exception('Error al solicitar restablecimiento de contraseña: $e');
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _apiClient.post('/auth/reset-password', data: {
        'token': token,
        'new_password': newPassword,
      });
    } catch (e) {
      throw Exception('Error al restablecer contraseña: $e');
    }
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.post('/auth/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } catch (e) {
      throw Exception('Error al cambiar contraseña: $e');
    }
  }

  @override
  Future<User> updateProfile(User user) async {
    try {
      final response = await _apiClient.put('/auth/profile', data: user.toJson());
      final updatedUser = User.fromJson(response.data);
      await _prefs.setString(_userKey, updatedUser.toJson().toString());
      return updatedUser;
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }
} 