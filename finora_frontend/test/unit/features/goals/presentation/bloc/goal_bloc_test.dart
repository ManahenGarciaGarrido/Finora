import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/domain/entities/goal_contribution_entity.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goals_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/create_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/update_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/delete_goal_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_goal_progress_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/add_contribution_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_contributions_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/delete_contribution_usecase.dart';
import 'package:finora_frontend/features/goals/domain/usecases/get_recommendations_usecase.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_event.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_state.dart';

@GenerateMocks([
  GetGoalsUseCase,
  CreateGoalUseCase,
  UpdateGoalUseCase,
  DeleteGoalUseCase,
  GetGoalProgressUseCase,
  AddContributionUseCase,
  GetContributionsUseCase,
  DeleteContributionUseCase,
  GetRecommendationsUseCase,
])
import 'goal_bloc_test.mocks.dart';

void main() {
  late GoalBloc goalBloc;
  late MockGetGoalsUseCase mockGetGoals;
  late MockCreateGoalUseCase mockCreateGoal;
  late MockUpdateGoalUseCase mockUpdateGoal;
  late MockDeleteGoalUseCase mockDeleteGoal;
  late MockGetGoalProgressUseCase mockGetGoalProgress;
  late MockAddContributionUseCase mockAddContribution;
  late MockGetContributionsUseCase mockGetContributions;
  late MockDeleteContributionUseCase mockDeleteContribution;
  late MockGetRecommendationsUseCase mockGetRecommendations;

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

  final testProgressCompleted = <String, dynamic>{
    'goal_id': 'goal-1',
    'percentage': 100,
    'current_amount': 10000.0,
    'target_amount': 10000.0,
    'remaining_amount': 0.0,
    'is_completed': true,
    'projected_completion_date': null,
  };

  final testRecommendations = <String, dynamic>{
    'recommendations': [
      {
        'goal_id': 'goal-1',
        'suggestion': 'Increase monthly savings by 10%',
        'priority': 'high',
      }
    ],
    'total_goals': 2,
    'on_track': 1,
  };

  setUp(() {
    mockGetGoals = MockGetGoalsUseCase();
    mockCreateGoal = MockCreateGoalUseCase();
    mockUpdateGoal = MockUpdateGoalUseCase();
    mockDeleteGoal = MockDeleteGoalUseCase();
    mockGetGoalProgress = MockGetGoalProgressUseCase();
    mockAddContribution = MockAddContributionUseCase();
    mockGetContributions = MockGetContributionsUseCase();
    mockDeleteContribution = MockDeleteContributionUseCase();
    mockGetRecommendations = MockGetRecommendationsUseCase();

    goalBloc = GoalBloc(
      getGoals: mockGetGoals,
      createGoal: mockCreateGoal,
      updateGoal: mockUpdateGoal,
      deleteGoal: mockDeleteGoal,
      getGoalProgress: mockGetGoalProgress,
      addContribution: mockAddContribution,
      getContributions: mockGetContributions,
      deleteContribution: mockDeleteContribution,
      getRecommendations: mockGetRecommendations,
    );
  });

  tearDown(() {
    goalBloc.close();
  });

  test('initial state is GoalInitial', () {
    expect(goalBloc.state, const GoalInitial());
  });

  // ── LoadGoals ────────────────────────────────────────────────────────────────

  group('LoadGoals', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalsLoaded] when goals are fetched successfully',
      build: () {
        when(mockGetGoals()).thenAnswer(
          (_) async => [testGoal, testGoal2],
        );
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        const GoalLoading(),
        GoalsLoaded([testGoal, testGoal2]),
      ],
      verify: (_) {
        verify(mockGetGoals()).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalsLoaded] with empty list when no goals exist',
      build: () {
        when(mockGetGoals()).thenAnswer((_) async => []);
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        const GoalLoading(),
        const GoalsLoaded([]),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when server throws exception',
      build: () {
        when(mockGetGoals()).thenThrow(Exception('Server error'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadGoals()),
      expect: () => [
        const GoalLoading(),
        const GoalError('Server error'),
      ],
    );
  });

  // ── CreateGoal ───────────────────────────────────────────────────────────────

  group('CreateGoal', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalCreated] when goal creation succeeds',
      build: () {
        when(
          mockCreateGoal(
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
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        CreateGoal(
          name: 'Emergency Fund',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 10000.0,
          deadline: DateTime(2027, 1, 1),
          category: 'savings',
          notes: 'Build 6-month emergency fund',
          monthlyTarget: 500.0,
        ),
      ),
      expect: () => [
        const GoalLoading(),
        GoalCreated(testGoal),
      ],
      verify: (_) {
        verify(
          mockCreateGoal(
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

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when validation fails (missing name)',
      build: () {
        when(
          mockCreateGoal(
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
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const CreateGoal(
          name: '',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 10000.0,
        ),
      ),
      expect: () => [
        const GoalLoading(),
        const GoalError('Name is required'),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when server error occurs during creation',
      build: () {
        when(
          mockCreateGoal(
            name: anyNamed('name'),
            icon: anyNamed('icon'),
            color: anyNamed('color'),
            targetAmount: anyNamed('targetAmount'),
            deadline: anyNamed('deadline'),
            category: anyNamed('category'),
            notes: anyNamed('notes'),
            monthlyTarget: anyNamed('monthlyTarget'),
          ),
        ).thenThrow(Exception('Internal server error'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const CreateGoal(
          name: 'Emergency Fund',
          icon: '🏦',
          color: '#4CAF50',
          targetAmount: 10000.0,
        ),
      ),
      expect: () => [
        const GoalLoading(),
        const GoalError('Internal server error'),
      ],
    );
  });

  // ── UpdateGoal ───────────────────────────────────────────────────────────────

  group('UpdateGoal', () {
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

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalUpdated] when goal update succeeds',
      build: () {
        when(mockUpdateGoal(any, any)).thenAnswer((_) async => updatedGoal);
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateGoal('goal-1', {'name': 'Updated Emergency Fund', 'target_amount': 15000.0}),
      ),
      expect: () => [
        const GoalLoading(),
        GoalUpdated(updatedGoal),
      ],
      verify: (_) {
        verify(mockUpdateGoal(
          'goal-1',
          {'name': 'Updated Emergency Fund', 'target_amount': 15000.0},
        )).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when goal is not found',
      build: () {
        when(mockUpdateGoal(any, any))
            .thenThrow(Exception('Goal not found'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const UpdateGoal('nonexistent-id', {'name': 'Updated'}),
      ),
      expect: () => [
        const GoalLoading(),
        const GoalError('Goal not found'),
      ],
    );
  });

  // ── DeleteGoal ───────────────────────────────────────────────────────────────

  group('DeleteGoal', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalDeleted] when goal deletion succeeds',
      build: () {
        when(mockDeleteGoal(any)).thenAnswer((_) async {});
        return goalBloc;
      },
      act: (bloc) => bloc.add(const DeleteGoal('goal-1')),
      expect: () => [
        const GoalLoading(),
        const GoalDeleted('goal-1'),
      ],
      verify: (_) {
        verify(mockDeleteGoal('goal-1')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when deletion throws server error',
      build: () {
        when(mockDeleteGoal(any)).thenThrow(Exception('Delete failed'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const DeleteGoal('goal-1')),
      expect: () => [
        const GoalLoading(),
        const GoalError('Delete failed'),
      ],
    );
  });

  // ── LoadGoalProgress ──────────────────────────────────────────────────────────

  group('LoadGoalProgress', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalProgressLoaded] with progress data on success',
      build: () {
        when(mockGetGoalProgress(any)).thenAnswer((_) async => testProgress);
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadGoalProgress('goal-1')),
      expect: () => [
        const GoalLoading(),
        GoalProgressLoaded(testProgress),
      ],
      verify: (_) {
        verify(mockGetGoalProgress('goal-1')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when progress fetch fails',
      build: () {
        when(mockGetGoalProgress(any))
            .thenThrow(Exception('Progress unavailable'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadGoalProgress('goal-1')),
      expect: () => [
        const GoalLoading(),
        const GoalError('Progress unavailable'),
      ],
    );
  });

  // ── AddContribution ───────────────────────────────────────────────────────────

  group('AddContribution', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, ContributionAdded] and reloads progress on success',
      build: () {
        when(
          mockAddContribution(
            goalId: anyNamed('goalId'),
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            note: anyNamed('note'),
            bankAccountId: anyNamed('bankAccountId'),
          ),
        ).thenAnswer((_) async => testContribution);
        when(mockGetGoalProgress(any)).thenAnswer((_) async => testProgress);
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        AddContribution(
          goalId: 'goal-1',
          amount: 500.0,
          date: now,
          note: 'Monthly contribution',
        ),
      ),
      expect: () => [
        const GoalLoading(),
        ContributionAdded(
          contribution: testContribution,
          updatedProgress: testProgress,
          goalCompleted: false,
        ),
      ],
      verify: (_) {
        verify(mockAddContribution(
          goalId: 'goal-1',
          amount: 500.0,
          date: now,
          note: 'Monthly contribution',
          bankAccountId: null,
        )).called(1);
        verify(mockGetGoalProgress('goal-1')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, ContributionAdded] with goalCompleted=true when goal reaches 100%',
      build: () {
        when(
          mockAddContribution(
            goalId: anyNamed('goalId'),
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            note: anyNamed('note'),
            bankAccountId: anyNamed('bankAccountId'),
          ),
        ).thenAnswer((_) async => testContribution);
        when(mockGetGoalProgress(any))
            .thenAnswer((_) async => testProgressCompleted);
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const AddContribution(
          goalId: 'goal-1',
          amount: 7500.0,
        ),
      ),
      expect: () => [
        const GoalLoading(),
        ContributionAdded(
          contribution: testContribution,
          updatedProgress: testProgressCompleted,
          goalCompleted: true,
        ),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when amount validation throws',
      build: () {
        when(
          mockAddContribution(
            goalId: anyNamed('goalId'),
            amount: anyNamed('amount'),
            date: anyNamed('date'),
            note: anyNamed('note'),
            bankAccountId: anyNamed('bankAccountId'),
          ),
        ).thenThrow(Exception('Amount must be greater than zero'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(
        const AddContribution(
          goalId: 'goal-1',
          amount: -100.0,
        ),
      ),
      expect: () => [
        const GoalLoading(),
        const GoalError('Amount must be greater than zero'),
      ],
    );
  });

  // ── LoadContributions ─────────────────────────────────────────────────────────

  group('LoadContributions', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, ContributionsLoaded] with contributions on success',
      build: () {
        when(mockGetContributions(any))
            .thenAnswer((_) async => [testContribution]);
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadContributions('goal-1')),
      expect: () => [
        const GoalLoading(),
        ContributionsLoaded([testContribution]),
      ],
      verify: (_) {
        verify(mockGetContributions('goal-1')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, ContributionsLoaded] with empty list when no contributions',
      build: () {
        when(mockGetContributions(any)).thenAnswer((_) async => []);
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadContributions('goal-1')),
      expect: () => [
        const GoalLoading(),
        const ContributionsLoaded([]),
      ],
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when contributions fetch fails',
      build: () {
        when(mockGetContributions(any))
            .thenThrow(Exception('Failed to load contributions'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadContributions('goal-1')),
      expect: () => [
        const GoalLoading(),
        const GoalError('Failed to load contributions'),
      ],
    );
  });

  // ── DeleteContribution ────────────────────────────────────────────────────────

  group('DeleteContribution', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, ContributionDeleted] when deletion succeeds',
      build: () {
        when(mockDeleteContribution(any, any)).thenAnswer((_) async {});
        return goalBloc;
      },
      act: (bloc) => bloc.add(const DeleteContribution('goal-1', 'contrib-1')),
      expect: () => [
        const GoalLoading(),
        const ContributionDeleted('contrib-1'),
      ],
      verify: (_) {
        verify(mockDeleteContribution('goal-1', 'contrib-1')).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when contribution deletion fails',
      build: () {
        when(mockDeleteContribution(any, any))
            .thenThrow(Exception('Contribution not found'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const DeleteContribution('goal-1', 'contrib-99')),
      expect: () => [
        const GoalLoading(),
        const GoalError('Contribution not found'),
      ],
    );
  });

  // ── LoadRecommendations ───────────────────────────────────────────────────────

  group('LoadRecommendations', () {
    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, RecommendationsLoaded] with AI recommendations on success',
      build: () {
        when(mockGetRecommendations())
            .thenAnswer((_) async => testRecommendations);
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadRecommendations()),
      expect: () => [
        const GoalLoading(),
        RecommendationsLoaded(testRecommendations),
      ],
      verify: (_) {
        verify(mockGetRecommendations()).called(1);
      },
    );

    blocTest<GoalBloc, GoalState>(
      'emits [GoalLoading, GoalError] when recommendations fetch fails',
      build: () {
        when(mockGetRecommendations())
            .thenThrow(Exception('AI service unavailable'));
        return goalBloc;
      },
      act: (bloc) => bloc.add(const LoadRecommendations()),
      expect: () => [
        const GoalLoading(),
        const GoalError('AI service unavailable'),
      ],
    );
  });
}

