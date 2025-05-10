import 'package:sqflite/sqflite.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';
import 'package:oxicloud_desktop/infrastructure/models/user_model.dart';
import '../database/database_helper.dart';

class LocalAuthRepository implements AuthRepository {
  final DatabaseHelper _dbHelper;

  LocalAuthRepository(this._dbHelper);

  @override
  Future<User> login(String username, String password) async {
    // La autenticación real se hace en el repositorio API
    throw UnimplementedError('El login debe realizarse a través del repositorio API');
  }

  @override
  Future<void> logout() async {
    try {
      await _dbHelper.deleteUser();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    // El token se maneja en el repositorio API
    throw UnimplementedError('El token debe obtenerse a través del repositorio API');
  }

  @override
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  @override
  Future<User> register(String username, String email, String password) async {
    // El registro real se hace en el repositorio API
    throw UnimplementedError('El registro debe realizarse a través del repositorio API');
  }

  @override
  Future<User?> getCurrentUser() async {
    final userModel = await getUser();
    return userModel?.toDomain();
  }

  @override
  Future<String> refreshToken() async {
    // El refresh token se maneja en el repositorio API
    throw UnimplementedError('El refresh token debe obtenerse a través del repositorio API');
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    throw UnimplementedError('El reset de contraseña debe realizarse a través del repositorio API');
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    throw UnimplementedError('El reset de contraseña debe realizarse a través del repositorio API');
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    throw UnimplementedError('El cambio de contraseña debe realizarse a través del repositorio API');
  }

  @override
  Future<User> updateProfile(User user) async {
    final userModel = UserModel.fromDomain(user);
    await updateUser(userModel);
    return user;
  }

  Future<void> saveUser(User user) async {
    final userModel = UserModel.fromDomain(user);
    await _dbHelper.insertUser(userModel);
  }

  Future<UserModel?> getUser() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<void> updateUser(UserModel user) async {
    final db = await _dbHelper.database;
    await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser() async {
    final db = await _dbHelper.database;
    await db.delete('users');
  }
} 