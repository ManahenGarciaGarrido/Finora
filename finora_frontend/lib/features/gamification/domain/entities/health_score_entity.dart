class HealthScoreEntity {
  final int score;
  final String grade;
  final int budgetAdherence;
  final int savingsRate;
  final int goalProgress;
  final int streakBonus;

  const HealthScoreEntity({
    required this.score,
    required this.grade,
    required this.budgetAdherence,
    required this.savingsRate,
    required this.goalProgress,
    required this.streakBonus,
  });
}
