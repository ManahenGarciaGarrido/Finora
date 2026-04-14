import 'package:dio/dio.dart'; // Importante para usar Response
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/household/data/datasources/household_remote_datasource.dart';
import 'package:finora_frontend/features/household/data/models/household_model.dart';

import 'household_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late HouseholdRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = HouseholdRemoteDataSourceImpl(mockClient);
  });

  // ── getHousehold ──────────────────────────────────────────────────────────
  group('getHousehold', () {
    test('retorna HouseholdModel cuando existe', () async {
      when(mockClient.get('/household')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'household': {
              'id': 'hh-1',
              'name': 'Mi Hogar',
              'owner_id': 'user-1',
              'created_at': '2024-01-01T00:00:00.000Z',
            },
          },
        ),
      );

      final result = await dataSource.getHousehold();

      expect(result, isA<HouseholdModel>());
      expect(result!.id, 'hh-1');
    });

    test('retorna null cuando household es null', () async {
      when(mockClient.get('/household')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'household': null},
        ),
      );

      final result = await dataSource.getHousehold();
      expect(result, isNull);
    });
  });

  // ── createHousehold ───────────────────────────────────────────────────────
  group('createHousehold', () {
    test('retorna HouseholdModel creado', () async {
      when(mockClient.post('/household', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'household': {
              'id': 'hh-2',
              'name': 'Casa Nueva',
              'owner_id': 'user-1',
              'created_at': '2024-06-01T00:00:00.000Z',
            },
          },
        ),
      );

      final result = await dataSource.createHousehold('Casa Nueva');

      expect(result.name, 'Casa Nueva');
      verify(
        mockClient.post('/household', data: <String, dynamic>{'name': 'Casa Nueva'}),
      ).called(1);
    });
  });

  // ── deleteHousehold ───────────────────────────────────────────────────────
  group('deleteHousehold', () {
    test('llama al endpoint DELETE correcto', () async {
      when(mockClient.delete('/household')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.deleteHousehold();

      verify(mockClient.delete('/household')).called(1);
    });
  });

  // ── inviteMember ──────────────────────────────────────────────────────────
  group('inviteMember', () {
    test('llama al endpoint con el email correcto', () async {
      when(
        mockClient.post('/household/invite', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.inviteMember('ana@example.com');

      verify(
        mockClient.post(
          '/household/invite',
          data: <String, dynamic>{'email': 'ana@example.com'},
        ),
      ).called(1);
    });
  });

  // ── removeMember ──────────────────────────────────────────────────────────
  group('removeMember', () {
    test('llama al endpoint DELETE con el userId correcto', () async {
      when(mockClient.delete('/household/members/user-2')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.removeMember('user-2');

      verify(mockClient.delete('/household/members/user-2')).called(1);
    });
  });

  // ── getMembers ────────────────────────────────────────────────────────────
  group('getMembers', () {
    test('retorna lista de HouseholdMemberModel', () async {
      when(mockClient.get('/household/members')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'members': [
              {
                'id': 'mem-1',
                'user_id': 'user-2',
                'role': 'member',
                'joined_at': '2024-02-01T00:00:00.000Z',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getMembers();

      expect(result, isA<List<HouseholdMemberModel>>());
      expect(result.first.userId, 'user-2');
    });
  });

  // ── createSharedTransaction ───────────────────────────────────────────────
  group('createSharedTransaction', () {
    test('llama al endpoint POST con los datos correctos', () async {
      when(
        mockClient.post('/household/transactions', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      final data = <String, dynamic>{'amount': 100.0, 'description': 'Cena'};
      await dataSource.createSharedTransaction(data);

      verify(mockClient.post('/household/transactions', data: data)).called(1);
    });
  });

  // ── getSharedTransactions ─────────────────────────────────────────────────
  group('getSharedTransactions', () {
    test('retorna lista de SharedTransactionModel', () async {
      when(mockClient.get('/household/transactions')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'transactions': [
              {
                'id': 'st-1',
                'amount': 80.0,
                'description': 'Supermercado',
                'created_at': '2024-03-01T00:00:00.000Z',
                'splits': [],
              },
            ],
          },
        ),
      );

      final result = await dataSource.getSharedTransactions();

      expect(result, isA<List<SharedTransactionModel>>());
      expect(result.first.description, 'Supermercado');
    });
  });

  // ── getBalances ───────────────────────────────────────────────────────────
  group('getBalances', () {
    test('retorna lista de BalanceModel', () async {
      when(mockClient.get('/household/balances')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'balances': [
              {'payer_id': 'user-1', 'ower_id': 'user-2', 'amount': 25.0},
            ],
          },
        ),
      );

      final result = await dataSource.getBalances();

      expect(result, isA<List<BalanceModel>>());
      expect(result.first.amount, 25.0);
    });
  });

  // ── settleBalance ─────────────────────────────────────────────────────────
  group('settleBalance', () {
    test('llama al endpoint con withUserId correcto', () async {
      when(
        mockClient.post('/household/settle', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.settleBalance('user-2');

      verify(
        mockClient.post('/household/settle', data: <String, dynamic>{'with_user_id': 'user-2'}),
      ).called(1);
    });
  });
}

