import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/login_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/register_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:finora_frontend/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:finora_frontend/features/authentication/presentation/bloc/auth_event.dart';
import 'package:finora_frontend/features/authentication/presentation/bloc/auth_state.dart';
import 'package:finora_frontend/core/errors/failures.dart';

@GenerateMocks([
  LoginUseCase,
  RegisterUseCase,
  LogoutUseCase,
])
import 'auth_bloc_test.mocks.dart';

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockRegisterUseCase mockRegisterUseCase;
  late MockLogoutUseCase mockLogoutUseCase;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockRegisterUseCase = MockRegisterUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      registerUseCase: mockRegisterUseCase,
      logoutUseCase: mockLogoutUseCase,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  const testEmail = 'test@example.com';
  const testPassword = 'Test@1234';
  const testName = 'Test User';

  final testUser = User(
    id: '1',
    email: testEmail,
    name: testName,
    createdAt: DateTime.now(),
    isEmailVerified: true,
  );

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] when login is successful',
      build: () {
        when(mockLoginUseCase(any))
            .thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginRequested(
          email: testEmail,
          password: testPassword,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        Authenticated(user: testUser),
      ],
      verify: (_) {
        verify(mockLoginUseCase(
          const LoginParams(email: testEmail, password: testPassword),
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when login fails',
      build: () {
        when(mockLoginUseCase(any)).thenAnswer(
          (_) async => const Left(
            AuthenticationFailure(message: 'Invalid credentials'),
          ),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginRequested(
          email: testEmail,
          password: testPassword,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when network fails',
      build: () {
        when(mockLoginUseCase(any)).thenAnswer(
          (_) async => const Left(
            NetworkFailure(message: 'No internet connection'),
          ),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const LoginRequested(
          email: testEmail,
          password: testPassword,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'No internet connection'),
      ],
    );
  });

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, RegistrationSuccess] when registration is successful',
      build: () {
        when(mockRegisterUseCase(any))
            .thenAnswer((_) async => Right(testUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const RegisterRequested(
          email: testEmail,
          password: testPassword,
          name: testName,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        RegistrationSuccess(user: testUser),
      ],
      verify: (_) {
        verify(mockRegisterUseCase(
          const RegisterParams(
            email: testEmail,
            password: testPassword,
            name: testName,
          ),
        )).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when registration fails',
      build: () {
        when(mockRegisterUseCase(any)).thenAnswer(
          (_) async => const Left(
            ValidationFailure(message: 'Email already exists'),
          ),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(
        const RegisterRequested(
          email: testEmail,
          password: testPassword,
          name: testName,
        ),
      ),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Email already exists'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, LogoutSuccess] when logout is successful',
      build: () {
        when(mockLogoutUseCase()).thenAnswer((_) async => const Right(null));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const LogoutSuccess(),
      ],
      verify: (_) {
        verify(mockLogoutUseCase()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when logout fails',
      build: () {
        when(mockLogoutUseCase()).thenAnswer(
          (_) async => const Left(
            ServerFailure(message: 'Logout failed'),
          ),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthError(message: 'Logout failed'),
      ],
    );
  });

  group('ClearAuthError', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthInitial] when error is cleared',
      build: () => authBloc,
      seed: () => const AuthError(message: 'Some error'),
      act: (bloc) => bloc.add(const ClearAuthError()),
      expect: () => [const AuthInitial()],
    );
  });
}
