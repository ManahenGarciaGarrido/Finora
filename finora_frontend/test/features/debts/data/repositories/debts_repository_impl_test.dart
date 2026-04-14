import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/debts/data/datasources/debts_remote_datasource.dart';
import 'package:finora_frontend/features/debts/data/models/debt_model.dart';
import 'package:finora_frontend/features/debts/data/repositories/debts_repository_impl.dart';
import 'package:finora_frontend/features/debts/domain/entities/debt_entity.dart';

import 'debts_repository_impl_test.mocks.dart';

@GenerateMocks([DebtsRemoteDataSource])
void main() {
  late MockDebtsRemoteDataSource mockDs;
  late DebtsRepositoryImpl repository;

  final tModel = DebtModel(
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
    mockDs = MockDebtsRemoteDataSource();
    repository = DebtsRepositoryImpl(mockDs);
  });

  group('getDebts', () {
    test('delega al datasource y retorna lista de entidades', () async {
      when(mockDs.getDebts()).thenAnswer((_) async => [tModel]);

      final result = await repository.getDebts();

      expect(result, isA<List<DebtEntity>>());
      expect(result.first.id, 'debt-1');
      verify(mockDs.getDebts()).called(1);
    });

    test('propaga excepción del datasource', () async {
      when(
        mockDs.getDebts(),
      ).thenAnswer((_) async => throw Exception('Server error'));

      expect(repository.getDebts(), throwsException);
    });
  });

  group('createDebt', () {
    test('pasa el mapa de datos y retorna la entidad creada', () async {
      final data = <String, dynamic>{'name': 'Car Loan', 'amount': 15000.0};
      when(mockDs.createDebt(data)).thenAnswer((_) async => tModel);

      final result = await repository.createDebt(data);

      expect(result.name, 'Car Loan');
      verify(mockDs.createDebt(data)).called(1);
    });
  });

  group('updateDebt', () {
    test('pasa id y datos al datasource', () async {
      final data = <String, dynamic>{'name': 'Updated Loan'};
      when(mockDs.updateDebt('debt-1', data)).thenAnswer((_) async => tModel);

      await repository.updateDebt('debt-1', data);

      verify(mockDs.updateDebt('debt-1', data)).called(1);
    });
  });

  group('deleteDebt', () {
    test('delega al datasource con el id correcto', () async {
      when(
        mockDs.deleteDebt('debt-1'),
      ).thenAnswer((_) async => Future<void>.value());

      await repository.deleteDebt('debt-1');

      verify(mockDs.deleteDebt('debt-1')).called(1);
    });
  });

  group('getStrategies', () {
    test('delega al datasource y retorna el mapa', () async {
      final tStrategies = <String, dynamic>{'avalanche': [], 'snowball': []};
      when(mockDs.getStrategies()).thenAnswer((_) async => tStrategies);

      final result = await repository.getStrategies();

      expect(result, tStrategies);
    });
  });

  group('calculateLoan', () {
    test('pasa datos al datasource y retorna resultado', () async {
      final tResult = <String, dynamic>{'monthly_payment': 312.5};
      final data = <String, dynamic>{
        'amount': 15000,
        'rate': 5.5,
        'months': 60,
      };
      when(mockDs.calculateLoan(data)).thenAnswer((_) async => tResult);

      final result = await repository.calculateLoan(data);

      expect(result['monthly_payment'], 312.5);
      verify(mockDs.calculateLoan(data)).called(1);
    });
  });

  group('calculateMortgage', () {
    test('pasa datos al datasource y retorna resultado', () async {
      final tResult = <String, dynamic>{'monthly_payment': 850.0};
      final data = <String, dynamic>{'amount': 200000};
      when(mockDs.calculateMortgage(data)).thenAnswer((_) async => tResult);

      final result = await repository.calculateMortgage(data);

      expect(result['monthly_payment'], 850.0);
      verify(mockDs.calculateMortgage(data)).called(1);
    });
  });
}
