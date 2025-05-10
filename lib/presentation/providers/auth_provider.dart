import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oxicloud_desktop/domain/entities/user.dart';
import 'package:oxicloud_desktop/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('Debe ser inicializado con una instancia de ApiAuthRepository');
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;
  
  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      final isAuthenticated = await _repository.isAuthenticated();
      if (isAuthenticated) {
        final user = await _repository.getCurrentUser();
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(username, password);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> logout() async {
    try {
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> updateProfile(User user) async {
    try {
      final updatedUser = await _repository.updateProfile(user);
      state = AsyncValue.data(updatedUser);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _repository.changePassword(currentPassword, newPassword);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
} 