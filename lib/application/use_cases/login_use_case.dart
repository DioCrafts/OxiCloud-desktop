import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _authRepository;

  LoginUseCase(this._authRepository);

  Future<User> execute(String username, String password) async {
    // Validar credenciales
    if (username.isEmpty || password.isEmpty) {
      throw Exception('El nombre de usuario y la contraseña son requeridos');
    }

    // Intentar login
    try {
      final user = await _authRepository.login(username, password);
      return user;
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }
} 