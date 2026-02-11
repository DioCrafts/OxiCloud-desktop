import '../../core/entities/user.dart';
import '../datasources/rust_bridge_datasource.dart';

/// Mappers between Auth DTOs (data layer) and domain entities.
///
/// Centralizes conversion logic that was previously scattered
/// across repository implementations.
class AuthMapper {
  const AuthMapper._();

  /// Maps [ServerInfoDto] → domain [ServerInfo]
  static ServerInfo fromServerInfoDto(ServerInfoDto dto) {
    return ServerInfo(
      url: dto.url,
      version: dto.version,
      name: dto.name,
      webdavUrl: dto.webdavUrl,
      quotaTotal: dto.quotaTotal,
      quotaUsed: dto.quotaUsed,
      supportsDeltaSync: dto.supportsDeltaSync,
      supportsChunkedUpload: dto.supportsChunkedUpload,
    );
  }

  /// Maps [AuthResultDto] → domain [User]
  static User fromAuthResultDto(AuthResultDto dto, String serverUrl) {
    return User(
      id: dto.userId,
      username: dto.username,
      serverUrl: serverUrl,
      serverInfo: fromServerInfoDto(dto.serverInfo),
    );
  }

  /// Builds a [User] from [ServerInfoDto] and stored credentials.
  static User fromServerInfoDtoWithCredentials(
    ServerInfoDto dto, {
    required String username,
  }) {
    return User(
      id: 'current-user',
      username: username,
      serverUrl: dto.url,
      serverInfo: fromServerInfoDto(dto),
    );
  }
}
