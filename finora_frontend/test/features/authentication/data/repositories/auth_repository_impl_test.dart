import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/errors/exceptions.dart';
import 'package:finora_frontend/core/errors/failures.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:finora_frontend/core/network/network_info.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:finora_frontend/features/authentication/data/models/user_model.dart';
import 'package:finora_frontend/features/authentication/data/repositories/auth_repository_impl.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';

import 'auth_repository_impl_test.mocks.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

@GenerateMocks([LocalDatabase])
void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockAuthLocalDataSource mockLocal;
  late MockNetworkInfo mockNetworkInfo;
  late MockLocalDatabase mockLocalDatabase;
  late AuthRepositoryImpl repository;

  final tUserModel = UserModel(
    id: 'user-1',
    email: 'test@finora.app',
    name: 'Test User',
    createdAt: DateTime(2024, 1, 1),
    isEmailVerified: true,
  );

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockLocal = MockAuthLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockLocalDatabase = MockLocalDatabase();
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemote,
      localDataSource: mockLocal,
      networkInfo: mockNetworkInfo,
      localDatabase: mockLocalDatabase,
    );
  });

  // ── login ────────────────────────────────────────────────────────────────────
  group('login', () {
    test('retorna Right(User) cuando hay red y el login es exitoso', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenAnswer((_) async => tUserModel);
      when(mockLocal.cacheUser(any)).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'test@finora.app',
        password: 'Pass123!',
      );

      expect(result, isA<Right<Failure, User>>());
      result.fold((_) => fail('esperaba Right'), (u) => expect(u.id, 'user-1'));
      verify(mockLocal.cacheUser(tUserModel)).called(1);
    });

    test('retorna Left(NetworkFailure) cuando no hay conexión', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.login(
        email: 'test@finora.app',
        password: 'Pass123!',
      );

      expect(result, isA<Left<Failure, User>>());
      result.fold(
        (f) => expect(f, isA<NetworkFailure>()),
        (_) => fail('esperaba Left'),
      );
      verifyNever(mockRemote.login(
        email: anyNamed('email'),
        password: anyNamed('password'),
      ));
    });

    test('retorna Left(ServerFailure) cuando el remote lanza ServerException',
        () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(const ServerException(message: 'Invalid credentials', code: 401));

      final result = await repository.login(
        email: 'bad@test.com',
        password: 'wrong',
      );

      result.fold(
        (f) {
          expect(f, isA<ServerFailure>());
          expect((f as ServerFailure).code, 401);
        },
        (_) => fail('esperaba Left'),
      );
    });

    test('retorna Left(AuthenticationFailure) cuando lanza AuthenticationException',
        () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.login(email: anyNamed('email'), password: anyNamed('password')))
          .thenThrow(const AuthenticationException(message: 'Token expired'));

      final result = await repository.login(
        email: 'a@b.com',
        password: 'Pass1!',
      );

      result.fold(
        (f) => expect(f, isA<AuthenticationFailure>()),
        (_) => fail('esperaba Left'),
      );
    });
  });

  // ── register ─────────────────────────────────────────────────────────────────
  group('register', () {
    test('retorna Right(User) cuando hay red y el registro es exitoso', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
        phoneNumber: anyNamed('phoneNumber'),
        consents: anyNamed('consents'),
      )).thenAnswer((_) async => tUserModel);
      when(mockLocal.cacheUser(any)).thenAnswer((_) async {});

      final result = await repository.register(
        email: 'new@finora.app',
        password: 'Pass123!',
        name: 'New User',
      );

      expect(result.isRight(), true);
    });

    test('retorna Left(NetworkFailure) sin conexión', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.register(
        email: 'x@x.com',
        password: 'Pass1!',
        name: 'X',
      );

      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
    });

    test('retorna Left(ValidationFailure) cuando lanza ValidationException',
        () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.register(
        email: anyNamed('email'),
        password: anyNamed('password'),
        name: anyNamed('name'),
        phoneNumber: anyNamed('phoneNumber'),
        consents: anyNamed('consents'),
      )).thenThrow(const ValidationException(message: 'Email already taken'));

      final result = await repository.register(
        email: 'dup@finora.app',
        password: 'Pass123!',
        name: 'Dup',
      );

      result.fold((f) => expect(f, isA<ValidationFailure>()), (_) => fail('Left'));
    });
  });

  // ── logout ───────────────────────────────────────────────────────────────────
  group('logout', () {
    test('retorna Right(null) limpiando cache y database', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.logout()).thenAnswer((_) async {});
      when(mockLocal.clearCache()).thenAnswer((_) async {});
      when(mockLocal.clearToken()).thenAnswer((_) async {});
      when(mockLocalDatabase.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isRight(), true);
      verify(mockLocal.clearCache()).called(1);
      verify(mockLocal.clearToken()).called(1);
      verify(mockLocalDatabase.clearAll()).called(1);
    });

    test('limpia la cache incluso cuando el server falla', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.logout())
          .thenThrow(const ServerException(message: 'fail'));
      when(mockLocal.clearCache()).thenAnswer((_) async {});
      when(mockLocal.clearToken()).thenAnswer((_) async {});
      when(mockLocalDatabase.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      // Retorna Left(ServerFailure) pero igualmente limpió
      result.fold((f) => expect(f, isA<ServerFailure>()), (_) => fail('Left'));
      verify(mockLocal.clearCache()).called(1);
      verify(mockLocal.clearToken()).called(1);
    });
  });

  // ── isLoggedIn ────────────────────────────────────────────────────────────────
  group('isLoggedIn', () {
    test('retorna true cuando localDataSource dice que está logueado', () async {
      when(mockLocal.isLoggedIn()).thenAnswer((_) async => true);

      final result = await repository.isLoggedIn();

      expect(result, true);
    });

    test('retorna false cuando localDataSource lanza excepción', () async {
      when(mockLocal.isLoggedIn()).thenThrow(Exception('Storage error'));

      final result = await repository.isLoggedIn();

      expect(result, false);
    });
  });

  // ── forgotPassword ────────────────────────────────────────────────────────────
  group('forgotPassword', () {
    test('retorna Right(null) cuando hay red y el POST es exitoso', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.forgotPassword(email: anyNamed('email')))
          .thenAnswer((_) async {});

      final result = await repository.forgotPassword(email: 'a@b.com');

      expect(result.isRight(), true);
    });

    test('retorna Left(NetworkFailure) sin conexión', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      final result = await repository.forgotPassword(email: 'a@b.com');

      result.fold((f) => expect(f, isA<NetworkFailure>()), (_) => fail('Left'));
    });
  });

  // ── enable2FA ─────────────────────────────────────────────────────────────────
  group('enable2FA', () {
    test('retorna Right(qrCode) cuando hay red', () async {
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemote.enable2FA()).thenAnswer((_) async => 'qr-data-base64');

      final result = await repository.enable2FA();

      result.fold((_) => fail('Right'), (qr) => expect(qr, 'qr-data-base64'));
    });
  });
}
