import 'package:oxicloud_desktop/domain/entities/user.dart' as domain;

class UserModel {
  final int? id;
  final String username;
  final String email;
  final String password;
  final String? token;
  final String? refreshToken;
  final bool isLoggedIn;
  final DateTime? lastLogin;
  final List<String> roles;
  final String? avatar;
  final String? theme;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    this.token,
    this.refreshToken,
    required this.isLoggedIn,
    this.lastLogin,
    required this.roles,
    this.avatar,
    this.theme,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'token': token,
      'refreshToken': refreshToken,
      'isLoggedIn': isLoggedIn ? 1 : 0,
      'lastLogin': lastLogin?.toIso8601String(),
      'roles': roles.join(','),
      'avatar': avatar,
      'theme': theme,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      token: map['token'] as String?,
      refreshToken: map['refreshToken'] as String?,
      isLoggedIn: map['isLoggedIn'] == 1,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin'] as String) : null,
      roles: (map['roles'] as String).split(','),
      avatar: map['avatar'] as String?,
      theme: map['theme'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? password,
    String? token,
    String? refreshToken,
    bool? isLoggedIn,
    DateTime? lastLogin,
    List<String>? roles,
    String? avatar,
    String? theme,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastLogin: lastLogin ?? this.lastLogin,
      roles: roles ?? this.roles,
      avatar: avatar ?? this.avatar,
      theme: theme ?? this.theme,
    );
  }

  factory UserModel.fromDomain(domain.User user) {
    return UserModel(
      id: int.tryParse(user.id ?? ''),
      username: user.username,
      email: user.email,
      password: '',
      token: null,
      refreshToken: null,
      isLoggedIn: user.isActive,
      lastLogin: user.lastLogin,
      roles: user.roles,
      avatar: user.avatarUrl,
      theme: null,
    );
  }

  domain.User toDomain() {
    return domain.User(
      id: id?.toString(),
      username: username,
      email: email,
      displayName: null,
      avatarUrl: avatar,
      createdAt: DateTime.now(),
      lastLogin: lastLogin ?? DateTime.now(),
      isActive: isLoggedIn,
      roles: roles,
    );
  }
} 