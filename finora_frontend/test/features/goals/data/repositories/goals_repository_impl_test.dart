import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/goals/data/datasources/goals_remote_datasource.dart';
import 'package:finora_frontend/features/goals/data/models/goal_contribution_model.dart';
import 'package:finora_frontend/features/goals/data/models/savings_goal_model.dart';
import 'package:finora_frontend/features/goals/data/repositories/goals_repository_impl.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/domain/entities/goal_contribution_entity.dart';

// Mock manual: GoalsRemoteDataSource es abstracta, no requiere build_runner
class MockGoalsRemoteDataSource extends Mock implements GoalsRemoteDataSource {}

void main() {
  late MockGoalsRemoteDataSource mockDataSource;
  late GoalsRepositoryImpl repository;

  // ── Fixtures ─────────────────────────────────────────────────────────────────
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

  // ── getGoals ─────────────────────────────────────────────────────────────────
  group('getGoals', () {
    test('delega al datasource y retorna la lista de entidades', () async {
      when(mockDataSource.getGoals()).thenAnswer((_) async => [tGoalModel]);

      final result = await repository.getGoals();

      expect(result, isA<List<SavingsGoalEntity>>());
      expect(result.length, 1);
      expect(result.first.id, 'goal-1');
      verify(mockDataSource.getGoals()).called(1);
      verifyNoMoreInteractions(mockDataSource);
    });

    test('propaga excepción del datasource', () async {
      when(mockDataSource.getGoals()).thenThrow(Exception('Server error'));

      expect(repository.getGoals(), throwsException);
    });
  });

  // ── getGoal ──────────────────────────────────────────────────────────────────
  group('getGoal', () {
    test('delega al datasource con el id correcto', () async {
      when(mockDataSource.getGoal('goal-1')).thenAnswer((_) async => tGoalModel);

      final result = await repository.getGoal('goal-1');

      expect(result.id, 'goal-1');
      verify(mockDataSource.getGoal('goal-1')).called(1);
    });
  });

  // ── createGoal ───────────────────────────────────────────────────────────────
  group('createGoal', () {
    test('construye el payload correcto con campos obligatorios', () async {
      when(mockDataSource.createGoal(any)).thenAnswer((_) async => tGoalModel);

      await repository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
      );

      final captured =
          verify(mockDataSource.createGoal(captureAny)).captured.first
              as Map<String, dynamic>;

      expect(captured['name'], 'Vacation Fund');
      expect(captured['icon'], 'beach');
      expect(captured['color'], '#6C63FF');
      expect(captured['target_amount'], 5000.0);
      // Campos opcionales no deben estar presentes si no se pasan
      expect(captured.containsKey('deadline'), isFalse);
      expect(captured.containsKey('category'), isFalse);
      expect(captured.containsKey('notes'), isFalse);
      expect(captured.containsKey('monthly_target'), isFalse);
    });

    test('incluye deadline formateada (solo fecha) cuando se provee', () async {
      when(mockDataSource.createGoal(any)).thenAnswer((_) async => tGoalModel);
      final deadline = DateTime(2025, 12, 31);

      await repository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
        deadline: deadline,
      );

      final captured =
          verify(mockDataSource.createGoal(captureAny)).captured.first
              as Map<String, dynamic>;

      expect(captured['deadline'], '2025-12-31');
    });

    test('incluye notes y monthlyTarget cuando se proveen', () async {
      when(mockDataSource.createGoal(any)).thenAnswer((_) async => tGoalModel);

      await repository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
        notes: 'My dream trip',
        monthlyTarget: 500.0,
      );

      final captured =
          verify(mockDataSource.createGoal(captureAny)).captured.first
              as Map<String, dynamic>;

      expect(captured['notes'], 'My dream trip');
      expect(captured['monthly_target'], 500.0);
    });
  });

  // ── updateGoal ───────────────────────────────────────────────────────────────
  group('updateGoal', () {
    test('pasa el id y los datos al datasource', () async {
      final updateData = {'name': 'Updated Goal'};
      when(mockDataSource.updateGoal('goal-1', updateData))
          .thenAnswer((_) async => tGoalModel);

      await repository.updateGoal('goal-1', updateData);

      verify(mockDataSource.updateGoal('goal-1', updateData)).called(1);
    });
  });

  // ── deleteGoal ───────────────────────────────────────────────────────────────
  group('deleteGoal', () {
    test('delega al datasource con el id correcto', () async {
      when(mockDataSource.deleteGoal('goal-1')).thenAnswer((_) async {});

      await repository.deleteGoal('goal-1');

      verify(mockDataSource.deleteGoal('goal-1')).called(1);
      verifyNoMoreInteractions(mockDataSource);
    });
  });

  // ── addContribution ──────────────────────────────────────────────────────────
  group('addContribution', () {
    test('construye payload con amount y date formateada', () async {
      when(mockDataSource.addContribution(any, any))
          .thenAnswer((_) async => tContributionModel);
      final date = DateTime(2024, 3, 15);

      final result = await repository.addContribution(
        goalId: 'goal-1',
        amount: 200.0,
        date: date,
        note: 'Monthly saving',
      );

      expect(result, isA<GoalContributionEntity>());
      expect(result.amount, 200.0);

      final capturedArgs =
          verify(mockDataSource.addContribution(captureAny, captureAny))
              .captured;
      expect(capturedArgs[0], 'goal-1');
      final payload = capturedArgs[1] as Map<String, dynamic>;
      expect(payload['amount'], 200.0);
      expect(payload['date'], '2024-03-15');
      expect(payload['note'], 'Monthly saving');
    });

    test('payload no incluye date si no se pasa', () async {
      when(mockDataSource.addContribution(any, any))
          .thenAnswer((_) async => tContributionModel);

      await repository.addContribution(goalId: 'goal-1', amount: 200.0);

      final capturedArgs =
          verify(mockDataSource.addContribution(captureAny, captureAny))
              .captured;
      final payload = capturedArgs[1] as Map<String, dynamic>;
      expect(payload.containsKey('date'), isFalse);
    });
  });

  // ── getContributions ─────────────────────────────────────────────────────────
  group('getContributions', () {
    test('delega al datasource y retorna lista de entidades', () async {
      when(mockDataSource.getContributions('goal-1'))
          .thenAnswer((_) async => [tContributionModel]);

      final result = await repository.getContributions('goal-1');

      expect(result, isA<List<GoalContributionEntity>>());
      expect(result.first.id, 'contrib-1');
    });
  });

  // ── getRecommendations ───────────────────────────────────────────────────────
  group('getRecommendations', () {
    test('delega al datasource y retorna el mapa', () async {
      final tRec = {'recommendation': 'Save more'};
      when(mockDataSource.getRecommendations()).thenAnswer((_) async => tRec);

      final result = await repository.getRecommendations();

      expect(result, tRec);
      verify(mockDataSource.getRecommendations()).called(1);
    });
  });
}
