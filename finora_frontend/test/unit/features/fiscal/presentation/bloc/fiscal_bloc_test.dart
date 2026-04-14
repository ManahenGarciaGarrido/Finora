import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/fiscal/presentation/bloc/fiscal_bloc.dart';
import 'package:finora_frontend/features/fiscal/presentation/bloc/fiscal_event.dart';
import 'package:finora_frontend/features/fiscal/presentation/bloc/fiscal_state.dart';
import 'package:finora_frontend/features/fiscal/domain/repositories/fiscal_repository.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/fiscal_transaction_entity.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/irpf_result_entity.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/tax_event_entity.dart';

@GenerateMocks([FiscalRepository])
import 'fiscal_bloc_test.mocks.dart';

void main() {
  late FiscalBloc bloc;
  late MockFiscalRepository mockRepo;

  final tTransaction = FiscalTransactionEntity(
    id: 'tx1',
    description: 'Consultoria',
    amount: 1500.0,
    date: '2025-01-15',
    category: 'income',
    fiscalCategory: 'deductible',
  );

  final tTransaction2 = FiscalTransactionEntity(
    id: 'tx2',
    description: 'Material oficina',
    amount: 200.0,
    date: '2025-02-10',
    category: 'expense',
    fiscalCategory: 'deductible',
  );

  final tIrpfResult = IrpfResultEntity(
    annualIncome: 50000.0,
    deductibleTotal: 2000.0,
    taxableBase: 48000.0,
    estimatedTax: 12000.0,
    netIncome: 36000.0,
    effectiveRate: 0.25,
    brackets: [],
  );

  final tTaxEvent = TaxEventEntity(
    date: '2025-04-30',
    title: 'Declaración Renta',
    type: 'deadline',
  );

  setUp(() {
    mockRepo = MockFiscalRepository();
    bloc = FiscalBloc(mockRepo);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is FiscalInitial', () {
    expect(bloc.state, isA<FiscalInitial>());
  });

  group('LoadDeductibles', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, DeductiblesLoaded] when successful with year',
      build: () {
        when(mockRepo.getDeductibles(year: 2025))
            .thenAnswer((_) async => [tTransaction, tTransaction2]);
        return bloc;
      },
      act: (b) => b.add(const LoadDeductibles(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<DeductiblesLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.getDeductibles(year: 2025)).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'DeductiblesLoaded has correct total',
      build: () {
        when(mockRepo.getDeductibles(year: 2025))
            .thenAnswer((_) async => [tTransaction, tTransaction2]);
        return bloc;
      },
      act: (b) => b.add(const LoadDeductibles(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is DeductiblesLoaded) {
            return s.transactions.length == 2 &&
                (s.total - 1700.0).abs() < 0.01;
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, DeductiblesLoaded] with empty list when no deductibles',
      build: () {
        when(mockRepo.getDeductibles()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadDeductibles()),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is DeductiblesLoaded) {
            return s.transactions.isEmpty && s.total == 0.0;
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalError] when repository throws',
      build: () {
        when(mockRepo.getDeductibles())
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadDeductibles()),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalError>(),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'FiscalError strips Exception: prefix',
      build: () {
        when(mockRepo.getDeductibles())
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadDeductibles()),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is FiscalError) {
            return s.message == 'Network error';
          }
          return false;
        }),
      ],
    );
  });

  group('LoadAllTransactions', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, AllTransactionsLoaded] when successful',
      build: () {
        when(mockRepo.getAllTransactions(year: anyNamed('year')))
            .thenAnswer((_) async => [tTransaction, tTransaction2]);
        return bloc;
      },
      act: (b) => b.add(const LoadAllTransactions(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<AllTransactionsLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.getAllTransactions(year: 2025)).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalError] when repository throws',
      build: () {
        when(mockRepo.getAllTransactions(year: anyNamed('year')))
            .thenThrow(Exception('Server down'));
        return bloc;
      },
      act: (b) => b.add(const LoadAllTransactions(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalError>(),
      ],
    );
  });

  group('TagTransaction', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [DeductiblesLoaded, AllTransactionsLoaded] when successful',
      build: () {
        when(mockRepo.tagTransaction('tx1', 'deductible'))
            .thenAnswer((_) async => tTransaction);
        when(mockRepo.getDeductibles())
            .thenAnswer((_) async => [tTransaction]);
        when(mockRepo.getAllTransactions())
            .thenAnswer((_) async => [tTransaction, tTransaction2]);
        return bloc;
      },
      act: (b) => b.add(const TagTransaction('tx1', fiscalCategory: 'deductible')),
      expect: () => [
        isA<DeductiblesLoaded>(),
        isA<AllTransactionsLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.tagTransaction('tx1', 'deductible')).called(1);
        verify(mockRepo.getDeductibles()).called(1);
        verify(mockRepo.getAllTransactions()).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalError] when tagTransaction throws',
      build: () {
        when(mockRepo.tagTransaction(any, any))
            .thenThrow(Exception('Not found'));
        return bloc;
      },
      act: (b) => b.add(const TagTransaction('tx1', fiscalCategory: 'deductible')),
      expect: () => [
        isA<FiscalError>(),
      ],
    );
  });

  group('EstimateIrpf', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, IrpfEstimated] with result data when successful',
      build: () {
        when(mockRepo.estimateIrpf(
          annualIncome: anyNamed('annualIncome'),
          extraDeductions: anyNamed('extraDeductions'),
        )).thenAnswer((_) async => tIrpfResult);
        return bloc;
      },
      act: (b) => b.add(const EstimateIrpf(50000.0, extraDeductions: 2000.0)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<IrpfEstimated>(),
      ],
      verify: (_) {
        verify(mockRepo.estimateIrpf(
          annualIncome: 50000.0,
          extraDeductions: 2000.0,
        )).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'IrpfEstimated contains correct result data',
      build: () {
        when(mockRepo.estimateIrpf(
          annualIncome: anyNamed('annualIncome'),
          extraDeductions: anyNamed('extraDeductions'),
        )).thenAnswer((_) async => tIrpfResult);
        return bloc;
      },
      act: (b) => b.add(const EstimateIrpf(50000.0)),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is IrpfEstimated) {
            return s.result.annualIncome == 50000.0 &&
                s.result.estimatedTax == 12000.0;
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalError] when estimation fails',
      build: () {
        when(mockRepo.estimateIrpf(
          annualIncome: anyNamed('annualIncome'),
          extraDeductions: anyNamed('extraDeductions'),
        )).thenThrow(Exception('Calculation error'));
        return bloc;
      },
      act: (b) => b.add(const EstimateIrpf(50000.0)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalError>(),
      ],
    );
  });

  group('LoadCalendar', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, CalendarLoaded] when successful',
      build: () {
        when(mockRepo.getCalendar(year: anyNamed('year')))
            .thenAnswer((_) async => [tTaxEvent]);
        return bloc;
      },
      act: (b) => b.add(const LoadCalendar(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<CalendarLoaded>(),
      ],
      verify: (_) {
        verify(mockRepo.getCalendar(year: 2025)).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'CalendarLoaded contains correct events',
      build: () {
        when(mockRepo.getCalendar(year: anyNamed('year')))
            .thenAnswer((_) async => [tTaxEvent]);
        return bloc;
      },
      act: (b) => b.add(const LoadCalendar(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is CalendarLoaded) {
            return s.events.length == 1 &&
                s.events.first.title == 'Declaración Renta';
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalError] when calendar fetch fails',
      build: () {
        when(mockRepo.getCalendar(year: anyNamed('year')))
            .thenThrow(Exception('Calendar unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadCalendar(year: 2025)),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalError>(),
      ],
    );
  });

  group('ExportFiscal', () {
    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalExported] when format is json',
      build: () {
        when(mockRepo.exportFiscal(year: anyNamed('year')))
            .thenAnswer((_) async => [tTransaction]);
        return bloc;
      },
      act: (b) => b.add(const ExportFiscal(year: 2025, format: 'json')),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalExported>(),
      ],
      verify: (_) {
        verify(mockRepo.exportFiscal(year: 2025)).called(1);
      },
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalExportReady] when format is xlsx',
      build: () {
        when(mockRepo.downloadExport(year: anyNamed('year'), format: anyNamed('format')))
            .thenAnswer((_) async => '/tmp/export_2025.xlsx');
        return bloc;
      },
      act: (b) => b.add(const ExportFiscal(year: 2025, format: 'xlsx')),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is FiscalExportReady) {
            return s.filePath == '/tmp/export_2025.xlsx' && s.format == 'xlsx';
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalExportReady] when format is csv',
      build: () {
        when(mockRepo.downloadExport(year: anyNamed('year'), format: anyNamed('format')))
            .thenAnswer((_) async => '/tmp/export_2025.csv');
        return bloc;
      },
      act: (b) => b.add(const ExportFiscal(year: 2025, format: 'csv')),
      expect: () => [
        isA<FiscalLoading>(),
        predicate<FiscalState>((s) {
          if (s is FiscalExportReady) {
            return s.filePath == '/tmp/export_2025.csv' && s.format == 'csv';
          }
          return false;
        }),
      ],
    );

    blocTest<FiscalBloc, FiscalState>(
      'emits [FiscalLoading, FiscalError] when export fails',
      build: () {
        when(mockRepo.downloadExport(year: anyNamed('year'), format: anyNamed('format')))
            .thenThrow(Exception('Export failed'));
        return bloc;
      },
      act: (b) => b.add(const ExportFiscal(year: 2025, format: 'csv')),
      expect: () => [
        isA<FiscalLoading>(),
        isA<FiscalError>(),
      ],
    );
  });
}

