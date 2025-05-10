import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? id;
  final String username;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;
  final List<String> roles;

  const User({
    this.id,
    required this.username,
    required this.email,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    required this.lastLogin,
    required this.isActive,
    required this.roles,
  });

  @override
  List<Object?> get props => [
    id,
    username,
    email,
    displayName,
    avatarUrl,
    createdAt,
    lastLogin,
    isActive,
    roles,
  ];

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? displayName,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
    List<String>? roles,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      roles: roles ?? this.roles,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      username: json['username'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastLogin: DateTime.parse(json['last_login'] as String),
      isActive: json['is_active'] as bool,
      roles: List<String>.from(json['roles'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin.toIso8601String(),
      'is_active': isActive,
      'roles': roles,
    };
  }
} 