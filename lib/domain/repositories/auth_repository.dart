import 'package:oxicloud_desktop/domain/entities/user.dart';

abstract class AuthRepository {
  /// Inicia sesión con las credenciales proporcionadas
  Future<User> login(String username, String password);
  
  /// Cierra la sesión actual
  Future<void> logout();
  
  /// Obtiene el token de autenticación
  Future<String?> getToken();
  
  /// Obtiene el usuario actual
  Future<User?> getCurrentUser();
  
  /// Verifica si hay una sesión activa
  Future<bool> isAuthenticated();
  
  /// Refresca el token de autenticación
  Future<String> refreshToken();
  
  /// Registra un nuevo usuario
  Future<User> register(String username, String email, String password);
  
  /// Solicita restablecimiento de contraseña
  Future<void> requestPasswordReset(String email);
  
  /// Restablece la contraseña con el token proporcionado
  Future<void> resetPassword(String token, String newPassword);
  
  /// Actualiza el perfil del usuario
  Future<User> updateProfile(User user);
  
  /// Cambia la contraseña del usuario actual
  Future<void> changePassword(String currentPassword, String newPassword);
} 