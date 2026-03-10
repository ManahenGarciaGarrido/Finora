import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_goals_usecase.dart';
import '../../domain/usecases/create_goal_usecase.dart';
import '../../domain/usecases/update_goal_usecase.dart';
import '../../domain/usecases/delete_goal_usecase.dart';
import '../../domain/usecases/get_goal_progress_usecase.dart';
import '../../domain/usecases/add_contribution_usecase.dart';
import '../../domain/usecases/get_contributions_usecase.dart';
import '../../domain/usecases/delete_contribution_usecase.dart';
import '../../domain/usecases/get_recommendations_usecase.dart';
import 'goal_event.dart';
import 'goal_state.dart';

class GoalBloc extends Bloc<GoalEvent, GoalState> {
  final GetGoalsUseCase getGoals;
  final CreateGoalUseCase createGoal;
  final UpdateGoalUseCase updateGoal;
  final DeleteGoalUseCase deleteGoal;
  final GetGoalProgressUseCase getGoalProgress;
  final AddContributionUseCase addContribution;
  final GetContributionsUseCase getContributions;
  final DeleteContributionUseCase deleteContribution;
  final GetRecommendationsUseCase getRecommendations;

  GoalBloc({
    required this.getGoals,
    required this.createGoal,
    required this.updateGoal,
    required this.deleteGoal,
    required this.getGoalProgress,
    required this.addContribution,
    required this.getContributions,
    required this.deleteContribution,
    required this.getRecommendations,
  }) : super(const GoalInitial()) {
    on<LoadGoals>(_onLoadGoals);
    on<CreateGoal>(_onCreateGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);
    on<LoadGoalProgress>(_onLoadGoalProgress);
    on<AddContribution>(_onAddContribution);
    on<LoadContributions>(_onLoadContributions);
    on<DeleteContribution>(_onDeleteContribution);
    on<LoadRecommendations>(_onLoadRecommendations);
  }

  Future<void> _onLoadGoals(LoadGoals event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final goals = await getGoals();
      emit(GoalsLoaded(goals));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onCreateGoal(CreateGoal event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final goal = await createGoal(
        name: event.name,
        icon: event.icon,
        color: event.color,
        targetAmount: event.targetAmount,
        deadline: event.deadline,
        category: event.category,
        notes: event.notes,
        monthlyTarget: event.monthlyTarget,
      );
      // El backend devuelve el análisis IA en la misma respuesta (RF-21)
      // El modelo ya lo deserializa en aiFeasibility/aiExplanation
      emit(GoalCreated(goal));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onUpdateGoal(UpdateGoal event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      final goal = await updateGoal(event.id, event.data);
      emit(GoalUpdated(goal));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onDeleteGoal(DeleteGoal event, Emitter<GoalState> emit) async {
    emit(const GoalLoading());
    try {
      await deleteGoal(event.id);
      emit(GoalDeleted(event.id));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onLoadGoalProgress(
    LoadGoalProgress event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoading());
    try {
      final progress = await getGoalProgress(event.goalId);
      emit(GoalProgressLoaded(progress));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onAddContribution(
    AddContribution event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoading());
    try {
      final contrib = await addContribution(
        goalId: event.goalId,
        amount: event.amount,
        date: event.date,
        note: event.note,
        bankAccountId: event.bankAccountId,
      );
      // Recargar progreso actualizado (RF-19: actualización en tiempo real)
      final progress = await getGoalProgress(event.goalId);
      final completed = progress['is_completed'] as bool? ?? false;
      emit(
        ContributionAdded(
          contribution: contrib,
          updatedProgress: progress,
          goalCompleted: completed, // HU-07: confetti si se completa
        ),
      );
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onLoadContributions(
    LoadContributions event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoading());
    try {
      final contribs = await getContributions(event.goalId);
      emit(ContributionsLoaded(contribs));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onDeleteContribution(
    DeleteContribution event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoading());
    try {
      await deleteContribution(event.goalId, event.contributionId);
      emit(ContributionDeleted(event.contributionId));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  Future<void> _onLoadRecommendations(
    LoadRecommendations event,
    Emitter<GoalState> emit,
  ) async {
    emit(const GoalLoading());
    try {
      final data = await getRecommendations();
      emit(RecommendationsLoaded(data));
    } catch (e) {
      emit(GoalError(_message(e)));
    }
  }

  String _message(Object e) => e.toString().replaceAll('Exception: ', '');
}
