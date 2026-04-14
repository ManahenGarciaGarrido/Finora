import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:finora_frontend/core/errors/failures.dart';
import 'package:finora_frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/register_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/logout_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/forgot_password_usecase.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/reset_password_usecase.dart';

@GenerateMocks([AuthRepository])
import 'auth_usecases_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;

  final tUser = User(
    id: 'user-1',
    email: 'test@example.com',
    name: 'Test User',
    createdAt: DateTime(2026, 1, 1),
    isEmailVerified: false,
    is2FAEnabled: false,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RegisterUseCase
  // ─────────────────────────────────────────────────────────────────────────
  group('RegisterUseCase', () {
    late RegisterUseCase useCase;

    setUp(() {
      useCase = RegisterUseCase(mockRepo);
    });

    const validParams = RegisterParams(
      email: 'test@example.com',
      password: 'ValidPass1!',
      name: 'TestUser',
    );

    test('returns Right(User) when registration succeeds', () async {
      when(mockRepo.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
        phoneNumber: anyNamed('phoneNumber'),
        consents: anyNamed('consents'),
      )).thenAnswer((_) async => Right(tUser));

      final result = await useCase(validParams);

      expect(result, isA<Right<Failure, User>>());
      result.fold(
        (l) => fail('Expected Right but got Left: ${l.message}'),
        (r) => expect(r.email, equals('test@example.com')),
      );
      verify(mockRepo.register(
        email: 'test@example.com',
        password: 'ValidPass1!',
        name: 'TestUser',
        phoneNumber: null,
        consents: null,
      )).called(1);
    });

    test('returns Left(ValidationFailure) when email is empty', () async {
      const params = RegisterParams(
        email: '',
        password: 'ValidPass1!',
        name: 'TestUser',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message, contains('Email'));
        },
        (r) => fail('Expected Left but got Right'),
      );
      verifyNever(mockRepo.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
      ));
    });

    test('returns Left(ValidationFailure) when password is too short (<8 chars)', () async {
      const params = RegisterParams(
        email: 'test@example.com',
        password: 'Ab1!',
        name: 'TestUser',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message.toLowerCase(), contains('8'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password has no uppercase', () async {
      const params = RegisterParams(
        email: 'test@example.com',
        password: 'nouppercase1!',
        name: 'TestUser',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password has no digit', () async {
      const params = RegisterParams(
        email: 'test@example.com',
        password: 'NoDigitPass!',
        name: 'TestUser',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when name is too short (<3 chars)', () async {
      const params = RegisterParams(
        email: 'test@example.com',
        password: 'ValidPass1!',
        name: 'AB',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message.toLowerCase(), contains('3'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when name is empty', () async {
      const params = RegisterParams(
        email: 'test@example.com',
        password: 'ValidPass1!',
        name: '',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when email format is invalid', () async {
      const params = RegisterParams(
        email: 'not-an-email',
        password: 'ValidPass1!',
        name: 'TestUser',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message.toLowerCase(), contains('email'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('propagates ServerFailure from repository', () async {
      when(mockRepo.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
        phoneNumber: anyNamed('phoneNumber'),
        consents: anyNamed('consents'),
      )).thenAnswer((_) async => const Left(
            ServerFailure(message: 'Email already in use'),
          ));

      final result = await useCase(validParams);

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, contains('Email already in use'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LogoutUseCase
  // ─────────────────────────────────────────────────────────────────────────
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;

    setUp(() {
      useCase = LogoutUseCase(mockRepo);
    });

    test('returns Right(void) when logout succeeds', () async {
      when(mockRepo.logout())
          .thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, isA<Right<Failure, void>>());
      verify(mockRepo.logout()).called(1);
    });

    test('returns Left(ServerFailure) when logout fails', () async {
      when(mockRepo.logout()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'Logout failed')),
      );

      final result = await useCase();

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l.message, contains('Logout failed')),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(NetworkFailure) when network is unavailable', () async {
      when(mockRepo.logout()).thenAnswer(
        (_) async =>
            const Left(NetworkFailure(message: 'No internet connection')),
      );

      final result = await useCase();

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<NetworkFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ForgotPasswordUseCase
  // ─────────────────────────────────────────────────────────────────────────
  group('ForgotPasswordUseCase', () {
    late ForgotPasswordUseCase useCase;

    setUp(() {
      useCase = ForgotPasswordUseCase(mockRepo);
    });

    test('returns Right(void) when forgot password request succeeds', () async {
      when(mockRepo.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async => const Right(null));

      final result =
          await useCase(const ForgotPasswordParams(email: 'test@example.com'));

      expect(result, isA<Right<Failure, void>>());
      verify(mockRepo.forgotPassword(email: 'test@example.com')).called(1);
    });

    test('returns Left(ValidationFailure) when email is empty', () async {
      final result =
          await useCase(const ForgotPasswordParams(email: ''));

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message, isNotEmpty);
        },
        (r) => fail('Expected Left but got Right'),
      );
      verifyNever(mockRepo.forgotPassword(email: anyNamed('email')));
    });

    test('returns Left(ValidationFailure) when email format is invalid', () async {
      final result =
          await useCase(const ForgotPasswordParams(email: 'invalid-email'));

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
      verifyNever(mockRepo.forgotPassword(email: anyNamed('email')));
    });

    test('returns Left(ValidationFailure) for email without domain', () async {
      final result =
          await useCase(const ForgotPasswordParams(email: 'user@'));

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) for email without @', () async {
      final result =
          await useCase(const ForgotPasswordParams(email: 'userexample.com'));

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('propagates ServerFailure from repository', () async {
      when(mockRepo.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async =>
              const Left(ServerFailure(message: 'User not found')));

      final result =
          await useCase(const ForgotPasswordParams(email: 'notfound@example.com'));

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ServerFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // ResetPasswordUseCase
  // ─────────────────────────────────────────────────────────────────────────
  group('ResetPasswordUseCase', () {
    late ResetPasswordUseCase useCase;

    setUp(() {
      useCase = ResetPasswordUseCase(mockRepo);
    });

    const validParams = ResetPasswordParams(
      token: 'valid-reset-token-123',
      newPassword: 'NewValidPass1!',
    );

    test('returns Right(void) when reset password succeeds', () async {
      when(mockRepo.resetPassword(
        token: anyNamed('token'),
        newPassword: anyNamed('newPassword'),
      )).thenAnswer((_) async => const Right(null));

      final result = await useCase(validParams);

      expect(result, isA<Right<Failure, void>>());
      verify(mockRepo.resetPassword(
        token: 'valid-reset-token-123',
        newPassword: 'NewValidPass1!',
      )).called(1);
    });

    test('returns Left(ValidationFailure) when token is empty', () async {
      const params = ResetPasswordParams(
        token: '',
        newPassword: 'NewValidPass1!',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message, isNotEmpty);
        },
        (r) => fail('Expected Left but got Right'),
      );
      verifyNever(mockRepo.resetPassword(
        token: anyNamed('token'),
        newPassword: anyNamed('newPassword'),
      ));
    });

    test('returns Left(ValidationFailure) when password is empty', () async {
      const params = ResetPasswordParams(
        token: 'valid-token',
        newPassword: '',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password is too short (<8 chars)', () async {
      const params = ResetPasswordParams(
        token: 'valid-token',
        newPassword: 'Ab1!',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) {
          expect(l, isA<ValidationFailure>());
          expect(l.message, contains('8'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password has no uppercase', () async {
      const params = ResetPasswordParams(
        token: 'valid-token',
        newPassword: 'nouppercase1!',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password has no digit', () async {
      const params = ResetPasswordParams(
        token: 'valid-token',
        newPassword: 'NoDigitPass!',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('returns Left(ValidationFailure) when password has no special character', () async {
      const params = ResetPasswordParams(
        token: 'valid-token',
        newPassword: 'NoSpecial1A',
      );

      final result = await useCase(params);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) => expect(l, isA<ValidationFailure>()),
        (r) => fail('Expected Left but got Right'),
      );
    });

    test('propagates ServerFailure when token is expired', () async {
      when(mockRepo.resetPassword(
        token: anyNamed('token'),
        newPassword: anyNamed('newPassword'),
      )).thenAnswer((_) async =>
          const Left(ServerFailure(message: 'Token expired')));

      final result = await useCase(validParams);

      expect(result, isA<Left<Failure, void>>());
      result.fold(
        (l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, contains('Token expired'));
        },
        (r) => fail('Expected Left but got Right'),
      );
    });
  });
}

