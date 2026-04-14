import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/debts/domain/entities/debt_entity.dart';
import 'package:finora_frontend/features/debts/domain/repositories/debts_repository.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_debts_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/create_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/delete_debt_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/get_strategies_usecase.dart';
import 'package:finora_frontend/features/debts/domain/usecases/calculate_loan_usecase.dart';

import 'debts_usecase_test.mocks.dart';

@GenerateMocks([DebtsRepository])
void main() {
  late MockDebtsRepository mockRepo;

  final tDebt = DebtEntity(
    id: 'debt-1',
    userId: 'user-1',
    name: 'Car Loan',
    type: 'own',
    amount: 15000.0,
    remainingAmount: 10000.0,
    interestRate: 5.5,
    isActive: true,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );

  setUp(() {
    mockRepo = MockDebtsRepository();
  });

  group('GetDebtsUseCase', () {
    late GetDebtsUseCase useCase;
    setUp(() => useCase = GetDebtsUseCase(mockRepo));

    test('retorna lista de deudas del repositorio', () async {
      when(mockRepo.getDebts()).thenAnswer((_) async => [tDebt]);

      final result = await useCase();

      expect(result.length, 1);
      expect(result.first.id, 'debt-1');
      verify(mockRepo.getDebts()).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(
        mockRepo.getDebts(),
      ).thenAnswer((_) async => throw Exception('Error'));

      expect(useCase(), throwsException);
    });
  });

  group('CreateDebtUseCase', () {
    late CreateDebtUseCase useCase;
    setUp(() => useCase = CreateDebtUseCase(mockRepo));

    test('delega al repositorio con los datos correctos', () async {
      final data = <String, dynamic>{'name': 'Car Loan', 'amount': 15000.0};
      when(mockRepo.createDebt(data)).thenAnswer((_) async => tDebt);

      final result = await useCase(data);

      expect(result.name, 'Car Loan');
      verify(mockRepo.createDebt(data)).called(1);
    });
  });

  group('DeleteDebtUseCase', () {
    late DeleteDebtUseCase useCase;
    setUp(() => useCase = DeleteDebtUseCase(mockRepo));

    test('delega al repositorio con el id correcto', () async {
      when(
        mockRepo.deleteDebt(any),
      ).thenAnswer((_) async => Future<void>.value());

      await useCase('debt-1');

      verify(mockRepo.deleteDebt('debt-1')).called(1);
    });

    test('propaga excepción del repositorio', () async {
      when(
        mockRepo.deleteDebt(any),
      ).thenAnswer((_) async => throw Exception('Not found'));

      expect(useCase('bad-id'), throwsException);
    });
  });

  group('GetStrategiesUseCase', () {
    late GetStrategiesUseCase useCase;
    setUp(() => useCase = GetStrategiesUseCase(mockRepo));

    test('retorna mapa de estrategias', () async {
      final tStrategies = <String, dynamic>{
        'avalanche': [
          <String, dynamic>{'id': 'debt-1', 'order': 1},
        ],
      };
      when(mockRepo.getStrategies()).thenAnswer((_) async => tStrategies);

      final result = await useCase();

      expect(result, tStrategies);
      verify(mockRepo.getStrategies()).called(1);
    });
  });

  group('CalculateLoanUseCase', () {
    late CalculateLoanUseCase useCase;
    setUp(() => useCase = CalculateLoanUseCase(mockRepo));

    test('retorna resultado del cálculo con los datos correctos', () async {
      final data = <String, dynamic>{
        'amount': 15000,
        'rate': 5.5,
        'months': 60,
      };
      final tResult = <String, dynamic>{
        'monthly_payment': 283.07,
        'total_interest': 1984.2,
      };
      when(mockRepo.calculateLoan(data)).thenAnswer((_) async => tResult);

      final result = await useCase(data);

      expect(result['monthly_payment'], 283.07);
      verify(mockRepo.calculateLoan(data)).called(1);
    });
  });

  group('DebtEntity getters', () {
    test('isOwn retorna true para type own', () => expect(tDebt.isOwn, true));

    test(
      'paidAmount calcula correctamente',
      () => expect(tDebt.paidAmount, closeTo(5000.0, 0.01)),
    );

    test(
      'progressPercent calcula (paidAmount/amount)*100',
      () => expect(tDebt.progressPercent, closeTo(33.33, 0.01)),
    );
  });
}
