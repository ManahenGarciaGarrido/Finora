import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/core/errors/exceptions.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_local_datasource.dart';
import 'package:finora_frontend/features/authentication/data/datasources/auth_remote_datasource.dart';
import 'package:finora_frontend/features/authentication/data/models/user_model.dart';

import 'auth_remote_data_source_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase, AuthLocalDataSource])
void main() {
  late MockApiClient mockApiClient;
  late MockAuthLocalDataSource mockLocalDataSource;
  late AuthRemoteDataSourceImpl dataSource;

  const tUserJson = <String, dynamic>{
    'id': 'user-1',
    'email': 'test@finora.app',
    'name': 'Test User',
    'created_at': '2024-01-01T00:00:00.000Z',
    'is_email_verified': false,
    'is_2fa_enabled': false,
  };

  Response<dynamic> fakeResponse(dynamic data, {int statusCode = 200}) =>
      Response(
        requestOptions: RequestOptions(path: ''),
        data: data,
        statusCode: statusCode,
      );

  setUp(() {
    mockApiClient = MockApiClient();
    mockLocalDataSource = MockAuthLocalDataSource();
    dataSource = AuthRemoteDataSourceImpl(
      apiClient: mockApiClient,
      localDataSource: mockLocalDataSource,
    );
  });

  // ── login ────────────────────────────────────────────────────────────────────
  group('login', () {
    test(
      'retorna UserModel y guarda token en storage al recibir 200',
      () async {
        when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async =>
              fakeResponse({'access_token': 'tok-abc', 'user': tUserJson}),
        );

        when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async {
          return;
        });

        final result = await dataSource.login(
          email: 'test@finora.app',
          password: 'Pass123!',
        );

        expect(result, isA<UserModel>());
        expect(result.id, 'user-1');
        verify(mockApiClient.setToken('tok-abc')).called(1);
        verify(mockLocalDataSource.saveToken('tok-abc')).called(1);
      },
    );

    test('lanza ServerException cuando el servidor devuelve != 200', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({'message': 'Unauthorized'}, statusCode: 401),
      );

      expect(
        () => dataSource.login(email: 'bad@test.com', password: 'wrong'),
        throwsA(isA<ServerException>()),
      );
    });

    test('relanza ServerException del ApiClient', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenThrow(const ServerException(message: 'Server error'));

      expect(
        () => dataSource.login(email: 'a@b.com', password: 'Pass1!'),
        throwsA(isA<ServerException>()),
      );
    });

    test('relanza NetworkException del ApiClient', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenThrow(const NetworkException(message: 'No connection'));

      expect(
        () => dataSource.login(email: 'a@b.com', password: 'Pass1!'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  // ── register ─────────────────────────────────────────────────────────────────
  group('register', () {
    test('retorna UserModel al recibir 201', () async {
      when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fakeResponse({
          'access_token': 'tok-new',
          'user': tUserJson,
        }, statusCode: 201),
      );
      when(mockLocalDataSource.saveToken(any)).thenAnswer((_) async {
        return;
      });

      final result = await dataSource.register(
        email: 'test@finora.app',
        password: 'Pass123!',
        name: 'Test User',
      );

      expect(result.email, 'test@finora.app');
    });
  });

  // ── logout ───────────────────────────────────────────────────────────────────
  group('logout', () {
    test('llama a POST logout y limpia el token', () async {
      when(mockApiClient.post(any)).thenAnswer((_) async => fakeResponse(null));

      await dataSource.logout();

      verify(mockApiClient.clearToken()).called(1);
    });

    test('limpia token aunque POST falle', () async {
      when(
        mockApiClient.post(any),
      ).thenThrow(const ServerException(message: 'fail'));

      await expectLater(dataSource.logout(), throwsA(isA<ServerException>()));
      verify(mockApiClient.clearToken()).called(1);
    });
  });

  // ── getCurrentUser ────────────────────────────────────────────────────────────
  group('getCurrentUser', () {
    test('retorna UserModel cuando GET /profile devuelve 200', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => fakeResponse(tUserJson));

      final result = await dataSource.getCurrentUser();

      expect(result.id, 'user-1');
    });

    test('lanza ServerException cuando status != 200', () async {
      when(
        mockApiClient.get(any),
      ).thenAnswer((_) async => fakeResponse(null, statusCode: 404));

      expect(dataSource.getCurrentUser(), throwsA(isA<ServerException>()));
    });
  });

  // ── forgotPassword ────────────────────────────────────────────────────────────
  group('forgotPassword', () {
    test('completa sin error cuando POST tiene éxito', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fakeResponse(null));

      await expectLater(dataSource.forgotPassword(email: 'a@b.com'), completes);
    });
  });

  // ── resetPassword ─────────────────────────────────────────────────────────────
  group('resetPassword', () {
    test('completa sin error cuando POST tiene éxito', () async {
      when(
        mockApiClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fakeResponse(null));

      await expectLater(
        dataSource.resetPassword(token: 'tok', newPassword: 'NewPass1!'),
        completes,
      );
    });
  });

  // ── enable2FA ─────────────────────────────────────────────────────────────────
  group('enable2FA', () {
    test('retorna el qr_code cuando POST tiene éxito', () async {
      when(mockApiClient.post(any)).thenAnswer(
        (_) async => fakeResponse({'qr_code': 'data:image/png;base64,...'}),
      );

      final result = await dataSource.enable2FA();

      expect(result, contains('data:image'));
    });
  });
}
