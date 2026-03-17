class StreakEntity {
  final String id;
  final String streakType;
  final int currentCount;
  final int longestCount;
  final String? lastActivityDate;

  const StreakEntity({
    required this.id,
    required this.streakType,
    required this.currentCount,
    required this.longestCount,
    this.lastActivityDate,
  });
}
