import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/ocr/data/datasources/ocr_remote_datasource.dart';
import 'package:finora_frontend/features/ocr/data/models/ocr_models.dart';
import 'package:finora_frontend/features/ocr/data/repositories/ocr_repository_impl.dart';
import 'package:finora_frontend/features/ocr/domain/entities/extracted_receipt_entity.dart';
import 'package:finora_frontend/features/ocr/domain/entities/csv_preview_entity.dart';

import 'ocr_repository_impl_test.mocks.dart';

@GenerateMocks([OcrRemoteDataSource])
void main() {
  late MockOcrRemoteDataSource mockDs;
  late OcrRepositoryImpl repository;

  final tReceipt = ExtractedReceiptModel.fromJson(<String, dynamic>{
    'amount': 49.99,
    'date': '2024-06-01',
    'description': 'Mercadona',
    'raw_lines': ['Mercadona', '49.99€'],
    'confidence': 'high',
  });

  final tPreview = CsvPreviewModel.fromJson(<String, dynamic>{
    'headers': ['fecha', 'importe'],
    'rows': <List<dynamic>>[],
    'total_rows': 0,
    'column_mapping': <String, dynamic>{},
  });

  setUp(() {
    mockDs = MockOcrRemoteDataSource();
    repository = OcrRepositoryImpl(mockDs);
  });

  // ── extractFromText ───────────────────────────────────────────────────────
  group('extractFromText', () {
    test('retorna ExtractedReceiptEntity', () async {
      when(mockDs.extractFromText(any)).thenAnswer((_) async => tReceipt);

      final result = await repository.extractFromText('texto del ticket');

      expect(result, isA<ExtractedReceiptEntity>());
      expect(result.confidence, 'high');
      verify(mockDs.extractFromText('texto del ticket')).called(1);
    });

    test('propaga excepción del datasource', () async {
      when(
        mockDs.extractFromText(any),
      ).thenAnswer((_) async => throw Exception('Error OCR'));

      expect(repository.extractFromText('test'), throwsException);
    });
  });

  // ── importReceipt ─────────────────────────────────────────────────────────
  group('importReceipt', () {
    test('delega al datasource con los campos correctos', () async {
      when(
        mockDs.importReceipt(
          amount: anyNamed('amount'),
          date: anyNamed('date'),
          description: anyNamed('description'),
          category: anyNamed('category'),
        ),
      ).thenAnswer((_) async => Future<void>.value());

      await repository.importReceipt(
        amount: 49.99,
        date: '2024-06-01',
        description: 'Mercadona',
        category: 'food',
      );

      verify(
        mockDs.importReceipt(
          amount: 49.99,
          date: '2024-06-01',
          description: 'Mercadona',
          category: 'food',
        ),
      ).called(1);
    });
  });

  // ── parseCsv ──────────────────────────────────────────────────────────────
  group('parseCsv', () {
    test('retorna CsvPreviewEntity', () async {
      when(mockDs.parseCsv(any)).thenAnswer((_) async => tPreview);

      final result = await repository.parseCsv('fecha,importe\n');

      expect(result, isA<CsvPreviewEntity>());
      verify(mockDs.parseCsv('fecha,importe\n')).called(1);
    });
  });

  // ── parsePdf ──────────────────────────────────────────────────────────────
  group('parsePdf', () {
    test('retorna CsvPreviewEntity', () async {
      when(mockDs.parsePdf(any)).thenAnswer((_) async => tPreview);

      final result = await repository.parsePdf('base64content==');

      expect(result, isA<CsvPreviewEntity>());
      verify(mockDs.parsePdf('base64content==')).called(1);
    });
  });

  // ── importCsvRows ─────────────────────────────────────────────────────────
  group('importCsvRows', () {
    test('retorna mapa con imported y skipped', () async {
      final tResult = <String, int>{'imported': 5, 'skipped': 1};

      when(
        mockDs.importCsvRows(any, skipDuplicates: anyNamed('skipDuplicates')),
      ).thenAnswer((_) async => tResult);

      final result = await repository.importCsvRows([], skipDuplicates: true);

      expect(result['imported'], 5);
      verify(mockDs.importCsvRows([], skipDuplicates: true)).called(1);
    });
  });
}
