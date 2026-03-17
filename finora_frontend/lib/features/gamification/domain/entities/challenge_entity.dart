class ChallengeEntity {
  final String id;
  final String title;
  final String? description;
  final String challengeType;
  final double targetValue;
  final int rewardPoints;
  final bool isActive;
  final String? startsAt;
  final String? endsAt;
  // User participation
  final double progress;
  final bool isCompleted;
  final bool isJoined;

  const ChallengeEntity({
    required this.id,
    required this.title,
    this.description,
    required this.challengeType,
    required this.targetValue,
    required this.rewardPoints,
    required this.isActive,
    this.startsAt,
    this.endsAt,
    required this.progress,
    required this.isCompleted,
    required this.isJoined,
  });

  double get progressPercent =>
      targetValue > 0 ? (progress / targetValue).clamp(0.0, 1.0) : 0.0;
}
