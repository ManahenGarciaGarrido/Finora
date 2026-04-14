import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/goals/data/datasources/goals_remote_datasource.dart';
import 'package:finora_frontend/features/goals/data/models/goal_contribution_model.dart';
import 'package:finora_frontend/features/goals/data/models/savings_goal_model.dart';
import 'package:finora_frontend/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/domain/entities/goal_contribution_entity.dart';

import 'goals_repository_impl_test.mocks.dart';

@GenerateMocks([GoalsRemoteDataSource])
void main() {
  late MockGoalsRemoteDataSource mockDataSource;
  late GoalsRepositoryImpl repository;

  final tGoalModel = SavingsGoalModel(
    id: 'goal-1',
    userId: 'user-1',
    name: 'Vacation Fund',
    icon: 'beach',
    color: '#6C63FF',
    targetAmount: 5000.0,
    currentAmount: 1000.0,
    status: 'active',
    percentage: 20,
    percentageDecimal: 0.20,
    remainingAmount: 4000.0,
    progressColor: '#ef4444',
    isCompleted: false,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 2),
  );

  final tContributionModel = GoalContributionModel(
    id: 'contrib-1',
    goalId: 'goal-1',
    userId: 'user-1',
    amount: 200.0,
    date: DateTime(2024, 3, 15),
    note: 'Monthly saving',
    createdAt: DateTime(2024, 3, 15),
    updatedAt: DateTime(2024, 3, 15),
  );

  setUp(() {
    mockDataSource = MockGoalsRemoteDataSource();
    repository = GoalsRepositoryImpl(mockDataSource);
  });

  group('getGoals', () {
    test('delega al datasource y retorna la lista de entidades', () async {
      when(mockDataSource.getGoals()).thenAnswer((_) async => [tGoalModel]);

      final result = await repository.getGoals();

      expect(result, isA<List<SavingsGoalEntity>>());
      expect(result.length, 1);
      expect(result.first.id, 'goal-1');
      verify(mockDataSource.getGoals()).called(1);
    });

    test('propaga excepción del datasource', () async {
      when(
        mockDataSource.getGoals(),
      ).thenAnswer((_) async => throw Exception('Server error'));

      expect(repository.getGoals(), throwsException);
    });
  });

  group('getGoal', () {
    test('delega al datasource con el id correcto', () async {
      when(
        mockDataSource.getGoal('goal-1'),
      ).thenAnswer((_) async => tGoalModel);

      final result = await repository.getGoal('goal-1');

      expect(result.id, 'goal-1');
      verify(mockDataSource.getGoal('goal-1')).called(1);
    });
  });

  group('createGoal', () {
    test('construye el payload correcto con campos obligatorios', () async {
      final expectedPayload = <String, dynamic>{
        'name': 'Vacation Fund',
        'icon': 'beach',
        'color': '#6C63FF',
        'target_amount': 5000.0,
      };

      when(
        mockDataSource.createGoal(expectedPayload),
      ).thenAnswer((_) async => tGoalModel);

      await repository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
      );

      verify(mockDataSource.createGoal(expectedPayload)).called(1);
    });

    test('incluye deadline formateada (solo fecha) cuando se provee', () async {
      final deadline = DateTime(2025, 12, 31);
      final expectedPayload = <String, dynamic>{
        'name': 'Vacation Fund',
        'icon': 'beach',
        'color': '#6C63FF',
        'target_amount': 5000.0,
        'deadline': '2025-12-31',
      };

      when(
        mockDataSource.createGoal(expectedPayload),
      ).thenAnswer((_) async => tGoalModel);

      await repository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
        deadline: deadline,
      );

      verify(mockDataSource.createGoal(expectedPayload)).called(1);
    });
  });

  group('updateGoal', () {
    test('pasa el id y los datos al datasource', () async {
      final updateData = <String, dynamic>{'name': 'Updated Goal'};
      when(
        mockDataSource.updateGoal('goal-1', updateData),
      ).thenAnswer((_) async => tGoalModel);

      await repository.updateGoal('goal-1', updateData);

      verify(mockDataSource.updateGoal('goal-1', updateData)).called(1);
    });
  });

  group('deleteGoal', () {
    test('delega al datasource con el id correcto', () async {
      when(
        mockDataSource.deleteGoal('goal-1'),
      ).thenAnswer((_) async => Future<void>.value());

      await repository.deleteGoal('goal-1');

      verify(mockDataSource.deleteGoal('goal-1')).called(1);
    });
  });

  group('addContribution', () {
    test('construye payload con amount y date formateada', () async {
      final date = DateTime(2024, 3, 15);
      final expectedPayload = <String, dynamic>{
        'amount': 200.0,
        'date': '2024-03-15',
        'note': 'Monthly saving',
      };

      when(
        mockDataSource.addContribution('goal-1', expectedPayload),
      ).thenAnswer((_) async => tContributionModel);

      final result = await repository.addContribution(
        goalId: 'goal-1',
        amount: 200.0,
        date: date,
        note: 'Monthly saving',
      );

      expect(result, isA<GoalContributionEntity>());
      expect(result.amount, 200.0);
      verify(
        mockDataSource.addContribution('goal-1', expectedPayload),
      ).called(1);
    });
  });

  group('getContributions', () {
    test('delega al datasource y retorna lista de entidades', () async {
      when(
        mockDataSource.getContributions('goal-1'),
      ).thenAnswer((_) async => [tContributionModel]);

      final result = await repository.getContributions('goal-1');

      expect(result, isA<List<GoalContributionEntity>>());
      expect(result.first.id, 'contrib-1');
    });
  });

  group('getRecommendations', () {
    test('delega al datasource y retorna el mapa', () async {
      final tRec = <String, dynamic>{'recommendation': 'Save more'};
      when(mockDataSource.getRecommendations()).thenAnswer((_) async => tRec);

      final result = await repository.getRecommendations();

      expect(result, tRec);
      verify(mockDataSource.getRecommendations()).called(1);
    });
  });
}
