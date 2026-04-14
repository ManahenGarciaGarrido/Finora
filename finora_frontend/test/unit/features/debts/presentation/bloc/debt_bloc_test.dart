import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/debts/domain/entities/debt_entity.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/create_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/update_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_strategies_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/calculate_loan_usecase.dart';
import 'package:finora_frontend/features/debts/presentation/bloc/debt_bloc.dart';
import 'package:finora_frontend/features/debts/presentation/bloc/debt_event.dart';
import 'package:finora_frontend/features/debts/presentation/bloc/debt_state.dart';

@GenerateMocks([
  GetDebtsUseCase,
  CreateDebtUseCase,
  UpdateDebtUseCase,
  DeleteDebtUseCase,
  GetStrategiesUseCase,
  CalculateLoanUseCase,
])
import 'debt_bloc_test.mocks.dart';

void main() {
  late DebtBloc debtBloc;
  late MockGetDebtsUseCase mockGetDebts;
  late MockCreateDebtUseCase mockCreateDebt;
  late MockUpdateDebtUseCase mockUpdateDebt;
  late MockDeleteDebtUseCase mockDeleteDebt;
  late MockGetStrategiesUseCase mockGetStrategies;
  late MockCalculateLoanUseCase mockCalculateLoan;

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
      {'month': 2, 'payment': 350.0, 'principal': 282.81, 'interest': 67.19},
    ],
  };

  setUp(() {
    mockGetDebts = MockGetDebtsUseCase();
    mockCreateDebt = MockCreateDebtUseCase();
    mockUpdateDebt = MockUpdateDebtUseCase();
    mockDeleteDebt = MockDeleteDebtUseCase();
    mockGetStrategies = MockGetStrategiesUseCase();
    mockCalculateLoan = MockCalculateLoanUseCase();

    debtBloc = DebtBloc(
      getDebts: mockGetDebts,
      createDebt: mockCreateDebt,
      updateDebt: mockUpdateDebt,
      deleteDebt: mockDeleteDebt,
      getStrategies: mockGetStrategies,
      calculateLoan: mockCalculateLoan,
    );
  });

  tearDown(() {
    debtBloc.close();
  });

  test('initial state is DebtInitial', () {
    expect(debtBloc.state, isA<DebtInitial>());
  });

  // ── LoadDebts ─────────────────────────────────────────────────────────────────

  group('LoadDebts', () {
    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtsLoaded] when debts are fetched successfully',
      build: () {
        when(mockGetDebts())
            .thenAnswer((_) async => [testDebt, testDebt2]);
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtsLoaded>(),
      ],
      verify: (_) {
        verify(mockGetDebts()).called(1);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'DebtsLoaded contains the fetched debts',
      build: () {
        when(mockGetDebts())
            .thenAnswer((_) async => [testDebt, testDebt2]);
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadDebts()),
      verify: (bloc) {
        expect(bloc.state, isA<DebtsLoaded>());
        final state = bloc.state as DebtsLoaded;
        expect(state.debts.length, 2);
        expect(state.debts.first.id, 'debt-1');
        expect(state.debts.last.id, 'debt-2');
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtsLoaded] with empty list when no debts exist',
      build: () {
        when(mockGetDebts()).thenAnswer((_) async => []);
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtsLoaded>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtsLoaded;
        expect(state.debts, isEmpty);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when server throws exception',
      build: () {
        when(mockGetDebts()).thenThrow(Exception('Server error'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadDebts()),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Server error');
      },
    );
  });

  // ── CreateDebt ────────────────────────────────────────────────────────────────

  group('CreateDebt', () {
    final createData = <String, dynamic>{
      'name': 'Car Loan',
      'type': 'own',
      'creditor_name': 'Bank ABC',
      'amount': 15000.0,
      'interest_rate': 5.5,
      'monthly_payment': 350.0,
    };

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtCreated] when debt is created successfully',
      build: () {
        when(mockCreateDebt(any)).thenAnswer((_) async => testDebt);
        return debtBloc;
      },
      act: (bloc) => bloc.add(CreateDebt(createData)),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtCreated>(),
      ],
      verify: (bloc) {
        verify(mockCreateDebt(createData)).called(1);
        final state = bloc.state as DebtCreated;
        expect(state.debt.id, 'debt-1');
        expect(state.debt.name, 'Car Loan');
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when creation fails with server error',
      build: () {
        when(mockCreateDebt(any))
            .thenThrow(Exception('Invalid debt data'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(CreateDebt(createData)),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Invalid debt data');
      },
    );
  });

  // ── UpdateDebt ────────────────────────────────────────────────────────────────

  group('UpdateDebt', () {
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

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtUpdated] when debt is updated successfully',
      build: () {
        when(mockUpdateDebt(any, any)).thenAnswer((_) async => updatedDebt);
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebt('debt-1', updateData)),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtUpdated>(),
      ],
      verify: (bloc) {
        verify(mockUpdateDebt('debt-1', updateData)).called(1);
        final state = bloc.state as DebtUpdated;
        expect(state.debt.remainingAmount, 9000.0);
        expect(state.debt.notes, 'Paid extra');
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when debt is not found',
      build: () {
        when(mockUpdateDebt(any, any))
            .thenThrow(Exception('Debt not found'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(UpdateDebt('nonexistent-id', updateData)),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Debt not found');
      },
    );
  });

  // ── DeleteDebt ────────────────────────────────────────────────────────────────

  group('DeleteDebt', () {
    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtDeleted] when debt is deleted successfully',
      build: () {
        when(mockDeleteDebt(any)).thenAnswer((_) async {});
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebt('debt-1')),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtDeleted>(),
      ],
      verify: (bloc) {
        verify(mockDeleteDebt('debt-1')).called(1);
        final state = bloc.state as DebtDeleted;
        expect(state.id, 'debt-1');
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when deletion throws server error',
      build: () {
        when(mockDeleteDebt(any)).thenThrow(Exception('Delete failed'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const DeleteDebt('debt-1')),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Delete failed');
      },
    );
  });

  // ── LoadStrategies ────────────────────────────────────────────────────────────

  group('LoadStrategies', () {
    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, StrategiesLoaded] with strategy data on success',
      build: () {
        when(mockGetStrategies())
            .thenAnswer((_) async => testStrategies);
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadStrategies()),
      expect: () => [
        isA<DebtLoading>(),
        isA<StrategiesLoaded>(),
      ],
      verify: (bloc) {
        verify(mockGetStrategies()).called(1);
        final state = bloc.state as StrategiesLoaded;
        expect(state.data['recommended'], 'avalanche');
        expect(state.data.containsKey('avalanche'), isTrue);
        expect(state.data.containsKey('snowball'), isTrue);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when strategies fetch fails',
      build: () {
        when(mockGetStrategies())
            .thenThrow(Exception('Strategies unavailable'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(const LoadStrategies()),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Strategies unavailable');
      },
    );
  });

  // ── CalculateLoan ─────────────────────────────────────────────────────────────

  group('CalculateLoan', () {
    final loanInput = <String, dynamic>{
      'amount': 15000.0,
      'interest_rate': 5.5,
      'term_months': 48,
    };

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, LoanCalculated] with calculated fields on success',
      build: () {
        when(mockCalculateLoan(any))
            .thenAnswer((_) async => testLoanResult);
        return debtBloc;
      },
      act: (bloc) => bloc.add(CalculateLoan(loanInput)),
      expect: () => [
        isA<DebtLoading>(),
        isA<LoanCalculated>(),
      ],
      verify: (bloc) {
        verify(mockCalculateLoan(loanInput)).called(1);
        final state = bloc.state as LoanCalculated;
        expect(state.result['monthly_payment'], 350.0);
        expect(state.result['total_interest'], 4200.0);
        expect(state.result.containsKey('amortization_schedule'), isTrue);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when loan calculation has invalid input',
      build: () {
        when(mockCalculateLoan(any))
            .thenThrow(Exception('Invalid loan parameters'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(CalculateLoan({
        'amount': -100.0,
        'interest_rate': -1.0,
        'term_months': 0,
      })),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Invalid loan parameters');
      },
    );
  });

  // ── CalculateMortgage ─────────────────────────────────────────────────────────

  group('CalculateMortgage', () {
    final mortgageInput = <String, dynamic>{
      'property_value': 200000.0,
      'down_payment': 40000.0,
      'interest_rate': 3.5,
      'term_years': 30,
    };

    final mortgageResult = <String, dynamic>{
      'monthly_payment': 718.47,
      'total_interest': 98650.0,
      'total_payment': 258650.0,
      'loan_amount': 160000.0,
    };

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, LoanCalculated] when mortgage calculation succeeds',
      build: () {
        when(mockCalculateLoan(any))
            .thenAnswer((_) async => mortgageResult);
        return debtBloc;
      },
      act: (bloc) => bloc.add(CalculateMortgage(mortgageInput)),
      expect: () => [
        isA<DebtLoading>(),
        isA<LoanCalculated>(),
      ],
      verify: (bloc) {
        // CalculateMortgage reuses calculateLoan use case (see debt_bloc.dart)
        verify(mockCalculateLoan(mortgageInput)).called(1);
        final state = bloc.state as LoanCalculated;
        expect(state.result['monthly_payment'], 718.47);
        expect(state.result['loan_amount'], 160000.0);
      },
    );

    blocTest<DebtBloc, DebtState>(
      'emits [DebtLoading, DebtError] when mortgage calculation fails',
      build: () {
        when(mockCalculateLoan(any))
            .thenThrow(Exception('Mortgage calculation failed'));
        return debtBloc;
      },
      act: (bloc) => bloc.add(CalculateMortgage(mortgageInput)),
      expect: () => [
        isA<DebtLoading>(),
        isA<DebtError>(),
      ],
      verify: (bloc) {
        final state = bloc.state as DebtError;
        expect(state.message, 'Mortgage calculation failed');
      },
    );
  });
}

