import 'package:equatable/equatable.dart';

abstract class GoalEvent extends Equatable {
  const GoalEvent();
  @override
  List<Object?> get props => [];
}

// ── Listar objetivos (RF-18) ───────────────────────────────────────────────────
class LoadGoals extends GoalEvent {
  const LoadGoals();
}

// ── Crear objetivo (RF-18, CU-03) ─────────────────────────────────────────────
class CreateGoal extends GoalEvent {
  final String name;
  final String icon;
  final String color;
  final double targetAmount;
  final DateTime? deadline;
  final String? category;
  final String? notes;
  final double? monthlyTarget;

  const CreateGoal({
    required this.name,
    required this.icon,
    required this.color,
    required this.targetAmount,
    this.deadline,
    this.category,
    this.notes,
    this.monthlyTarget,
  });

  @override
  List<Object?> get props => [
    name,
    icon,
    color,
    targetAmount,
    deadline,
    category,
    notes,
    monthlyTarget,
  ];
}

// ── Actualizar objetivo ────────────────────────────────────────────────────────
class UpdateGoal extends GoalEvent {
  final String id;
  final Map<String, dynamic> data;
  const UpdateGoal(this.id, this.data);
  @override
  List<Object?> get props => [id, data];
}

// ── Eliminar objetivo ──────────────────────────────────────────────────────────
class DeleteGoal extends GoalEvent {
  final String id;
  const DeleteGoal(this.id);
  @override
  List<Object?> get props => [id];
}

// ── Progreso de un objetivo (RF-19) ───────────────────────────────────────────
class LoadGoalProgress extends GoalEvent {
  final String goalId;
  const LoadGoalProgress(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

// ── Añadir aportación (RF-20) ─────────────────────────────────────────────────
class AddContribution extends GoalEvent {
  final String goalId;
  final double amount;
  final DateTime? date;
  final String? note;
  final String? bankAccountId;

  const AddContribution({
    required this.goalId,
    required this.amount,
    this.date,
    this.note,
    this.bankAccountId,
  });

  @override
  List<Object?> get props => [goalId, amount, date, note, bankAccountId];
}

// ── Cargar historial de aportaciones (RF-20) ──────────────────────────────────
class LoadContributions extends GoalEvent {
  final String goalId;
  const LoadContributions(this.goalId);
  @override
  List<Object?> get props => [goalId];
}

// ── Eliminar aportación (RF-20) ────────────────────────────────────────────────
class DeleteContribution extends GoalEvent {
  final String goalId;
  final String contributionId;
  const DeleteContribution(this.goalId, this.contributionId);
  @override
  List<Object?> get props => [goalId, contributionId];
}

// ── Recomendaciones IA (RF-21) ────────────────────────────────────────────────
class LoadRecommendations extends GoalEvent {
  const LoadRecommendations();
}
