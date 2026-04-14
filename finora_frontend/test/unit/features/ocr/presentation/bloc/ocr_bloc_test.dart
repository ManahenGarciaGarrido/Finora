import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/ocr/presentation/bloc/ocr_bloc.dart';
import 'package:finora_frontend/features/ocr/presentation/bloc/ocr_event.dart';
import 'package:finora_frontend/features/ocr/presentation/bloc/ocr_state.dart';
import 'package:finora_frontend/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:finora_frontend/features/ocr/domain/entities/extracted_receipt_entity.dart';
import 'package:finora_frontend/features/ocr/domain/entities/csv_preview_entity.dart';

@GenerateMocks([OcrRepository])
import 'ocr_bloc_test.mocks.dart';

void main() {
  late OcrBloc bloc;
  late MockOcrRepository mockRepo;

  final tReceipt = ExtractedReceiptEntity(
    amount: 45.99,
    date: '2026-04-09',
    description: 'Supermercado Mercadona',
    merchant: 'Mercadona',
    suggestedCategory: 'food',
    rawLines: ['MERCADONA', 'Total: 45,99€'],
    confidence: 'high',
  );

  final tCsvRow1 = CsvRowEntity(
    index: 0,
    amount: 100.0,
    date: '2026-01-15',
    description: 'Salary',
    type: 'income',
    selected: true,
  );

  final tCsvRow2 = CsvRowEntity(
    index: 1,
    amount: 25.50,
    date: '2026-01-20',
    description: 'Grocery shopping',
    type: 'expense',
    selected: true,
  );

  final tCsvPreview = CsvPreviewEntity(
    headers: ['date', 'amount', 'description', 'type'],
    rows: [tCsvRow1, tCsvRow2],
    totalRows: 2,
    columnMapping: {'date': 0, 'amount': 1, 'description': 2, 'type': 3},
  );

  setUp(() {
    mockRepo = MockOcrRepository();
    bloc = OcrBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is OcrInitial', () {
    expect(bloc.state, isA<OcrInitial>());
  });

  group('ExtractReceiptText', () {
    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, ReceiptExtracted] with extracted data on success',
      build: () {
        when(mockRepo.extractFromText(any)).thenAnswer((_) async => tReceipt);
        return bloc;
      },
      act: (b) => b.add(const ExtractReceiptText('MERCADONA Total: 45,99€')),
      expect: () => [isA<OcrLoading>(), isA<ReceiptExtracted>()],
      verify: (_) {
        verify(mockRepo.extractFromText('MERCADONA Total: 45,99€')).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'ReceiptExtracted contains correct receipt data',
      build: () {
        when(mockRepo.extractFromText(any)).thenAnswer((_) async => tReceipt);
        return bloc;
      },
      act: (b) => b.add(const ExtractReceiptText('MERCADONA Total: 45,99€')),
      expect: () => [
        isA<OcrLoading>(),
        predicate<OcrState>((s) {
          if (s is ReceiptExtracted) {
            return s.receipt.amount == 45.99 &&
                s.receipt.description == 'Supermercado Mercadona' &&
                s.receipt.confidence == 'high';
          }
          return false;
        }),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, OcrError] on recognition failure',
      build: () {
        when(
          mockRepo.extractFromText(any),
        ).thenThrow(Exception('Text recognition failed'));
        return bloc;
      },
      act: (b) => b.add(const ExtractReceiptText('blurry unreadable text')),
      expect: () => [isA<OcrLoading>(), isA<OcrError>()],
    );

    blocTest<OcrBloc, OcrState>(
      'OcrError strips Exception: prefix',
      build: () {
        when(
          mockRepo.extractFromText(any),
        ).thenThrow(Exception('Text recognition failed'));
        return bloc;
      },
      act: (b) => b.add(const ExtractReceiptText('unreadable')),
      expect: () => [
        isA<OcrLoading>(),
        predicate<OcrState>((s) {
          if (s is OcrError) {
            return s.message == 'Text recognition failed';
          }
          return false;
        }),
      ],
    );
  });

  group('ImportReceipt', () {
    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, ReceiptImported] on success',
      build: () {
        when(
          mockRepo.importReceipt(
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            description: anyNamed('description'),
            category: anyNamed('category'),
          ),
        ).thenAnswer((_) async {
          return;
        });
        return bloc;
      },
      act: (b) => b.add(
        const ImportReceipt(
          amount: 45.99,
          date: '2026-04-09',
          description: 'Supermercado Mercadona',
          category: 'food',
        ),
      ),
      expect: () => [isA<OcrLoading>(), isA<ReceiptImported>()],
      verify: (_) {
        verify(
          mockRepo.importReceipt(
            amount: 45.99,
            date: '2026-04-09',
            description: 'Supermercado Mercadona',
            category: 'food',
          ),
        ).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, OcrError] on validation error',
      build: () {
        when(
          mockRepo.importReceipt(
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            description: anyNamed('description'),
            category: anyNamed('category'),
          ),
        ).thenThrow(Exception('Invalid amount'));
        return bloc;
      },
      act: (b) => b.add(
        const ImportReceipt(amount: -10.0, date: '2026-04-09', description: ''),
      ),
      expect: () => [isA<OcrLoading>(), isA<OcrError>()],
    );
  });

  group('ParseCsv', () {
    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, CsvParsed] with rows on success',
      build: () {
        when(mockRepo.parseCsv(any)).thenAnswer((_) async => tCsvPreview);
        return bloc;
      },
      act: (b) => b.add(
        const ParseCsv('date,amount,description\n2026-01-15,100,Salary'),
      ),
      expect: () => [isA<OcrLoading>(), isA<CsvParsed>()],
      verify: (_) {
        verify(mockRepo.parseCsv(any)).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'CsvParsed contains correct preview data',
      build: () {
        when(mockRepo.parseCsv(any)).thenAnswer((_) async => tCsvPreview);
        return bloc;
      },
      act: (b) => b.add(
        const ParseCsv('date,amount,description\n2026-01-15,100,Salary'),
      ),
      expect: () => [
        isA<OcrLoading>(),
        predicate<OcrState>((s) {
          if (s is CsvParsed) {
            return s.preview.rows.length == 2 &&
                s.preview.totalRows == 2 &&
                s.preview.headers.contains('date');
          }
          return false;
        }),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, OcrError] on invalid format',
      build: () {
        when(mockRepo.parseCsv(any)).thenThrow(Exception('Invalid CSV format'));
        return bloc;
      },
      act: (b) => b.add(const ParseCsv('not valid csv ;;; !!!')),
      expect: () => [isA<OcrLoading>(), isA<OcrError>()],
    );
  });

  group('ParsePdf', () {
    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, CsvParsed] on success',
      build: () {
        when(mockRepo.parsePdf(any)).thenAnswer((_) async => tCsvPreview);
        return bloc;
      },
      act: (b) => b.add(const ParsePdf('base64encodedpdfcontent==')),
      expect: () => [isA<OcrLoading>(), isA<CsvParsed>()],
      verify: (_) {
        verify(mockRepo.parsePdf('base64encodedpdfcontent==')).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, OcrError] when PDF parsing fails',
      build: () {
        when(mockRepo.parsePdf(any)).thenThrow(Exception('Cannot parse PDF'));
        return bloc;
      },
      act: (b) => b.add(const ParsePdf('invalidbase64')),
      expect: () => [isA<OcrLoading>(), isA<OcrError>()],
    );
  });

  group('ImportCsvRows', () {
    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, CsvImported] with counts on success',
      build: () {
        when(
          mockRepo.importCsvRows(
            any,
            skipDuplicates: anyNamed('skipDuplicates'),
          ),
        ).thenAnswer((_) async => {'imported': 2, 'skipped': 0});
        return bloc;
      },
      act: (b) => b.add(ImportCsvRows([tCsvRow1, tCsvRow2])),
      expect: () => [isA<OcrLoading>(), isA<CsvImported>()],
      verify: (_) {
        verify(mockRepo.importCsvRows(any, skipDuplicates: true)).called(1);
      },
    );

    blocTest<OcrBloc, OcrState>(
      'CsvImported contains correct imported and skipped counts',
      build: () {
        when(
          mockRepo.importCsvRows(
            any,
            skipDuplicates: anyNamed('skipDuplicates'),
          ),
        ).thenAnswer((_) async => {'imported': 2, 'skipped': 0});
        return bloc;
      },
      act: (b) => b.add(ImportCsvRows([tCsvRow1, tCsvRow2])),
      expect: () => [
        isA<OcrLoading>(),
        predicate<OcrState>((s) {
          if (s is CsvImported) {
            return s.imported == 2 && s.skipped == 0;
          }
          return false;
        }),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'CsvImported skips duplicates when skipDuplicates is true',
      build: () {
        when(
          mockRepo.importCsvRows(
            any,
            skipDuplicates: anyNamed('skipDuplicates'),
          ),
        ).thenAnswer((_) async => {'imported': 1, 'skipped': 1});
        return bloc;
      },
      act: (b) =>
          b.add(ImportCsvRows([tCsvRow1, tCsvRow2], skipDuplicates: true)),
      expect: () => [
        isA<OcrLoading>(),
        predicate<OcrState>((s) {
          if (s is CsvImported) {
            return s.imported == 1 && s.skipped == 1;
          }
          return false;
        }),
      ],
    );

    blocTest<OcrBloc, OcrState>(
      'emits [OcrLoading, OcrError] when import fails',
      build: () {
        when(
          mockRepo.importCsvRows(
            any,
            skipDuplicates: anyNamed('skipDuplicates'),
          ),
        ).thenThrow(Exception('Import failed'));
        return bloc;
      },
      act: (b) => b.add(ImportCsvRows([tCsvRow1])),
      expect: () => [isA<OcrLoading>(), isA<OcrError>()],
    );
  });
}

