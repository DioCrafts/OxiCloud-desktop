import '../../core/auth/secure_storage.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../dtos/auth/auth_dtos.dart';
import '../mappers/auth_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remote;
  final SecureStorage _secureStorage;

  AuthRepositoryImpl({
    required AuthRemoteDatasource remote,
    required SecureStorage secureStorage,
  })  : _remote = remote,
        _secureStorage = secureStorage;

  @override
  Future<({bool adminExists, bool registrationEnabled})> getStatus() async {
    final dto = await _remote.getStatus();
    return (
      adminExists: dto.adminExists,
      registrationEnabled: dto.registrationEnabled,
    );
  }

  @override
  Future<(UserEntity, AuthTokens)?> setup({
    required String username,
    required String email,
    required String password,
  }) async {
    final dto = await _remote.setup(
      SetupAdminRequestDto(
        username: username,
        email: email,
        password: password,
      ),
    );
    final result = AuthMapper.authResponseFromDto(dto);
    await _persistTokens(result.$2, result.$1);
    return result;
  }

  @override
  Future<(UserEntity, AuthTokens)> login({
    required String username,
    required String password,
  }) async {
    final dto = await _remote.login(
      LoginRequestDto(username: username, password: password),
    );
    final result = AuthMapper.authResponseFromDto(dto);
    await _persistTokens(result.$2, result.$1);
    return result;
  }

  @override
  Future<(UserEntity, AuthTokens)> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final dto = await _remote.register(
      RegisterRequestDto(username: username, email: email, password: password),
    );
    final result = AuthMapper.authResponseFromDto(dto);
    await _persistTokens(result.$2, result.$1);
    return result;
  }

  @override
  Future<AuthTokens> refreshToken(String refreshToken) async {
    final dto = await _remote.refreshToken(
      RefreshTokenRequestDto(refreshToken: refreshToken),
    );
    final tokens = AuthMapper.tokensFromDto(dto);
    await _secureStorage.saveAccessToken(tokens.accessToken);
    await _secureStorage.saveRefreshToken(tokens.refreshToken);
    await _secureStorage.saveTokenExpiry(tokens.expiresAt);
    return tokens;
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    final dto = await _remote.getCurrentUser();
    return AuthMapper.userFromDto(dto);
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _remote.changePassword(
      ChangePasswordRequestDto(
        currentPassword: currentPassword,
        newPassword: newPassword,
      ),
    );
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _secureStorage.clearSession();
    }
  }

  Future<void> _persistTokens(AuthTokens tokens, UserEntity user) async {
    await _secureStorage.saveAccessToken(tokens.accessToken);
    await _secureStorage.saveRefreshToken(tokens.refreshToken);
    await _secureStorage.saveTokenExpiry(tokens.expiresAt);
    await _secureStorage.saveUserId(user.id);
  }
}
