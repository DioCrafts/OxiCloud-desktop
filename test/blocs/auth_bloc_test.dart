import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:oxicloud_app/core/entities/user.dart';
import 'package:oxicloud_app/core/repositories/auth_repository.dart';
import 'package:oxicloud_app/presentation/blocs/auth/auth_bloc.dart';

// Manual mock using mocktail
class MockAuthRepository extends Mock implements AuthRepository {}

class FakeAuthCredentials extends Fake implements AuthCredentials {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late AuthBloc authBloc;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredentials());
  });

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    final testUser = User(
      id: 'test-id',
      username: 'testuser',
      serverUrl: 'https://cloud.example.com',
      serverInfo: ServerInfo(
        url: 'https://cloud.example.com',
        version: '1.0.0',
        name: 'OxiCloud',
        webdavUrl: 'https://cloud.example.com/dav',
        quotaTotal: 10737418240, // 10GB
        quotaUsed: 0,
        supportsDeltaSync: false,
        supportsChunkedUpload: true,
      ),
    );

    group('CheckAuthStatus', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when user is logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => const Right<AuthFailure, bool>(true));
          when(() => mockAuthRepository.getCurrentUser())
              .thenAnswer((_) async => Right<AuthFailure, User?>(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(testUser),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when user is not logged in',
        build: () {
          when(() => mockAuthRepository.isLoggedIn())
              .thenAnswer((_) async => const Right<AuthFailure, bool>(false));
          when(() => mockAuthRepository.getStoredServerUrl())
              .thenAnswer((_) async => 'https://cloud.example.com');
          when(() => mockAuthRepository.getStoredUsername())
              .thenAnswer((_) async => 'lastuser');
          return authBloc;
        },
        act: (bloc) => bloc.add(const CheckAuthStatus()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(
            lastServerUrl: 'https://cloud.example.com',
            lastUsername: 'lastuser',
          ),
        ],
      );
    });

    group('LoginSubmitted', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthAuthenticated] when login succeeds',
        build: () {
          when(() => mockAuthRepository.login(any()))
              .thenAnswer((_) async => Right<AuthFailure, User>(testUser));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoginSubmitted(
          serverUrl: 'https://cloud.example.com',
          username: 'testuser',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(),
          AuthAuthenticated(testUser),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.login(any())).called(1);
        },
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when login fails with invalid credentials',
        build: () {
          when(() => mockAuthRepository.login(any()))
              .thenAnswer((_) async => const Left<AuthFailure, User>(InvalidCredentialsFailure()));
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoginSubmitted(
          serverUrl: 'https://cloud.example.com',
          username: 'testuser',
          password: 'wrongpassword',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message: 'Invalid username or password',
            type: AuthErrorType.invalidCredentials,
          ),
        ],
      );

      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthError] when server is unreachable',
        build: () {
          when(() => mockAuthRepository.login(any())).thenAnswer(
            (_) async => const Left<AuthFailure, User>(ServerUnreachableFailure('Connection refused')),
          );
          return authBloc;
        },
        act: (bloc) => bloc.add(const LoginSubmitted(
          serverUrl: 'https://invalid.server.com',
          username: 'testuser',
          password: 'password123',
        )),
        expect: () => [
          const AuthLoading(),
          const AuthError(
            message: 'Could not connect to server: Connection refused',
            type: AuthErrorType.serverUnreachable,
          ),
        ],
      );
    });

    group('LogoutRequested', () {
      blocTest<AuthBloc, AuthState>(
        'emits [AuthLoading, AuthUnauthenticated] when logout succeeds',
        build: () {
          when(() => mockAuthRepository.logout())
              .thenAnswer((_) async => const Right<AuthFailure, void>(null));
          when(() => mockAuthRepository.getStoredServerUrl())
              .thenAnswer((_) async => 'https://cloud.example.com');
          when(() => mockAuthRepository.getStoredUsername())
              .thenAnswer((_) async => 'testuser');
          return authBloc;
        },
        act: (bloc) => bloc.add(const LogoutRequested()),
        expect: () => [
          const AuthLoading(),
          const AuthUnauthenticated(
            lastServerUrl: 'https://cloud.example.com',
            lastUsername: 'testuser',
          ),
        ],
        verify: (_) {
          verify(() => mockAuthRepository.logout()).called(1);
        },
      );
    });
  });
}
