// ignore_for_file: subtype_of_sealed_class
// PREREQUISITO: flutter pub run build_runner build --delete-conflicting-outputs

import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/banks/data/datasources/bank_remote_datasource.dart';
import 'package:finora_frontend/features/banks/data/models/bank_account_model.dart';
import 'package:finora_frontend/features/banks/data/models/bank_card_model.dart';

import 'bank_remote_data_source_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late BankRemoteDataSourceImpl dataSource;

  const tAccountJson = <String, dynamic>{
    'id': 'acc-1',
    'connection_id': 'conn-1',
    'account_name': 'Cuenta Corriente',
    'balance_cents': 150050,
  };

  const tCardJson = <String, dynamic>{
    'id': 'card-1',
    'bank_account_id': 'acc-1',
    'user_id': 'user-1',
    'card_name': 'Visa',
  };

  Response<dynamic> fake(dynamic data, {int code = 200}) => Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: code,
  );

  setUp(() {
    mockClient = MockApiClient();
    dataSource = BankRemoteDataSourceImpl(apiClient: mockClient);
  });

  group('getInstitutions', () {
    test('retorna lista de BankInstitutionModel', () async {
      when(
        mockClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer(
        (_) async => fake({
          'institutions': [
            {
              'id': 'inst-1',
              'name': 'Santander',
              'bic': 'BSCHESMMXXX',
              'countries': ['ES'],
            },
          ],
        }),
      );

      final result = await dataSource.getInstitutions();

      expect(result.length, 1);
      expect(result.first.id, 'inst-1');
    });

    test('retorna lista vacía cuando institutions es null', () async {
      when(
        mockClient.get(any, queryParameters: anyNamed('queryParameters')),
      ).thenAnswer((_) async => fake({'institutions': null}));

      expect(await dataSource.getInstitutions(), isEmpty);
    });
  });

  group('getBankAccounts', () {
    test('retorna lista de BankAccountModel', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => fake({
          'accounts': [tAccountJson],
        }),
      );

      final result = await dataSource.getBankAccounts();

      expect(result, isA<List<BankAccountModel>>());
      expect(result.first.id, 'acc-1');
    });

    test('retorna lista vacía cuando accounts es null', () async {
      when(
        mockClient.get(any),
      ).thenAnswer((_) async => fake({'accounts': null}));
      expect(await dataSource.getBankAccounts(), isEmpty);
    });
  });

  group('connectBank', () {
    test('retorna mapa con connectionId y authUrl', () async {
      when(mockClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fake({
          'connection_id': 'conn-1',
          'auth_url': 'https://bank.auth/link',
          'institution_name': 'Santander',
          'is_mock': false,
        }),
      );

      final result = await dataSource.connectBank('inst-1');

      expect(result['connectionId'], 'conn-1');
      expect(result['authUrl'], 'https://bank.auth/link');
    });
  });

  group('disconnectBank', () {
    test('llama a DELETE y completa sin error', () async {
      when(
        mockClient.delete(any),
      ).thenAnswer((_) async => fake(null, code: 204));

      await expectLater(dataSource.disconnectBank('conn-1'), completes);
      verify(mockClient.delete(any)).called(1);
    });
  });

  group('syncBank', () {
    test('llama a POST sync y retorna cuentas actualizadas', () async {
      when(mockClient.post(any)).thenAnswer(
        (_) async => fake({
          'accounts': [tAccountJson],
        }),
      );

      final result = await dataSource.syncBank('conn-1');

      expect(result.first.id, 'acc-1');
    });
  });

  group('getBankCards', () {
    test('retorna lista de BankCardModel', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => fake({
          'cards': [tCardJson],
        }),
      );

      final result = await dataSource.getBankCards();

      expect(result, isA<List<BankCardModel>>());
      expect(result.first.id, 'card-1');
    });
  });

  group('deleteBankCard', () {
    test('llama a DELETE y completa sin error', () async {
      when(
        mockClient.delete(any),
      ).thenAnswer((_) async => fake(null, code: 204));

      await expectLater(dataSource.deleteBankCard('card-1'), completes);
    });
  });

  group('importCsvTransactions', () {
    test('retorna mapa con imported y skipped', () async {
      when(
        mockClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fake({'imported': 10, 'skipped': 2}));

      final result = await dataSource.importCsvTransactions(
        bankAccountId: 'acc-1',
        rows: [
          {'date': '2024-01-01', 'amount': '-50.0', 'description': 'Coffee'},
        ],
      );

      expect(result['imported'], 10);
      expect(result['skipped'], 2);
    });
  });

  group('importBankTransactions', () {
    test('retorna mapa con imported, skipped y last_sync_at', () async {
      when(mockClient.post(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fake({
          'imported': 25,
          'skipped': 3,
          'last_sync_at': '2024-06-01T10:00:00.000Z',
        }),
      );

      final result = await dataSource.importBankTransactions('conn-1');

      expect(result['imported'], 25);
      expect(result['last_sync_at'], '2024-06-01T10:00:00.000Z');
    });
  });

  group('getPsd2Consents', () {
    test('retorna lista de consentimientos', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => fake({
          'consents': [
            {'connection_id': 'conn-1', 'status': 'active'},
          ],
        }),
      );

      final result = await dataSource.getPsd2Consents();

      expect(result.length, 1);
      expect(result.first['status'], 'active');
    });
  });

  group('renewPsd2Consent', () {
    test('llama a POST y completa sin error', () async {
      when(mockClient.post(any)).thenAnswer((_) async => fake(null));
      await expectLater(dataSource.renewPsd2Consent('conn-1'), completes);
    });
  });

  group('revokePsd2Consent', () {
    test('llama a DELETE y completa sin error', () async {
      when(
        mockClient.delete(any),
      ).thenAnswer((_) async => fake(null, code: 204));
      await expectLater(dataSource.revokePsd2Consent('conn-1'), completes);
    });
  });
}


