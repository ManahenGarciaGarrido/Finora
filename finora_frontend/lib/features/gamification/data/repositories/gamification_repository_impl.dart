import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/challenge_entity.dart';
import '../../domain/entities/health_score_entity.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_datasource.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationRemoteDataSource _ds;
  GamificationRepositoryImpl(this._ds);

  @override
  Future<List<StreakEntity>> getStreaks() => _ds.getStreaks();

  @override
  Future<StreakEntity> recordStreak(String streakType) =>
      _ds.recordStreak(streakType);

  @override
  Future<List<BadgeEntity>> getBadges() => _ds.getBadges();

  @override
  Future<List<String>> checkAndAwardBadges() => _ds.checkAndAwardBadges();

  @override
  Future<List<ChallengeEntity>> getChallenges() => _ds.getChallenges();

  @override
  Future<void> joinChallenge(String challengeId) =>
      _ds.joinChallenge(challengeId);

  @override
  Future<void> updateChallengeProgress(String challengeId, double progress) =>
      _ds.updateChallengeProgress(challengeId, progress);

  @override
  Future<HealthScoreEntity> getHealthScore() => _ds.getHealthScore();
}
