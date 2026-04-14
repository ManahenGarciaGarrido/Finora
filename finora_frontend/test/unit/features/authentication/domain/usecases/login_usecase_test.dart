import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';
import 'package:finora_frontend/features/authentication/domain/repositories/auth_repository.dart';
import 'package:finora_frontend/features/authentication/domain/usecases/login_usecase.dart';
import 'package:finora_frontend/core/errors/failures.dart';

@GenerateMocks([AuthRepository])
import 'login_usecase_test.mocks.dart';

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = LoginUseCase(mockRepository);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'Test@1234';

  final testUser = User(
    id: '1',
    email: testEmail,
    name: 'Test User',
    createdAt: DateTime.now(),
    isEmailVerified: true,
  );

  group('LoginUseCase', () {
    test('should validate email is not empty', () async {
      // Arrange
      const params = LoginParams(email: '', password: testPassword);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Email cannot be empty'));
        },
        (_) => fail('Should return validation failure'),
      );
      verifyNever(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('should validate password is not empty', () async {
      // Arrange
      const params = LoginParams(email: testEmail, password: '');

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Password cannot be empty'));
        },
        (_) => fail('Should return validation failure'),
      );
      verifyNever(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('should validate email format', () async {
      // Arrange
      const params = LoginParams(email: 'invalid-email', password: testPassword);

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('Invalid email format'));
        },
        (_) => fail('Should return validation failure'),
      );
      verifyNever(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('should call repository login with correct parameters', () async {
      // Arrange
      const params = LoginParams(email: testEmail, password: testPassword);
      when(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(testUser));

      // Act
      await useCase(params);

      // Assert
      verify(mockRepository.login(
        email: testEmail,
        password: testPassword,
      )).called(1);
    });

    test('should return User when login is successful', () async {
      // Arrange
      const params = LoginParams(email: testEmail, password: testPassword);
      when(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => Right(testUser));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should return user'),
        (user) {
          expect(user, equals(testUser));
          expect(user.email, equals(testEmail));
        },
      );
    });

    test('should return Failure when login fails', () async {
      // Arrange
      const params = LoginParams(email: testEmail, password: testPassword);
      const failure = AuthenticationFailure(message: 'Invalid credentials');
      when(mockRepository.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      )).thenAnswer((_) async => const Left(failure));

      // Act
      final result = await useCase(params);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, equals('Invalid credentials'));
        },
        (_) => fail('Should return failure'),
      );
    });
  });
}

