/// RF-20: Entidad de aportación a un objetivo de ahorro
class GoalContributionEntity {
  final String id;
  final String goalId;
  final String userId;
  final double amount;
  final DateTime date;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const GoalContributionEntity({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });
}
