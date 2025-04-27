import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/user.dart';
import '../../../domain/ports/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._dio, this._prefs);

  @override
  Future<Either<String, User>> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });

      final user = User.fromJson(response.data);
      await _prefs.setString('token', response.data['token']);
      _dio.options.headers['Authorization'] = 'Bearer ${response.data['token']}';
      
      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, User>> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });

      final user = User.fromJson(response.data);
      return Right(user);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _prefs.remove('token');
      _dio.options.headers.remove('Authorization');
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, User>> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return Right(User.fromJson(response.data));
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await _dio.post('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> requestPasswordReset(String email) async {
    try {
      await _dio.post('/auth/forgot-password', data: {
        'email': email,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> verifyEmail(String token) async {
    try {
      await _dio.post('/auth/verify-email', data: {
        'token': token,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<Either<String, void>> resendVerificationEmail(String email) async {
    try {
      await _dio.post('/auth/resend-verification', data: {
        'email': email,
      });
      return const Right(null);
    } on DioException catch (e) {
      return Left(e.response?.data['message'] ?? 'Error de conexión');
    }
  }
} 