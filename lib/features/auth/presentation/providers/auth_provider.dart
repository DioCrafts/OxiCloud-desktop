import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../domain/models/user.dart';
import '../../application/usecases/auth_usecase.dart';

@injectable
class AuthProvider with ChangeNotifier {
  final AuthUseCase _authUseCase;
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider(this._authUseCase);

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.login(username, password);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.register(username, email, password);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authUseCase.logout();
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _user = null;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> getCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    final result = await _authUseCase.getCurrentUser();
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (user) {
        _user = user;
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.changePassword(currentPassword, newPassword);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> requestPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.requestPasswordReset(email);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.resetPassword(token, newPassword);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> verifyEmail(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.verifyEmail(token);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authUseCase.resendVerificationEmail(email);
    
    result.fold(
      (error) {
        _error = error;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }
} 