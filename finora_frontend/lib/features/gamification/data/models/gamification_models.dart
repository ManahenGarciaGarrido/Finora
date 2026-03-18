import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/health_score_entity.dart';

double _d(dynamic v, [double fallback = 0.0]) =>
    v == null ? fallback : double.tryParse(v.toString()) ?? fallback;

int _i(dynamic v, [int fallback = 0]) =>
    v == null ? fallback : int.tryParse(v.toString()) ?? fallback;

bool _b(dynamic v, [bool fallback = false]) {
  if (v == null) return fallback;
  if (v is bool) return v;
  return v.toString().toLowerCase() == 'true';
}

class StreakModel extends StreakEntity {
  const StreakModel({
    required super.id,
    required super.streakType,
    required super.currentCount,
    required super.longestCount,
    super.lastActivityDate,
  });

  factory StreakModel.fromJson(Map<String, dynamic> j) => StreakModel(
    id: j['id']?.toString() ?? '',
    streakType: j['streak_type']?.toString() ?? '',
    currentCount: _i(j['current_count']),
    longestCount: _i(j['longest_count']),
    lastActivityDate: j['last_activity_date']?.toString(),
  );
}

class BadgeModel extends BadgeEntity {
  const BadgeModel({
    required super.id,
    required super.badgeKey,
    required super.name,
    super.description,
    super.icon,
    super.category,
    required super.isEarned,
    super.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
    id: j['id']?.toString() ?? '',
    badgeKey: j['badge_key']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    description: j['description']?.toString(),
    icon: j['icon']?.toString(),
    category: j['category']?.toString(),
    isEarned: _b(j['is_earned']),
    earnedAt: j['earned_at']?.toString(),
  );
}

class ChallengeModel extends ChallengeEntity {
  const ChallengeModel({
    required super.id,
    required super.title,
    super.description,
    required super.challengeType,
    required super.targetValue,
    required super.rewardPoints,
    required super.isActive,
    super.startsAt,
    super.endsAt,
    required super.progress,
    required super.isCompleted,
    required super.isJoined,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> j) => ChallengeModel(
    id: j['id']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    challengeType: j['challenge_type']?.toString() ?? '',
    targetValue: _d(j['target_value']),
    rewardPoints: _i(j['reward_points']),
    isActive: _b(j['is_active'], true),
    startsAt: j['starts_at']?.toString(),
    endsAt: j['ends_at']?.toString(),
    progress: _d(j['progress']),
    isCompleted: _b(j['is_completed']),
    isJoined: _b(j['is_joined']),
  );
}

class HealthScoreModel extends HealthScoreEntity {
  const HealthScoreModel({
    required super.score,
    required super.grade,
    required super.budgetAdherence,
    required super.savingsRate,
    required super.goalProgress,
    required super.streakBonus,
  });

  factory HealthScoreModel.fromJson(Map<String, dynamic> j) {
    final breakdown = j['breakdown'] as Map<String, dynamic>? ?? {};
    return HealthScoreModel(
      score: _i(j['score']),
      grade: j['grade']?.toString() ?? 'D',
      budgetAdherence: _i(breakdown['budget_adherence']),
      savingsRate: _i(breakdown['savings_rate']),
      goalProgress: _i(breakdown['goal_progress']),
      streakBonus: _i(breakdown['streak_bonus']),
    );
  }
}
