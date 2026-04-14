import 'package:dio/dio.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/features/ocr/data/datasources/ocr_remote_datasource.dart';
import 'package:finora_frontend/features/ocr/data/models/ocr_models.dart';

import 'ocr_remote_datasource_test.mocks.dart';

@GenerateMocks([ApiClient, LocalDatabase])
void main() {
  late MockApiClient mockClient;
  late OcrRemoteDataSourceImpl dataSource;

  setUp(() {
    mockClient = MockApiClient();
    dataSource = OcrRemoteDataSourceImpl(mockClient);
  });

  // ── extractFromText ───────────────────────────────────────────────────────
  group('extractFromText', () {
    test('retorna ExtractedReceiptModel del servidor', () async {
      final rawText = 'Mercadona\n49.99€';
      final expectedPayload = <String, dynamic>{'raw_text': rawText};

      when(mockClient.post('/ocr/extract', data: expectedPayload)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'amount': 49.99,
            'date': '2024-06-01',
            'description': 'Mercadona',
            'raw_lines': ['Mercadona', '49.99€'],
            'confidence': 'high',
          },
        ),
      );

      final result = await dataSource.extractFromText(rawText);

      expect(result, isA<ExtractedReceiptModel>());
      expect(result.confidence, 'high');
      verify(mockClient.post('/ocr/extract', data: expectedPayload)).called(1);
    });
  });

  // ── importReceipt ─────────────────────────────────────────────────────────
  group('importReceipt', () {
    test('llama al endpoint con los campos obligatorios', () async {
      when(
        mockClient.post('/ocr/import-receipt', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.importReceipt(
        amount: 49.99,
        date: '2024-06-01',
        description: 'Mercadona',
      );

      verify(
        mockClient.post(
          '/ocr/import-receipt',
          data: argThat(containsPair('amount', 49.99), named: 'data'),
        ),
      ).called(1);
    });

    test('incluye category cuando se proporciona', () async {
      when(
        mockClient.post('/ocr/import-receipt', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.importReceipt(
        amount: 49.99,
        date: '2024-06-01',
        description: 'Mercadona',
        category: 'food',
      );

      verify(
        mockClient.post(
          '/ocr/import-receipt',
          data: argThat(containsPair('category', 'food'), named: 'data'),
        ),
      ).called(1);
    });

    test('no incluye category cuando es null', () async {
      when(
        mockClient.post('/ocr/import-receipt', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      );

      await dataSource.importReceipt(
        amount: 49.99,
        date: '2024-06-01',
        description: 'Test',
      );

      final captured =
          verify(
                mockClient.post(
                  '/ocr/import-receipt',
                  data: captureAnyNamed('data'),
                ),
              ).captured.first
              as Map;
      expect(captured.containsKey('category'), false);
    });
  });

  // ── parseCsv ──────────────────────────────────────────────────────────────
  group('parseCsv', () {
    test('retorna CsvPreviewModel del servidor', () async {
      final csvContent = 'fecha,importe\n';
      final expectedPayload = <String, dynamic>{'csv_content': csvContent};

      when(mockClient.post('/ocr/parse-csv', data: expectedPayload)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'headers': ['fecha', 'importe'],
            'rows': <List<dynamic>>[],
            'total_rows': 0,
            'column_mapping': <String, dynamic>{},
          },
        ),
      );

      final result = await dataSource.parseCsv(csvContent);

      expect(result, isA<CsvPreviewModel>());
      verify(
        mockClient.post('/ocr/parse-csv', data: expectedPayload),
      ).called(1);
    });
  });

  // ── parsePdf ──────────────────────────────────────────────────────────────
  group('parsePdf', () {
    test('retorna CsvPreviewModel del servidor', () async {
      final pdfBase64 = 'base64content==';
      final expectedPayload = <String, dynamic>{'pdf_base64': pdfBase64};

      when(mockClient.post('/ocr/parse-pdf', data: expectedPayload)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{
            'headers': ['date', 'amount'],
            'rows': <List<dynamic>>[],
            'total_rows': 0,
            'column_mapping': <String, dynamic>{},
          },
        ),
      );

      final result = await dataSource.parsePdf(pdfBase64);

      expect(result, isA<CsvPreviewModel>());
      verify(
        mockClient.post('/ocr/parse-pdf', data: expectedPayload),
      ).called(1);
    });
  });

  // ── importCsvRows ─────────────────────────────────────────────────────────
  group('importCsvRows', () {
    test('retorna mapa con imported y skipped', () async {
      when(
        mockClient.post('/ocr/import-csv', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'imported': 5, 'skipped': 1},
        ),
      );

      final rows = [
        CsvRowModel.fromJson(<String, dynamic>{
          'index': 0,
          'amount': 50.0,
          'date': '2024-01-01',
          'description': 'Compra',
          'type': 'expense',
        }),
      ];

      final result = await dataSource.importCsvRows(rows);

      expect(result['imported'], 5);
      expect(result['skipped'], 1);
    });

    test('incluye skip_duplicates en el payload', () async {
      when(
        mockClient.post('/ocr/import-csv', data: anyNamed('data')),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: <String, dynamic>{'imported': 0, 'skipped': 0},
        ),
      );

      await dataSource.importCsvRows([], skipDuplicates: false);

      final captured =
          verify(
                mockClient.post(
                  '/ocr/import-csv',
                  data: captureAnyNamed('data'),
                ),
              ).captured.first
              as Map;
      expect(captured['skip_duplicates'], false);
    });
  });
}
