/// RF-18: Entidad de objetivo de ahorro
/// RF-19: Incluye métricas de progreso calculadas por el backend
/// HU-07: Color dinámico según progreso
class SavingsGoalEntity {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color; // Hex color personalizable
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? category;
  final String? notes;
  final String status; // active | completed | cancelled

  // RF-19: Métricas de progreso (calculadas por backend)
  final int percentage;
  final double percentageDecimal;
  final double remainingAmount;
  final String progressColor; // HU-07: rojo/amarillo/verde según progreso
  final bool isCompleted;
  final String? projectedCompletionDate;

  // RF-21: Análisis IA
  final double? monthlyTarget;
  final String? aiFeasibility; // viable | difficult | not_viable
  final String? aiExplanation;

  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Número de aportaciones (opcional, de queries enriquecidas)
  final int? contributionsCount;

  const SavingsGoalEntity({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.category,
    this.notes,
    required this.status,
    required this.percentage,
    required this.percentageDecimal,
    required this.remainingAmount,
    required this.progressColor,
    required this.isCompleted,
    this.projectedCompletionDate,
    this.monthlyTarget,
    this.aiFeasibility,
    this.aiExplanation,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.contributionsCount,
  });

  bool get isActive => status == 'active';
  bool get isCancelled => status == 'cancelled';

  /// Devuelve un label corto de viabilidad IA para mostrar en la UI
  String? get feasibilityLabel {
    switch (aiFeasibility) {
      case 'viable':
        return 'Viable';
      case 'difficult':
        return 'Difícil';
      case 'not_viable':
        return 'No viable';
      default:
        return null;
    }
  }
}
