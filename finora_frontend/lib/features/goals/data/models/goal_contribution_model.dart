import '../../domain/entities/goal_contribution_entity.dart';

class GoalContributionModel extends GoalContributionEntity {
  const GoalContributionModel({
    required super.id,
    required super.goalId,
    required super.userId,
    required super.amount,
    required super.date,
    super.note,
    required super.createdAt,
    required super.updatedAt,
  });

  factory GoalContributionModel.fromJson(Map<String, dynamic> json) {
    return GoalContributionModel(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
