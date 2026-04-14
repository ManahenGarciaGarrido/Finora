import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finora_frontend/features/debts/domain/entities/debt_entity.dart';
import 'package:finora_frontend/features/debts/domain/repositories/debts_repository.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/create_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/update_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_strategies_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/calculate_loan_usecase.dart';

@GenerateMocks([DebtsRepository])
import 'debt_usecases_test.mocks.dart';

void main() {
  late MockDebtsRepository mockRepository;

  final now = DateTime(2026, 4, 9);

  final testDebt = DebtEntity(
    id: 'debt-1',
    userId: 'user-1',
    name: 'Car Loan',
    type: 'own',
    creditorName: 'Bank ABC',
    amount: 15000.0,
    remainingAmount: 10000.0,
    interestRate: 5.5,
    dueDate: DateTime(2028, 6, 1),
    monthlyPayment: 350.0,
    notes: 'Monthly car payment',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  final testDebt2 = DebtEntity(
    id: 'debt-2',
    userId: 'user-1',
    name: 'Personal Loan',
    type: 'own',
    creditorName: 'Credit Union',
    amount: 5000.0,
    remainingAmount: 2500.0,
    interestRate: 8.0,
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );

  final testStrategies = <String, dynamic>{
    'avalanche': {
      'total_interest': 3200.0,
      'months_to_payoff': 36,
      'debts': ['debt-2', 'debt-1'],
    },
    'snowball': {
      'total_interest': 3500.0,
      'months_to_payoff': 38,
      'debts': ['debt-2', 'debt-1'],
    },
    'recommended': 'avalanche',
  };

  final testLoanResult = <String, dynamic>{
    'monthly_payment': 350.0,
    'total_interest': 4200.0,
    'total_payment': 19200.0,
    'amortization_schedule': [
      {'month': 1, 'payment': 350.0, 'principal': 281.25, 'interest': 68.75},
    ],
  };

  setUp(() {
    mockRepository = MockDebtsRepository();
  });

  // ── GetDebtsUseCase ───────────────────────────────────────────────────────────

  group('GetDebtsUseCase', () {
    late GetDebtsUseCase useCase;

    setUp(() {
      useCase = GetDebtsUseCase(mockRepository);
    });

    test('calls repository.getDebts() and returns list of debts', () async {
      when(
        mockRepository.getDebts(),
      ).thenAnswer((_) async => [testDebt, testDebt2]);

      final result = await useCase();

      expect(result, [testDebt, testDebt2]);
      verify(mockRepository.getDebts()).called(1);
    });

    test('returns empty list when no debts exist', () async {
      when(mockRepository.getDebts()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
      verify(mockRepository.getDebts()).called(1);
    });

    test('propagates exception thrown by repository', () async {
      when(mockRepository.getDebts()).thenThrow(Exception('Network error'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── CreateDebtUseCase ─────────────────────────────────────────────────────────

  group('CreateDebtUseCase', () {
    late CreateDebtUseCase useCase;

    setUp(() {
      useCase = CreateDebtUseCase(mockRepository);
    });

    final createData = <String, dynamic>{
      'name': 'Car Loan',
      'type': 'own',
      'creditor_name': 'Bank ABC',
      'amount': 15000.0,
      'interest_rate': 5.5,
      'monthly_payment': 350.0,
    };

    test(
      'calls repository.createDebt() with data and returns new debt',
      () async {
        when(mockRepository.createDebt(any)).thenAnswer((_) async => testDebt);

        final result = await useCase(createData);

        expect(result, testDebt);
        verify(mockRepository.createDebt(createData)).called(1);
      },
    );

    test('propagates exception when data is invalid', () async {
      when(
        mockRepository.createDebt(any),
      ).thenThrow(Exception('Invalid debt data'));

      expect(() => useCase({'name': ''}), throwsException);
    });

    test('returned debt has correct computed properties', () async {
      when(mockRepository.createDebt(any)).thenAnswer((_) async => testDebt);

      final result = await useCase(createData);

      expect(result.isOwn, isTrue);
      expect(result.paidAmount, 5000.0); // 15000 - 10000
      expect(result.progressPercent, closeTo(33.33, 0.01));
    });
  });

  // ── UpdateDebtUseCase ─────────────────────────────────────────────────────────

  group('UpdateDebtUseCase', () {
    late UpdateDebtUseCase useCase;

    setUp(() {
      useCase = UpdateDebtUseCase(mockRepository);
    });

    final updateData = <String, dynamic>{'remaining_amount': 9000.0, 'notes': 'Paid extra'};

    final updatedDebt = DebtEntity(
      id: 'debt-1',
      userId: 'user-1',
      name: 'Car Loan',
      type: 'own',
      creditorName: 'Bank ABC',
      amount: 15000.0,
      remainingAmount: 9000.0,
      interestRate: 5.5,
      notes: 'Paid extra',
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );

    test(
      'calls repository.updateDebt() with id and data, returns updated debt',
      () async {
        when(
          mockRepository.updateDebt(any, any),
        ).thenAnswer((_) async => updatedDebt);

        final result = await useCase('debt-1', updateData);

        expect(result, updatedDebt);
        verify(mockRepository.updateDebt('debt-1', updateData)).called(1);
      },
    );

    test('propagates exception when debt is not found', () async {
      when(
        mockRepository.updateDebt(any, any),
      ).thenThrow(Exception('Debt not found'));

      expect(() => useCase('nonexistent', updateData), throwsException);
    });

    test('updated debt reflects new remaining amount', () async {
      when(
        mockRepository.updateDebt(any, any),
      ).thenAnswer((_) async => updatedDebt);

      final result = await useCase('debt-1', updateData);

      expect(result.remainingAmount, 9000.0);
      expect(result.paidAmount, 6000.0); // 15000 - 9000
    });
  });

  // ── DeleteDebtUseCase ─────────────────────────────────────────────────────────

  group('DeleteDebtUseCase', () {
    late DeleteDebtUseCase useCase;

    setUp(() {
      useCase = DeleteDebtUseCase(mockRepository);
    });

    test('calls repository.deleteDebt() with correct id', () async {
      when(mockRepository.deleteDebt(any)).thenAnswer((_) async {
        return;
      });

      await useCase('debt-1');

      verify(mockRepository.deleteDebt('debt-1')).called(1);
    });

    test('propagates exception when debt does not exist', () async {
      when(
        mockRepository.deleteDebt(any),
      ).thenThrow(Exception('Debt not found'));

      expect(() => useCase('nonexistent'), throwsException);
    });

    test('completes without error when deletion is successful', () async {
      when(mockRepository.deleteDebt(any)).thenAnswer((_) async {
        return;
      });

      expect(() => useCase('debt-1'), returnsNormally);
    });
  });

  // ── GetStrategiesUseCase ──────────────────────────────────────────────────────

  group('GetStrategiesUseCase', () {
    late GetStrategiesUseCase useCase;

    setUp(() {
      useCase = GetStrategiesUseCase(mockRepository);
    });

    test('calls repository.getStrategies() and returns strategy map', () async {
      when(
        mockRepository.getStrategies(),
      ).thenAnswer((_) async => testStrategies);

      final result = await useCase();

      expect(result, testStrategies);
      expect(result['recommended'], 'avalanche');
      verify(mockRepository.getStrategies()).called(1);
    });

    test('returns map with both avalanche and snowball strategies', () async {
      when(
        mockRepository.getStrategies(),
      ).thenAnswer((_) async => testStrategies);

      final result = await useCase();

      expect(result.containsKey('avalanche'), isTrue);
      expect(result.containsKey('snowball'), isTrue);
    });

    test('propagates exception when service is unavailable', () async {
      when(
        mockRepository.getStrategies(),
      ).thenThrow(Exception('Strategies unavailable'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── CalculateLoanUseCase ──────────────────────────────────────────────────────

  group('CalculateLoanUseCase', () {
    late CalculateLoanUseCase useCase;

    setUp(() {
      useCase = CalculateLoanUseCase(mockRepository);
    });

    final loanInput = <String, dynamic>{
      'amount': 15000.0,
      'interest_rate': 5.5,
      'term_months': 48,
    };

    test(
      'calls repository.calculateLoan() with data and returns result',
      () async {
        when(
          mockRepository.calculateLoan(any),
        ).thenAnswer((_) async => testLoanResult);

        final result = await useCase(loanInput);

        expect(result, testLoanResult);
        verify(mockRepository.calculateLoan(loanInput)).called(1);
      },
    );

    test('returned result contains monthly_payment field', () async {
      when(
        mockRepository.calculateLoan(any),
      ).thenAnswer((_) async => testLoanResult);

      final result = await useCase(loanInput);

      expect(result.containsKey('monthly_payment'), isTrue);
      expect(result['monthly_payment'], 350.0);
    });

    test('returned result contains total_interest field', () async {
      when(
        mockRepository.calculateLoan(any),
      ).thenAnswer((_) async => testLoanResult);

      final result = await useCase(loanInput);

      expect(result.containsKey('total_interest'), isTrue);
    });

    test('returned result contains amortization_schedule', () async {
      when(
        mockRepository.calculateLoan(any),
      ).thenAnswer((_) async => testLoanResult);

      final result = await useCase(loanInput);

      expect(result.containsKey('amortization_schedule'), isTrue);
      expect(result['amortization_schedule'], isA<List>());
    });

    test('propagates exception when input is invalid', () async {
      when(
        mockRepository.calculateLoan(any),
      ).thenThrow(Exception('Invalid loan parameters'));

      expect(
        () => useCase({
          'amount': -100.0,
          'interest_rate': -1.0,
          'term_months': 0,
        }),
        throwsException,
      );
    });

    test('passes exact input data to repository', () async {
      when(
        mockRepository.calculateLoan(any),
      ).thenAnswer((_) async => testLoanResult);

      await useCase(loanInput);

      verify(mockRepository.calculateLoan(loanInput)).called(1);
      verifyNever(mockRepository.calculateLoan(argThat(isNot(loanInput))));
    });
  });
}

