import '../entities/streak_entity.dart';
import '../entities/badge_entity.dart';
import '../entities/challenge_entity.dart';
import '../entities/health_score_entity.dart';

abstract class GamificationRepository {
  Future<List<StreakEntity>> getStreaks();
  Future<StreakEntity> recordStreak(String streakType);
  Future<List<BadgeEntity>> getBadges();
  Future<List<String>> checkAndAwardBadges();
  Future<List<ChallengeEntity>> getChallenges();
  Future<void> joinChallenge(String challengeId);
  Future<void> updateChallengeProgress(String challengeId, double progress);
  Future<HealthScoreEntity> getHealthScore();
}
