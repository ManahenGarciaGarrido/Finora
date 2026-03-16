import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/goal_contribution_entity.dart';
import '../../domain/repositories/goals_repository.dart';
import '../datasources/goals_remote_datasource.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final GoalsRemoteDataSource _remote;
  GoalsRepositoryImpl(this._remote);

  @override
  Future<List<SavingsGoalEntity>> getGoals() => _remote.getGoals();

  @override
  Future<SavingsGoalEntity> getGoal(String id) => _remote.getGoal(id);

  @override
  Future<SavingsGoalEntity> createGoal({
    required String name,
    required String icon,
    required String color,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? notes,
    double? monthlyTarget,
  }) => _remote.createGoal({
    'name': name,
    'icon': icon,
    'color': color,
    'target_amount': targetAmount,
    if (deadline != null)
      'deadline': deadline.toIso8601String().split('T').first,
    if (category != null) 'category': category,
    if (notes != null) 'notes': notes,
    if (monthlyTarget != null) 'monthly_target': monthlyTarget,
  });

  @override
  Future<SavingsGoalEntity> updateGoal(String id, Map<String, dynamic> data) =>
      _remote.updateGoal(id, data);

  @override
  Future<void> deleteGoal(String id) => _remote.deleteGoal(id);

  @override
  Future<Map<String, dynamic>> getGoalProgress(String id) =>
      _remote.getGoalProgress(id);

  @override
  Future<GoalContributionEntity> addContribution({
    required String goalId,
    required double amount,
    DateTime? date,
    String? note,
    String? bankAccountId,
  }) => _remote.addContribution(goalId, {
    'amount': amount,
    if (date != null) 'date': date.toIso8601String().split('T').first,
    if (note != null) 'note': note,
    if (bankAccountId != null) 'bank_account_id': bankAccountId,
  });

  @override
  Future<List<GoalContributionEntity>> getContributions(String goalId) =>
      _remote.getContributions(goalId);

  @override
  Future<GoalContributionEntity> updateContribution(
    String goalId,
    String contributionId,
    Map<String, dynamic> data,
  ) => _remote.updateContribution(goalId, contributionId, data);

  @override
  Future<void> deleteContribution(String goalId, String contributionId) =>
      _remote.deleteContribution(goalId, contributionId);

  @override
  Future<Map<String, dynamic>> getRecommendations() =>
      _remote.getRecommendations();
}
