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

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _toInt(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().split('.').first) ?? fallback;
  }

  factory SavingsGoalModel.fromJson(Map<String, dynamic> json) {
    final pct = _toInt(json['percentage']);
    final pctDecimal =
        _toDouble(json['percentage_decimal'],
            _toDouble(json['percentageDecimal'], pct / 100.0));

    return SavingsGoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? 'other',
      color: json['color'] as String? ?? '#6C63FF',
      targetAmount: _toDouble(json['target_amount']),
      currentAmount: _toDouble(json['current_amount']),
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'].toString())
          : null,
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
      percentage: pct,
      percentageDecimal: pctDecimal,
      remainingAmount: _toDouble(
          json['remaining_amount'] ?? json['remainingAmount']),
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
      monthlyTarget: json['monthly_target'] != null
          ? _toDouble(json['monthly_target'])
          : null,
      aiFeasibility: json['ai_feasibility'] as String?,
      aiExplanation: json['ai_explanation'] as String?,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      contributionsCount: json['contributions_count'] != null
          ? _toInt(json['contributions_count'])
          : null,
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
