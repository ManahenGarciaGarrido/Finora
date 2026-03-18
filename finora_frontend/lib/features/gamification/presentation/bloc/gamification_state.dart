import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/health_score_entity.dart';

abstract class GamificationState {
  const GamificationState();
}

class GamificationInitial extends GamificationState {
  const GamificationInitial();
}

class GamificationLoading extends GamificationState {
  const GamificationLoading();
}

class GamificationLoaded extends GamificationState {
  final List<StreakEntity> streaks;
  final List<BadgeEntity> badges;
  final List<ChallengeEntity> challenges;
  final HealthScoreEntity? healthScore;
  const GamificationLoaded({
    required this.streaks,
    required this.badges,
    required this.challenges,
    this.healthScore,
  });
}

class BadgesAwarded extends GamificationState {
  final List<String> awarded;
  const BadgesAwarded(this.awarded);
}

class ChallengeJoined extends GamificationState {
  const ChallengeJoined();
}

class GamificationError extends GamificationState {
  final String message;
  const GamificationError(this.message);
}
