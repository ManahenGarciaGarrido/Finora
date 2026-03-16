import '../entities/savings_goal_entity.dart';
import '../entities/goal_contribution_entity.dart';

abstract class GoalsRepository {
  // RF-18: CRUD de objetivos
  Future<List<SavingsGoalEntity>> getGoals();
  Future<SavingsGoalEntity> getGoal(String id);
  Future<SavingsGoalEntity> createGoal({
    required String name,
    required String icon,
    required String color,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? notes,
    double? monthlyTarget,
  });
  Future<SavingsGoalEntity> updateGoal(String id, Map<String, dynamic> data);
  Future<void> deleteGoal(String id);

  // RF-19: Progreso
  Future<Map<String, dynamic>> getGoalProgress(String id);

  // RF-20: Aportaciones
  Future<GoalContributionEntity> addContribution({
    required String goalId,
    required double amount,
    DateTime? date,
    String? note,
    String? bankAccountId,
  });
  Future<List<GoalContributionEntity>> getContributions(String goalId);
  Future<GoalContributionEntity> updateContribution(
    String goalId,
    String contributionId,
    Map<String, dynamic> data,
  );
  Future<void> deleteContribution(String goalId, String contributionId);

  // RF-21: Recomendaciones IA
  Future<Map<String, dynamic>> getRecommendations();
}
