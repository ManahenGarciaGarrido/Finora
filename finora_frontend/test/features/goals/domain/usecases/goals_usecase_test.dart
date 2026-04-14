import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:finora_frontend/features/goals/domain/entities/goal_contribution_entity.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/domain/repositories/goals_repository.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goals_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/create_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/delete_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goal_progress_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/add_contribution_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_contributions_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_recommendations_usecase.dart';

// Mock manual: GoalsRepository es abstracta, no requiere build_runner
class MockGoalsRepository extends Mock implements GoalsRepository {}

void main() {
  late MockGoalsRepository mockRepository;

  // ── Fixtures ─────────────────────────────────────────────────────────────────
  final tGoal = SavingsGoalEntity(
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

  final tContribution = GoalContributionEntity(
    id: 'contrib-1',
    goalId: 'goal-1',
    userId: 'user-1',
    amount: 200.0,
    date: DateTime(2024, 3, 15),
    createdAt: DateTime(2024, 3, 15),
    updatedAt: DateTime(2024, 3, 15),
  );

  setUp(() {
    mockRepository = MockGoalsRepository();
  });

  // ── GetGoalsUseCase ───────────────────────────────────────────────────────────
  group('GetGoalsUseCase', () {
    late GetGoalsUseCase useCase;

    setUp(() => useCase = GetGoalsUseCase(mockRepository));

    test('call() delega a repository.getGoals() y retorna la lista', () async {
      when(mockRepository.getGoals()).thenAnswer((_) async => [tGoal]);

      final result = await useCase();

      expect(result, isA<List<SavingsGoalEntity>>());
      expect(result.length, 1);
      expect(result.first.id, 'goal-1');
      verify(mockRepository.getGoals()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('call() propaga excepción del repositorio', () async {
      when(mockRepository.getGoals()).thenThrow(Exception('Server error'));

      expect(useCase(), throwsException);
    });
  });

  // ── CreateGoalUseCase ─────────────────────────────────────────────────────────
  group('CreateGoalUseCase', () {
    late CreateGoalUseCase useCase;

    setUp(() => useCase = CreateGoalUseCase(mockRepository));

    test('call() delega a repository.createGoal() con los parámetros correctos',
        () async {
      when(mockRepository.createGoal(
        name: anyNamed('name'),
        icon: anyNamed('icon'),
        color: anyNamed('color'),
        targetAmount: anyNamed('targetAmount'),
        deadline: anyNamed('deadline'),
        category: anyNamed('category'),
        notes: anyNamed('notes'),
        monthlyTarget: anyNamed('monthlyTarget'),
      )).thenAnswer((_) async => tGoal);

      final result = await useCase(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
      );

      expect(result.name, 'Vacation Fund');
      verify(mockRepository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
      )).called(1);
    });

    test('call() pasa deadline y notes cuando se proveen', () async {
      final deadline = DateTime(2025, 12, 31);
      when(mockRepository.createGoal(
        name: anyNamed('name'),
        icon: anyNamed('icon'),
        color: anyNamed('color'),
        targetAmount: anyNamed('targetAmount'),
        deadline: anyNamed('deadline'),
        category: anyNamed('category'),
        notes: anyNamed('notes'),
        monthlyTarget: anyNamed('monthlyTarget'),
      )).thenAnswer((_) async => tGoal);

      await useCase(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
        deadline: deadline,
        notes: 'My dream trip',
        monthlyTarget: 500.0,
      );

      verify(mockRepository.createGoal(
        name: 'Vacation Fund',
        icon: 'beach',
        color: '#6C63FF',
        targetAmount: 5000.0,
        deadline: deadline,
        notes: 'My dream trip',
        monthlyTarget: 500.0,
      )).called(1);
    });
  });

  // ── DeleteGoalUseCase ─────────────────────────────────────────────────────────
  group('DeleteGoalUseCase', () {
    late DeleteGoalUseCase useCase;

    setUp(() => useCase = DeleteGoalUseCase(mockRepository));

    test('call(id) delega a repository.deleteGoal() con el id correcto', () async {
      when(mockRepository.deleteGoal('goal-1')).thenAnswer((_) async {});

      await useCase('goal-1');

      verify(mockRepository.deleteGoal('goal-1')).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('call(id) propaga excepción del repositorio', () async {
      when(mockRepository.deleteGoal(any)).thenThrow(Exception('Not found'));

      expect(useCase('goal-999'), throwsException);
    });
  });

  // ── GetGoalProgressUseCase ────────────────────────────────────────────────────
  group('GetGoalProgressUseCase', () {
    late GetGoalProgressUseCase useCase;

    setUp(() => useCase = GetGoalProgressUseCase(mockRepository));

    test('call(id) retorna el mapa de progreso', () async {
      final tProgress = {'percentage': 20, 'remaining_amount': 4000.0};
      when(mockRepository.getGoalProgress('goal-1'))
          .thenAnswer((_) async => tProgress);

      final result = await useCase('goal-1');

      expect(result['percentage'], 20);
      verify(mockRepository.getGoalProgress('goal-1')).called(1);
    });
  });

  // ── AddContributionUseCase ────────────────────────────────────────────────────
  group('AddContributionUseCase', () {
    late AddContributionUseCase useCase;

    setUp(() => useCase = AddContributionUseCase(mockRepository));

    test('call() delega a repository.addContribution()', () async {
      when(mockRepository.addContribution(
        goalId: anyNamed('goalId'),
        amount: anyNamed('amount'),
        date: anyNamed('date'),
        note: anyNamed('note'),
        bankAccountId: anyNamed('bankAccountId'),
      )).thenAnswer((_) async => tContribution);

      final result = await useCase(goalId: 'goal-1', amount: 200.0);

      expect(result, isA<GoalContributionEntity>());
      expect(result.amount, 200.0);
      verify(mockRepository.addContribution(
        goalId: 'goal-1',
        amount: 200.0,
      )).called(1);
    });
  });

  // ── GetContributionsUseCase ───────────────────────────────────────────────────
  group('GetContributionsUseCase', () {
    late GetContributionsUseCase useCase;

    setUp(() => useCase = GetContributionsUseCase(mockRepository));

    test('call(goalId) retorna lista de contribuciones', () async {
      when(mockRepository.getContributions('goal-1'))
          .thenAnswer((_) async => [tContribution]);

      final result = await useCase('goal-1');

      expect(result.length, 1);
      expect(result.first.id, 'contrib-1');
      verify(mockRepository.getContributions('goal-1')).called(1);
    });
  });

  // ── GetRecommendationsUseCase ─────────────────────────────────────────────────
  group('GetRecommendationsUseCase', () {
    late GetRecommendationsUseCase useCase;

    setUp(() => useCase = GetRecommendationsUseCase(mockRepository));

    test('call() retorna mapa de recomendaciones IA', () async {
      final tRec = {'recommendation': 'Increase savings by 10%'};
      when(mockRepository.getRecommendations()).thenAnswer((_) async => tRec);

      final result = await useCase();

      expect(result['recommendation'], 'Increase savings by 10%');
      verify(mockRepository.getRecommendations()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
