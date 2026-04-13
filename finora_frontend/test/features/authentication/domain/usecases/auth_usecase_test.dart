import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/errors/failures.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';
import 'package:finora_frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/login_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/register_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/reset_password_usecase.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;

  final tUser = User(
    id: 'user-1',
    email: 'test@finora.app',
    name: 'Test User',
    createdAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
  });

  // ── LoginUseCase ──────────────────────────────────────────────────────────────
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    setUp(() => useCase = LoginUseCase(mockRepository));

    test('retorna Right(User) con credenciales válidas', () async {
      when(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(const LoginParams(
        email: 'test@finora.app',
        password: 'Pass123!',
      ));

      expect(result.isRight(), true);
      verify(mockRepository.login(
        email: 'test@finora.app',
        password: 'Pass123!',
      )).called(1);
    });

    test('retorna Left(ValidationFailure) si email está vacío', () async {
      final result = await useCase(const LoginParams(
        email: '',
        password: 'Pass123!',
      ));

      result.fold(
        (f) => expect(f, isA<ValidationFailure>()),
        (_) => fail('esperaba Left'),
      );
      verifyNever(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('retorna Left(ValidationFailure) si password está vacío', () async {
      final result = await useCase(const LoginParams(
        email: 'test@finora.app',
        password: '',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si email tiene formato inválido',
        () async {
      final result = await useCase(const LoginParams(
        email: 'no-es-un-email',
        password: 'Pass123!',
      ));

      result.fold(
        (f) {
          expect(f, isA<ValidationFailure>());
          expect((f as ValidationFailure).message, contains('email'));
        },
        (_) => fail('esperaba Left'),
      );
    });

    test('propaga Left(ServerFailure) del repositorio', () async {
      when(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer(
        (_) async =>
            const Left(ServerFailure(message: 'Invalid credentials', code: 401)),
      );

      final result = await useCase(const LoginParams(
        email: 'test@finora.app',
        password: 'WrongPass1!',
      ));

      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Left'));
    });
  });

  // ── RegisterUseCase ───────────────────────────────────────────────────────────
  group('RegisterUseCase', () {
    late RegisterUseCase useCase;
    setUp(() => useCase = RegisterUseCase(mockRepository));

    const tValidParams = RegisterParams(
      email: 'new@finora.app',
      password: 'SecurePass1!',
      name: 'New User',
    );

    test('retorna Right(User) con parámetros válidos', () async {
      when(mockRepository.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
        phoneNumber: anyNamed('phoneNumber'),
        consents: anyNamed('consents'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(tValidParams);

      expect(result.isRight(), true);
    });

    test('retorna Left(ValidationFailure) si email está vacío', () async {
      final result = await useCase(const RegisterParams(
        email: '',
        password: 'SecurePass1!',
        name: 'User',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si password es demasiado corta', () async {
      final result = await useCase(const RegisterParams(
        email: 'a@b.com',
        password: 'Ab1!',  // < 8 caracteres
        name: 'User',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si password no tiene mayúscula', () async {
      final result = await useCase(const RegisterParams(
        email: 'a@b.com',
        password: 'onlylower1!',
        name: 'User',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si password no tiene carácter especial',
        () async {
      final result = await useCase(const RegisterParams(
        email: 'a@b.com',
        password: 'NoSpecial1',
        name: 'User',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si nombre es demasiado corto', () async {
      final result = await useCase(const RegisterParams(
        email: 'a@b.com',
        password: 'SecurePass1!',
        name: 'Ab',   // < 3 caracteres (minUsernameLength)
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) si nombre está vacío', () async {
      final result = await useCase(const RegisterParams(
        email: 'a@b.com',
        password: 'SecurePass1!',
        name: '',
      ));

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });

    test('LoginParams tienen igualdad por valor (Equatable)', () {
      const p1 = LoginParams(email: 'a@b.com', password: 'pass');
      const p2 = LoginParams(email: 'a@b.com', password: 'pass');
      expect(p1, equals(p2));
    });
  });

  // ── LogoutUseCase ─────────────────────────────────────────────────────────────
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;
    setUp(() => useCase = LogoutUseCase(mockRepository));

    test('retorna Right(null) cuando el repositorio tiene éxito', () async {
      when(mockRepository.logout())
          .thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result.isRight(), true);
      verify(mockRepository.logout()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('propaga Left(ServerFailure) del repositorio', () async {
      when(mockRepository.logout()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Logout failed')),
      );

      final result = await useCase();

      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Left'));
    });
  });

  // ── ForgotPasswordUseCase ─────────────────────────────────────────────────────
  group('ForgotPasswordUseCase', () {
    late ForgotPasswordUseCase useCase;
    setUp(() => useCase = ForgotPasswordUseCase(mockRepository));

    test('llama al repositorio con el email correcto', () async {
      when(mockRepository.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => const Right(null));

      final result = await useCase(const ForgotPasswordParams(
        email: 'reset@finora.app',
      ));

      expect(result.isRight(), true);
      verify(mockRepository.forgotPassword(email: 'reset@finora.app')).called(1);
    });
  });

  // ── ResetPasswordUseCase ──────────────────────────────────────────────────────
  group('ResetPasswordUseCase', () {
    late ResetPasswordUseCase useCase;
    setUp(() => useCase = ResetPasswordUseCase(mockRepository));

    test('llama al repositorio con token y nueva contraseña', () async {
      when(mockRepository.resetPassword(
        token: anyNamed('token'),
        newPassword: anyNamed('newPassword'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(const ResetPasswordParams(
        token: 'reset-tok-123',
        newPassword: 'NewPass123!',
      ));

      expect(result.isRight(), true);
      verify(mockRepository.resetPassword(
        token: 'reset-tok-123',
        newPassword: 'NewPass123!',
      )).called(1);
    });
  });
}
