import 'package:equatable/equatable.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/goal_contribution_entity.dart';

abstract class GoalState extends Equatable {
  const GoalState();
  @override
  List<Object?> get props => [];
}

// ── Estados de carga ──────────────────────────────────────────────────────────
class GoalInitial extends GoalState {
  const GoalInitial();
}

class GoalLoading extends GoalState {
  const GoalLoading();
}

// ── Lista de objetivos (RF-18, HU-07) ────────────────────────────────────────
class GoalsLoaded extends GoalState {
  final List<SavingsGoalEntity> goals;
  const GoalsLoaded(this.goals);
  @override
  List<Object?> get props => [goals];
}

// ── Objetivo creado (RF-18) ───────────────────────────────────────────────────
class GoalCreated extends GoalState {
  final SavingsGoalEntity goal;

  /// Resultado del análisis IA (RF-21), puede ser null si la IA no respondió
  final Map<String, dynamic>? aiAnalysis;
  const GoalCreated(this.goal, {this.aiAnalysis});
  @override
  List<Object?> get props => [goal, aiAnalysis];
}

// ── Objetivo actualizado ───────────────────────────────────────────────────────
class GoalUpdated extends GoalState {
  final SavingsGoalEntity goal;
  const GoalUpdated(this.goal);
  @override
  List<Object?> get props => [goal];
}

// ── Objetivo eliminado ─────────────────────────────────────────────────────────
class GoalDeleted extends GoalState {
  final String goalId;
  const GoalDeleted(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

// ── Progreso detallado (RF-19) ────────────────────────────────────────────────
class GoalProgressLoaded extends GoalState {
  final Map<String, dynamic> progress;
  const GoalProgressLoaded(this.progress);
  @override
  List<Object?> get props => [progress];
}

// ── Aportación añadida (RF-20) ────────────────────────────────────────────────
class ContributionAdded extends GoalState {
  final GoalContributionEntity contribution;
  final Map<String, dynamic> updatedProgress;
  final bool goalCompleted; // HU-07: dispara confetti si true

  const ContributionAdded({
    required this.contribution,
    required this.updatedProgress,
    required this.goalCompleted,
  });

  @override
  List<Object?> get props => [contribution, updatedProgress, goalCompleted];
}

// ── Historial de aportaciones (RF-20) ─────────────────────────────────────────
class ContributionsLoaded extends GoalState {
  final List<GoalContributionEntity> contributions;
  const ContributionsLoaded(this.contributions);
  @override
  List<Object?> get props => [contributions];
}

// ── Aportación eliminada (RF-20) ───────────────────────────────────────────────
class ContributionDeleted extends GoalState {
  final String contributionId;
  const ContributionDeleted(this.contributionId);
  @override
  List<Object?> get props => [contributionId];
}

// ── Recomendaciones IA (RF-21) ────────────────────────────────────────────────
class RecommendationsLoaded extends GoalState {
  final Map<String, dynamic> data;
  const RecommendationsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

// ── Error ─────────────────────────────────────────────────────────────────────
class GoalError extends GoalState {
  final String message;
  const GoalError(this.message);
  @override
  List<Object?> get props => [message];
}
