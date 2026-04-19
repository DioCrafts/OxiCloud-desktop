import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_tokens_entity.dart';
import '../dtos/auth/auth_dtos.dart';

class AuthMapper {
  AuthMapper._();

  static UserEntity userFromDto(UserResponseDto dto) {
    return UserEntity(
      id: dto.id,
      username: dto.username,
      email: dto.email,
      role: dto.role ?? 'user',
      storageQuotaBytes: dto.storageQuotaBytes,
      storageUsedBytes: dto.storageUsedBytes,
    );
  }

  static AuthTokens tokensFromDto(AuthResponseDto dto) {
    return AuthTokens(
      accessToken: dto.accessToken,
      refreshToken: dto.refreshToken,
      expiresIn: dto.expiresIn,
      issuedAt: DateTime.now(),
    );
  }

  static (UserEntity, AuthTokens) authResponseFromDto(AuthResponseDto dto) {
    return (userFromDto(dto.user), tokensFromDto(dto));
  }
}
