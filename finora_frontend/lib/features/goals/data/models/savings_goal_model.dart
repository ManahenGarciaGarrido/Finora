import '../../domain/entities/savings_goal_entity.dart';

class SavingsGoalModel extends SavingsGoalEntity {
  const SavingsGoalModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    required super.color,
    required super.targetAmount,
    required super.currentAmount,
    super.deadline,
    super.category,
    super.notes,
    required super.status,
    required super.percentage,
    required super.percentageDecimal,
    required super.remainingAmount,
    required super.progressColor,
    required super.isCompleted,
    super.projectedCompletionDate,
    super.monthlyTarget,
    super.aiFeasibility,
    super.aiExplanation,
    super.completedAt,
    required super.createdAt,
    required super.updatedAt,
    super.contributionsCount,
  });

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    final pct = (json['percentage'] as num?)?.toInt() ?? 0;
    final pctDecimal =
        (json['percentage_decimal'] as num?)?.toDouble() ??
        (json['percentageDecimal'] as num?)?.toDouble() ??
        (pct / 100.0);

    return SavingsGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'other',
      color: json['color'] as String? ?? '#6C63FF',
      targetAmount: (json['target_amount'] as num).toDouble(),
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      percentage: pct,
      percentageDecimal: pctDecimal,
      remainingAmount:
          (json['remaining_amount'] as num?)?.toDouble() ??
          (json['remainingAmount'] as num?)?.toDouble() ??
          0.0,
      progressColor:
          json['progress_color'] as String? ??
          json['progressColor'] as String? ??
          '#ef4444',
      isCompleted:
          json['is_completed'] as bool? ??
          json['isCompleted'] as bool? ??
          false,
      projectedCompletionDate:
          json['projected_completion_date'] as String? ??
          json['projectedCompletionDate'] as String?,
      monthlyTarget: (json['monthly_target'] as num?)?.toDouble(),
      aiFeasibility: json['ai_feasibility'] as String?,
      aiExplanation: json['ai_explanation'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contributionsCount: (json['contributions_count'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'icon': icon,
    'color': color,
    'target_amount': targetAmount,
    'current_amount': currentAmount,
    'deadline': deadline?.toIso8601String().split('T').first,
    'category': category,
    'notes': notes,
    'status': status,
    'monthly_target': monthlyTarget,
  };
}
