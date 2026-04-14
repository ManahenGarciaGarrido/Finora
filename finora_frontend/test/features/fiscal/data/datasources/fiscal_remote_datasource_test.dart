import 'package:dio/dio.dart'; // ¡Añadido para que reconozca Response!
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/fiscal/data/datasources/fiscal_remote_datasource.dart';
import 'package:finora_frontend/features/fiscal/data/models/fiscal_models.dart';

import 'fiscal_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late FiscalRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = FiscalRemoteDataSourceImpl(mockClient);
  });

  // ── getDeductibles ────────────────────────────────────────────────────────
  group('getDeductibles', () {
    test('retorna lista de FiscalTransactionModel', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'transactions': [
              {
                'id': 'tx-1',
                'description': 'Seguro médico',
                'amount': 120.0,
                'date': '2024-01-01',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getDeductibles();

      expect(result, isA<List<FiscalTransactionModel>>());
      expect(result.first.id, 'tx-1');
    });

    test('retorna lista vacía cuando transactions es null', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'transactions': null},
        ),
      );

      final result = await dataSource.getDeductibles();
      expect(result, isEmpty);
    });

    test('incluye year en la URL cuando se proporciona', () async {
      when(mockClient.get('/fiscal/deductible?year=2024')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'transactions': []},
        ),
      );

      await dataSource.getDeductibles(year: 2024);

      verify(mockClient.get('/fiscal/deductible?year=2024')).called(1);
    });
  });

  // ── getAllTransactions ────────────────────────────────────────────────────
  group('getAllTransactions', () {
    test('retorna lista de transacciones del endpoint fiscal', () async {
      when(mockClient.get('/fiscal/all-transactions')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'transactions': [
              {
                'id': 'tx-2',
                'description': 'Nómina',
                'amount': 2000.0,
                'date': '2024-02-01',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getAllTransactions();

      expect(result.length, 1);
      expect(result.first.description, 'Nómina');
    });
  });

  // ── estimateIrpf ──────────────────────────────────────────────────────────
  group('estimateIrpf', () {
    test('retorna IrpfResultModel del servidor', () async {
      when(mockClient.post('/fiscal/irpf', data: anyNamed('data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'annual_income': 30000.0,
            'deductible_total': 0.0,
            'taxable_base': 30000.0,
            'estimated_tax': 5700.0,
            'net_income': 24300.0,
            'effective_rate': 19.0,
            'brackets': [],
          },
        ),
      );

      final result = await dataSource.estimateIrpf(annualIncome: 30000.0);

      expect(result, isA<IrpfResultModel>());
      expect(result.annualIncome, 30000.0);
    });

    test('incluye extraDeductions en el payload', () async {
      when(
        mockClient.post(
          '/fiscal/irpf',
          data: argThat(containsPair('extra_deductions', 500.0), named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'annual_income': 30000.0,
            'deductible_total': 500.0,
            'taxable_base': 29500.0,
            'estimated_tax': 5605.0,
            'net_income': 24395.0,
            'effective_rate': 18.68,
            'brackets': [],
          },
        ),
      );

      await dataSource.estimateIrpf(
        annualIncome: 30000.0,
        extraDeductions: 500.0,
      );

      verify(
        mockClient.post(
          '/fiscal/irpf',
          data: argThat(containsPair('extra_deductions', 500.0), named: 'data'),
        ),
      ).called(1);
    });
  });

  // ── getCalendar ───────────────────────────────────────────────────────────
  group('getCalendar', () {
    test('retorna lista de TaxEventModel', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'events': [
              {
                'date': '2024-04-30',
                'title': 'Declaración IRPF',
                'type': 'deadline',
              },
            ],
          },
        ),
      );

      final result = await dataSource.getCalendar();

      expect(result, isA<List<TaxEventModel>>());
      expect(result.first.title, 'Declaración IRPF');
    });
  });

  // ── exportFiscal ──────────────────────────────────────────────────────────
  group('exportFiscal', () {
    test('retorna lista de FiscalTransactionModel exportadas', () async {
      when(mockClient.get(any)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'transactions': [
              {
                'id': 'tx-3',
                'description': 'Donación ONG',
                'amount': 500.0,
                'date': '2024-03-01',
              },
            ],
          },
        ),
      );

      final result = await dataSource.exportFiscal();
      expect(result.first.id, 'tx-3');
    });
  });
}

