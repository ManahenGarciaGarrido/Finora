import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/domain/entities/goal_contribution_entity.dart';
import 'package:finora_frontend/features/goals/domain/repositories/goals_repository.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goals_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/create_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/update_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/delete_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goal_progress_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/add_contribution_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_contributions_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/delete_contribution_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_recommendations_usecase.dart';

@GenerateMocks([GoalsRepository])
import 'goal_usecases_test.mocks.dart';

void main() {
  late MockGoalsRepository mockRepository;

  final now = DateTime(2026, 4, 9);

  final testGoal = SavingsGoalEntity(
    id: 'goal-1',
    userId: 'user-1',
    name: 'Emergency Fund',
    icon: '🏦',
    color: '#4CAF50',
    targetAmount: 10000.0,
    currentAmount: 2500.0,
    deadline: DateTime(2027, 1, 1),
    category: 'savings',
    notes: 'Build 6-month emergency fund',
    status: 'active',
    percentage: 25,
    percentageDecimal: 0.25,
    remainingAmount: 7500.0,
    progressColor: '#FF9800',
    isCompleted: false,
    projectedCompletionDate: '2027-06-01',
    monthlyTarget: 500.0,
    aiFeasibility: 'viable',
    aiExplanation: 'Achievable with current savings rate',
    createdAt: now,
    updatedAt: now,
    contributionsCount: 5,
  );

  final testGoal2 = SavingsGoalEntity(
    id: 'goal-2',
    userId: 'user-1',
    name: 'Vacation',
    icon: '✈️',
    color: '#2196F3',
    targetAmount: 3000.0,
    currentAmount: 3000.0,
    status: 'completed',
    percentage: 100,
    percentageDecimal: 1.0,
    remainingAmount: 0.0,
    progressColor: '#4CAF50',
    isCompleted: true,
    createdAt: now,
    updatedAt: now,
  );

  final testContribution = GoalContributionEntity(
    id: 'contrib-1',
    goalId: 'goal-1',
    userId: 'user-1',
    amount: 500.0,
    date: now,
    note: 'Monthly contribution',
    createdAt: now,
    updatedAt: now,
  );

  final testProgress = <String, dynamic>{
    'goal_id': 'goal-1',
    'percentage': 25,
    'current_amount': 2500.0,
    'target_amount': 10000.0,
    'remaining_amount': 7500.0,
    'is_completed': false,
    'projected_completion_date': '2027-06-01',
  };

  final testRecommendations = <String, dynamic>{
    'recommendations': [
      {
        'goal_id': 'goal-1',
        'suggestion': 'Increase monthly savings by 10%',
        'priority': 'high',
      },
    ],
    'total_goals': 2,
    'on_track': 1,
  };

  setUp(() {
    mockRepository = MockGoalsRepository();
  });

  // ── GetGoalsUseCase ───────────────────────────────────────────────────────────

  group('GetGoalsUseCase', () {
    late GetGoalsUseCase useCase;

    setUp(() {
      useCase = GetGoalsUseCase(mockRepository);
    });

    test('calls repository.getGoals() and returns list of goals', () async {
      when(
        mockRepository.getGoals(),
      ).thenAnswer((_) async => [testGoal, testGoal2]);

      final result = await useCase();

      expect(result, [testGoal, testGoal2]);
      verify(mockRepository.getGoals()).called(1);
    });

    test('returns empty list when no goals exist', () async {
      when(mockRepository.getGoals()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
      verify(mockRepository.getGoals()).called(1);
    });

    test('propagates exception thrown by repository', () async {
      when(mockRepository.getGoals()).thenThrow(Exception('Server error'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── CreateGoalUseCase ─────────────────────────────────────────────────────────

  group('CreateGoalUseCase', () {
    late CreateGoalUseCase useCase;

    setUp(() {
      useCase = CreateGoalUseCase(mockRepository);
    });

    test(
      'calls repository.createGoal() with correct params and returns goal',
      () async {
        when(
          mockRepository.createGoal(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
            targetAmount: anyNamed('targetAmount'),
            deadline: anyNamed('deadline'),
            category: anyNamed('category'),
            notes: anyNamed('notes'),
            monthlyTarget: anyNamed('monthlyTarget'),
          ),
        ).thenAnswer((_) async => testGoal);

        final result = await useCase(
          name: 'Emergency Fund',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 10000.0,
          deadline: DateTime(2027, 1, 1),
          category: 'savings',
          notes: 'Build 6-month emergency fund',
          monthlyTarget: 500.0,
        );

        expect(result, testGoal);
        verify(
          mockRepository.createGoal(
            name: 'Emergency Fund',
            icon: '🏦',
            color: '#4CAF50',
            targetAmount: 10000.0,
            deadline: DateTime(2027, 1, 1),
            category: 'savings',
            notes: 'Build 6-month emergency fund',
            monthlyTarget: 500.0,
          ),
        ).called(1);
      },
    );

    test(
      'propagates exception when name is missing (validation failure)',
      () async {
        when(
          mockRepository.createGoal(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
            targetAmount: anyNamed('targetAmount'),
            deadline: anyNamed('deadline'),
            category: anyNamed('category'),
            notes: anyNamed('notes'),
            monthlyTarget: anyNamed('monthlyTarget'),
          ),
        ).thenThrow(Exception('Name is required'));

        expect(
          () => useCase(
            name: '',
            icon: '🏦',
            color: '#4CAF50',
            targetAmount: 10000.0,
          ),
          throwsException,
        );
      },
    );

    test('passes optional fields as null when not provided', () async {
      when(
        mockRepository.createGoal(
          name: anyNamed('name'),
          icon: anyNamed('icon'),
          color: anyNamed('color'),
          targetAmount: anyNamed('targetAmount'),
          deadline: anyNamed('deadline'),
          category: anyNamed('category'),
          notes: anyNamed('notes'),
          monthlyTarget: anyNamed('monthlyTarget'),
        ),
      ).thenAnswer((_) async => testGoal);

      await useCase(
        name: 'Emergency Fund',
        icon: '🏦',
        color: '#4CAF50',
        targetAmount: 10000.0,
      );

      verify(
        mockRepository.createGoal(
          name: 'Emergency Fund',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 10000.0,
          deadline: null,
          category: null,
          notes: null,
          monthlyTarget: null,
        ),
      ).called(1);
    });
  });

  // ── UpdateGoalUseCase ─────────────────────────────────────────────────────────

  group('UpdateGoalUseCase', () {
    late UpdateGoalUseCase useCase;

    setUp(() {
      useCase = UpdateGoalUseCase(mockRepository);
    });

    test(
      'calls repository.updateGoal() with id and data, returns updated goal',
      () async {
        final updatedGoal = SavingsGoalEntity(
          id: 'goal-1',
          userId: 'user-1',
          name: 'Updated Emergency Fund',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 15000.0,
          currentAmount: 2500.0,
          status: 'active',
          percentage: 17,
          percentageDecimal: 0.17,
          remainingAmount: 12500.0,
          progressColor: '#F44336',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        );

        when(
          mockRepository.updateGoal(any, any),
        ).thenAnswer((_) async => updatedGoal);

        final result = await useCase('goal-1', {
          'name': 'Updated Emergency Fund',
          'target_amount': 15000.0,
        });

        expect(result, updatedGoal);
        verify(
          mockRepository.updateGoal('goal-1', {
            'name': 'Updated Emergency Fund',
            'target_amount': 15000.0,
          }),
        ).called(1);
      },
    );

    test('propagates exception when goal is not found', () async {
      when(
        mockRepository.updateGoal(any, any),
      ).thenThrow(Exception('Goal not found'));

      expect(() => useCase('nonexistent-id', {'name': 'X'}), throwsException);
    });
  });

  // ── DeleteGoalUseCase ─────────────────────────────────────────────────────────

  group('DeleteGoalUseCase', () {
    late DeleteGoalUseCase useCase;

    setUp(() {
      useCase = DeleteGoalUseCase(mockRepository);
    });

    test('calls repository.deleteGoal() with correct id', () async {
      when(mockRepository.deleteGoal(any)).thenAnswer((_) async {
        return;
      });

      await useCase('goal-1');

      verify(mockRepository.deleteGoal('goal-1')).called(1);
    });

    test('propagates exception on server error', () async {
      when(
        mockRepository.deleteGoal(any),
      ).thenThrow(Exception('Delete failed'));

      expect(() => useCase('goal-1'), throwsException);
    });
  });

  // ── GetGoalProgressUseCase ────────────────────────────────────────────────────

  group('GetGoalProgressUseCase', () {
    late GetGoalProgressUseCase useCase;

    setUp(() {
      useCase = GetGoalProgressUseCase(mockRepository);
    });

    test(
      'calls repository.getGoalProgress() and returns progress map',
      () async {
        when(
          mockRepository.getGoalProgress(any),
        ).thenAnswer((_) async => testProgress);

        final result = await useCase('goal-1');

        expect(result, testProgress);
        verify(mockRepository.getGoalProgress('goal-1')).called(1);
      },
    );

    test('returns progress with is_completed=true when goal is done', () async {
      final completedProgress = <String, dynamic>{
        'goal_id': 'goal-1',
        'percentage': 100,
        'current_amount': 10000.0,
        'target_amount': 10000.0,
        'remaining_amount': 0.0,
        'is_completed': true,
      };

      when(
        mockRepository.getGoalProgress(any),
      ).thenAnswer((_) async => completedProgress);

      final result = await useCase('goal-1');

      expect(result['is_completed'], isTrue);
      expect(result['percentage'], 100);
    });

    test('propagates exception when goal not found', () async {
      when(
        mockRepository.getGoalProgress(any),
      ).thenThrow(Exception('Goal not found'));

      expect(() => useCase('nonexistent'), throwsException);
    });
  });

  // ── AddContributionUseCase ────────────────────────────────────────────────────

  group('AddContributionUseCase', () {
    late AddContributionUseCase useCase;

    setUp(() {
      useCase = AddContributionUseCase(mockRepository);
    });

    test(
      'calls repository.addContribution() with correct params and returns contribution',
      () async {
        when(
          mockRepository.addContribution(
            goalId: anyNamed('goalId'),
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            note: anyNamed('note'),
            bankAccountId: anyNamed('bankAccountId'),
          ),
        ).thenAnswer((_) async => testContribution);

        final result = await useCase(
          goalId: 'goal-1',
          amount: 500.0,
          date: now,
          note: 'Monthly contribution',
          bankAccountId: 'bank-1',
        );

        expect(result, testContribution);
        verify(
          mockRepository.addContribution(
            goalId: 'goal-1',
            amount: 500.0,
            date: now,
            note: 'Monthly contribution',
            bankAccountId: 'bank-1',
          ),
        ).called(1);
      },
    );

    test('propagates exception when amount is not positive', () async {
      when(
        mockRepository.addContribution(
          goalId: anyNamed('goalId'),
          amount: anyNamed('amount'),
          date: anyNamed('date'),
          note: anyNamed('note'),
          bankAccountId: anyNamed('bankAccountId'),
        ),
      ).thenThrow(Exception('Amount must be greater than zero'));

      expect(() => useCase(goalId: 'goal-1', amount: -50.0), throwsException);
    });

    test('accepts optional fields as null', () async {
      when(
        mockRepository.addContribution(
          goalId: anyNamed('goalId'),
          amount: anyNamed('amount'),
          date: anyNamed('date'),
          note: anyNamed('note'),
          bankAccountId: anyNamed('bankAccountId'),
        ),
      ).thenAnswer((_) async => testContribution);

      final result = await useCase(goalId: 'goal-1', amount: 200.0);

      expect(result, testContribution);
      verify(
        mockRepository.addContribution(
          goalId: 'goal-1',
          amount: 200.0,
          date: null,
          note: null,
          bankAccountId: null,
        ),
      ).called(1);
    });
  });

  // ── GetContributionsUseCase ───────────────────────────────────────────────────

  group('GetContributionsUseCase', () {
    late GetContributionsUseCase useCase;

    setUp(() {
      useCase = GetContributionsUseCase(mockRepository);
    });

    test(
      'calls repository.getContributions() and returns contribution list',
      () async {
        when(
          mockRepository.getContributions(any),
        ).thenAnswer((_) async => [testContribution]);

        final result = await useCase('goal-1');

        expect(result, [testContribution]);
        verify(mockRepository.getContributions('goal-1')).called(1);
      },
    );

    test('returns empty list when goal has no contributions', () async {
      when(mockRepository.getContributions(any)).thenAnswer((_) async => []);

      final result = await useCase('goal-1');

      expect(result, isEmpty);
    });

    test('propagates exception on repository error', () async {
      when(
        mockRepository.getContributions(any),
      ).thenThrow(Exception('Network error'));

      expect(() => useCase('goal-1'), throwsException);
    });
  });

  // ── DeleteContributionUseCase ─────────────────────────────────────────────────

  group('DeleteContributionUseCase', () {
    late DeleteContributionUseCase useCase;

    setUp(() {
      useCase = DeleteContributionUseCase(mockRepository);
    });

    test(
      'calls repository.deleteContribution() with goalId and contributionId',
      () async {
        when(mockRepository.deleteContribution(any, any)).thenAnswer((_) async {
          return;
        });

        await useCase('goal-1', 'contrib-1');

        verify(
          mockRepository.deleteContribution('goal-1', 'contrib-1'),
        ).called(1);
      },
    );

    test('propagates exception when contribution not found', () async {
      when(
        mockRepository.deleteContribution(any, any),
      ).thenThrow(Exception('Contribution not found'));

      expect(() => useCase('goal-1', 'nonexistent'), throwsException);
    });
  });

  // ── GetRecommendationsUseCase ─────────────────────────────────────────────────

  group('GetRecommendationsUseCase', () {
    late GetRecommendationsUseCase useCase;

    setUp(() {
      useCase = GetRecommendationsUseCase(mockRepository);
    });

    test('calls repository.getRecommendations() and returns AI data', () async {
      when(
        mockRepository.getRecommendations(),
      ).thenAnswer((_) async => testRecommendations);

      final result = await useCase();

      expect(result, testRecommendations);
      expect(result['total_goals'], 2);
      verify(mockRepository.getRecommendations()).called(1);
    });

    test('returns map with empty recommendations list', () async {
      final emptyData = <String, dynamic>{
        'recommendations': [],
        'total_goals': 0,
        'on_track': 0,
      };
      when(
        mockRepository.getRecommendations(),
      ).thenAnswer((_) async => emptyData);

      final result = await useCase();

      expect(result['recommendations'], isEmpty);
    });

    test('propagates exception when AI service is unavailable', () async {
      when(
        mockRepository.getRecommendations(),
      ).thenThrow(Exception('AI service unavailable'));

      expect(() => useCase(), throwsException);
    });
  });
}

