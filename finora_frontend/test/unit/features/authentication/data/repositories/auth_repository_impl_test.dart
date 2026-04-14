import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';
import 'package:finora_frontend/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:finora_frontend/features/authentication/data/models/user_model.dart';
import 'package:finora_frontend/core/network/network_info.dart';
import 'package:finora_frontend/core/errors/failures.dart';
import 'package:finora_frontend/core/errors/exceptions.dart';

@GenerateMocks([AuthRemoteDataSource, AuthLocalDataSource, NetworkInfo])
import 'auth_repository_impl_test.mocks.dart';

/// LocalDatabase that doesn't touch Hive - suitable for unit tests
class _FakeLocalDatabase extends LocalDatabase {
  @override
  Future<void> clearAll() async {}
}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockAuthLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late LocalDatabase mockLocalDatabase;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockLocalDataSource = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockLocalDatabase = _FakeLocalDatabase();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
      localDatabase: mockLocalDatabase,
    );
  });

  tearDown(() {
    clearInteractions(mockNetworkInfo);
    clearInteractions(mockRemoteDataSource);
    clearInteractions(mockLocalDataSource);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'Test@1234';

  final testUserModel = UserModel(
    id: '1',
    email: testEmail,
    name: 'Test User',
    createdAt: DateTime.now(),
    isEmailVerified: true,
  );

  group('login', () {
    test('should check if device is online', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => testUserModel);
      when(mockLocalDataSource.cacheUser(any)).thenAnswer((_) async => {});

      // Act
      await repository.login(email: testEmail, password: testPassword);

      // Assert
      verify(mockNetworkInfo.isConnected);
    });

    test('should return NetworkFailure when device is offline', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(
        result,
        const Left(NetworkFailure(message: 'No internet connection')),
      );
      verifyNever(mockRemoteDataSource.login(email: anyNamed('email'), password: anyNamed('password')));
    });

    test('should call remote data source when device is online', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => testUserModel);
      when(mockLocalDataSource.cacheUser(any)).thenAnswer((_) async => {});

      // Act
      await repository.login(email: testEmail, password: testPassword);

      // Assert
      verify(
        mockRemoteDataSource.login(email: testEmail, password: testPassword),
      );
    });

    test('should cache user data when login is successful', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => testUserModel);
      when(mockLocalDataSource.cacheUser(any)).thenAnswer((_) async => {});

      // Act
      await repository.login(email: testEmail, password: testPassword);

      // Assert
      verify(mockLocalDataSource.cacheUser(testUserModel));
    });

    test('should return User when login is successful', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => testUserModel);
      when(mockLocalDataSource.cacheUser(any)).thenAnswer((_) async => {});

      // Act
      final result = await repository.login(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result.isRight(), true);
      result.fold((_) => fail('Should return user'), (user) {
        expect(user.email, equals(testEmail));
        expect(user.id, equals('1'));
      });
    });

    test(
      'should return ServerFailure when remote data source throws ServerException',
      () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockRemoteDataSource.login(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(const ServerException(message: 'Server error'));

        // Act
        final result = await repository.login(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<ServerFailure>());
          expect(failure.message, equals('Server error'));
        }, (_) => fail('Should return failure'));
      },
    );

    test(
      'should return AuthenticationFailure when credentials are invalid',
      () async {
        // Arrange
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockRemoteDataSource.login(
            email: anyNamed('email'),
            password: anyNamed('password'),
          ),
        ).thenThrow(
          const AuthenticationException(message: 'Invalid credentials'),
        );

        // Act
        final result = await repository.login(
          email: testEmail,
          password: testPassword,
        );

        // Assert
        expect(result.isLeft(), true);
        result.fold((failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, equals('Invalid credentials'));
        }, (_) => fail('Should return failure'));
      },
    );
  });

  group('logout', () {
    test('should clear local cache', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.logout()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearCache()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      await repository.logout();

      // Assert
      verify(mockLocalDataSource.clearCache());
      verify(mockLocalDataSource.clearToken());
    });

    test('should clear local cache even when server request fails', () async {
      // Arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockRemoteDataSource.logout(),
      ).thenThrow(const ServerException(message: 'Server error'));
      when(mockLocalDataSource.clearCache()).thenAnswer((_) async => {});
      when(mockLocalDataSource.clearToken()).thenAnswer((_) async => {});

      // Act
      await repository.logout();

      // Assert
      verify(mockLocalDataSource.clearCache());
      verify(mockLocalDataSource.clearToken());
    });
  });
}

