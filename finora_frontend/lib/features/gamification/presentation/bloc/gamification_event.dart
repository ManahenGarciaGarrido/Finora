abstract class GamificationEvent {
  const GamificationEvent();
}

class LoadGamificationData extends GamificationEvent {
  const LoadGamificationData();
}

class RecordStreak extends GamificationEvent {
  final String streakType;
  const RecordStreak(this.streakType);
}

class CheckBadges extends GamificationEvent {
  const CheckBadges();
}

class JoinChallenge extends GamificationEvent {
  final String challengeId;
  const JoinChallenge(this.challengeId);
}

class UpdateChallengeProgress extends GamificationEvent {
  final String challengeId;
  final double progress;
  const UpdateChallengeProgress(this.challengeId, this.progress);
}
