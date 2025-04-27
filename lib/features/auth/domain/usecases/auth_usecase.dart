import 'package:injectable/injectable.dart';

import '../models/user.dart';
import '../ports/auth_repository.dart';
import '../../../../core/domain/usecase.dart';

@Injectable()
class AuthUseCase implements UseCase {
  final AuthRepository _repository;

  AuthUseCase(this._repository);

  Future<User> login(String email, String password) async {
    return await _repository.login(email, password);
  }

  Future<void> logout() async {
    await _repository.logout();
  }

  Future<User> getCurrentUser() async {
    return await _repository.getCurrentUser();
  }
} 