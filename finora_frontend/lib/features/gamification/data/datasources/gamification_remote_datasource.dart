import '../../../../core/network/api_client.dart';
import '../models/gamification_models.dart';

abstract class GamificationRemoteDataSource {
  Future<List<StreakModel>> getStreaks();
  Future<StreakModel> recordStreak(String streakType);
  Future<List<BadgeModel>> getBadges();
  Future<List<String>> checkAndAwardBadges();
  Future<List<ChallengeModel>> getChallenges();
  Future<void> joinChallenge(String challengeId);
  Future<void> updateChallengeProgress(String challengeId, double progress);
  Future<HealthScoreModel> getHealthScore();
}

class GamificationRemoteDataSourceImpl implements GamificationRemoteDataSource {
  final ApiClient _client;
  GamificationRemoteDataSourceImpl(this._client);

  @override
  Future<List<StreakModel>> getStreaks() async {
    final res = await _client.get('/gamification/streaks');
    final list = res.data['streaks'] as List? ?? [];
    return list
        .map((e) => StreakModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StreakModel> recordStreak(String streakType) async {
    final res = await _client.post(
      '/gamification/streaks/record',
      data: {'streak_type': streakType},
    );
    return StreakModel.fromJson(res.data['streak'] as Map<String, dynamic>);
  }

  @override
  Future<List<BadgeModel>> getBadges() async {
    final res = await _client.get('/gamification/badges');
    final list = res.data['badges'] as List? ?? [];
    return list
        .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<String>> checkAndAwardBadges() async {
    final res = await _client.post('/gamification/badges/check', data: {});
    final list = res.data['awarded'] as List? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  @override
  Future<List<ChallengeModel>> getChallenges() async {
    final res = await _client.get('/gamification/challenges');
    final list = res.data['challenges'] as List? ?? [];
    return list
        .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> joinChallenge(String challengeId) async {
    await _client.post('/gamification/challenges/$challengeId/join', data: {});
  }

  @override
  Future<void> updateChallengeProgress(
    String challengeId,
    double progress,
  ) async {
    await _client.patch(
      '/gamification/challenges/$challengeId/progress',
      data: {'progress': progress},
    );
  }

  @override
  Future<HealthScoreModel> getHealthScore() async {
    final res = await _client.get('/gamification/health-score');
    return HealthScoreModel.fromJson(res.data as Map<String, dynamic>);
  }
}
