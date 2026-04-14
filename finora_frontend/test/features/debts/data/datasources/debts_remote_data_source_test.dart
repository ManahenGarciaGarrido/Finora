// ignore_for_file: subtype_of_sealed_class
// PREREQUISITO: flutter pub run build_runner build --delete-conflicting-outputs

import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/debts/data/datasources/debts_remote_datasource.dart';
import 'package:finora_frontend/features/debts/data/models/debt_model.dart';

import 'debts_remote_data_source_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late DebtsRemoteDataSourceImpl dataSource;

  const tDebtJson = <String, dynamic>{
    'id': 'debt-1',
    'user_id': 'user-1',
    'name': 'Car Loan',
    'type': 'own',
    'amount': 15000.0,
    'remaining_amount': 10000.0,
    'interest_rate': 5.5,
    'is_active': true,
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-01-01T00:00:00.000Z',
  };

  Response<dynamic> fake(dynamic data, {int code = 200}) => Response(
    requestOptions: RequestOptions(path: ''),
    data: data,
    statusCode: code,
  );

  setUp(() {
    mockClient = MockApiClient();
    dataSource = DebtsRemoteDataSourceImpl(mockClient);
  });

  group('getDebts', () {
    test('retorna lista de DebtModel al recibir respuesta exitosa', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => fake({
          'debts': [tDebtJson],
        }),
      );

      final result = await dataSource.getDebts();

      expect(result, isA<List<DebtModel>>());
      expect(result.length, 1);
      expect(result.first.id, 'debt-1');
    });

    test('retorna lista vacía cuando debts es []', () async {
      when(
        mockClient.get(any),
      ).thenAnswer((_) async => fake({'debts': <dynamic>[]}));

      expect(await dataSource.getDebts(), isEmpty);
    });

    test('propaga excepción del cliente', () {
      when(mockClient.get(any)).thenThrow(Exception('Network error'));
      expect(dataSource.getDebts(), throwsException);
    });
  });

  group('createDebt', () {
    test('llama a POST y retorna DebtModel', () async {
      when(
        mockClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fake({'debt': tDebtJson}, code: 201));

      final result = await dataSource.createDebt({'name': 'Car Loan'});

      expect(result.name, 'Car Loan');
      verify(mockClient.post(any, data: anyNamed('data'))).called(1);
    });
  });

  group('updateDebt', () {
    test('llama a PUT y retorna DebtModel actualizado', () async {
      when(mockClient.put(any, data: anyNamed('data'))).thenAnswer(
        (_) async => fake({
          'debt': {...tDebtJson, 'name': 'Updated'},
        }),
      );

      final result = await dataSource.updateDebt('debt-1', {'name': 'Updated'});

      expect(result.name, 'Updated');
    });
  });

  group('deleteDebt', () {
    test('llama a DELETE y completa sin error', () async {
      when(
        mockClient.delete(any),
      ).thenAnswer((_) async => fake(null, code: 204));

      await expectLater(dataSource.deleteDebt('debt-1'), completes);
      verify(mockClient.delete(any)).called(1);
    });
  });

  group('getStrategies', () {
    test('retorna mapa de estrategias', () async {
      final tStrategies = <String, dynamic>{'avalanche': [], 'snowball': []};
      when(mockClient.get(any)).thenAnswer((_) async => fake(tStrategies));

      final result = await dataSource.getStrategies();

      expect(result, tStrategies);
    });
  });

  group('calculateLoan', () {
    test('retorna mapa con resultado del cálculo', () async {
      final tResult = <String, dynamic>{'monthly_payment': 312.5, 'total_interest': 1500.0};
      when(
        mockClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fake(tResult));

      final result = await dataSource.calculateLoan({
        'amount': 15000,
        'rate': 5.5,
        'months': 60,
      });

      expect(result['monthly_payment'], 312.5);
    });
  });

  group('calculateMortgage', () {
    test('retorna mapa con resultado del cálculo hipotecario', () async {
      final tResult = <String, dynamic>{'monthly_payment': 850.0};
      when(
        mockClient.post(any, data: anyNamed('data')),
      ).thenAnswer((_) async => fake(tResult));

      final result = await dataSource.calculateMortgage({'amount': 200000});

      expect(result['monthly_payment'], 850.0);
    });
  });
}

