import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/savings_goal_model.dart';
import '../models/goal_contribution_model.dart';

abstract class GoalsRemoteDataSource {
  Future<List<SavingsGoalModel>> getGoals();
  Future<SavingsGoalModel> getGoal(String id);
  Future<SavingsGoalModel> createGoal(Map<String, dynamic> data);
  Future<SavingsGoalModel> updateGoal(String id, Map<String, dynamic> data);
  Future<void> deleteGoal(String id);
  Future<Map<String, dynamic>> getGoalProgress(String id);
  Future<GoalContributionModel> addContribution(
    String goalId,
    Map<String, dynamic> data,
  );
  Future<List<GoalContributionModel>> getContributions(String goalId);
  Future<GoalContributionModel> updateContribution(
    String goalId,
    String cid,
    Map<String, dynamic> data,
  );
  Future<void> deleteContribution(String goalId, String cid);
  Future<Map<String, dynamic>> getRecommendations();
}

class GoalsRemoteDataSourceImpl implements GoalsRemoteDataSource {
  final ApiClient _client;
  GoalsRemoteDataSourceImpl(this._client);

  @override
  Future<List<SavingsGoalModel>> getGoals() async {
    final resp = await _client.get(ApiEndpoints.savingsGoals);
    final list = resp.data['goals'] as List<dynamic>;
    return list
        .map((j) => SavingsGoalModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SavingsGoalModel> getGoal(String id) async {
    final resp = await _client.get(ApiEndpoints.goalById(id));
    return SavingsGoalModel.fromJson(resp.data['goal'] as Map<String, dynamic>);
  }

  @override
  Future<SavingsGoalModel> createGoal(Map<String, dynamic> data) async {
    final resp = await _client.post(ApiEndpoints.savingsGoals, data: data);
    return SavingsGoalModel.fromJson(resp.data['goal'] as Map<String, dynamic>);
  }

  @override
  Future<SavingsGoalModel> updateGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    final resp = await _client.put(ApiEndpoints.goalById(id), data: data);
    return SavingsGoalModel.fromJson(resp.data['goal'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _client.delete(ApiEndpoints.goalById(id));
  }

  @override
  Future<Map<String, dynamic>> getGoalProgress(String id) async {
    final resp = await _client.get(ApiEndpoints.goalProgress(id));
    return resp.data as Map<String, dynamic>;
  }

  @override
  Future<GoalContributionModel> addContribution(
    String goalId,
    Map<String, dynamic> data,
  ) async {
    final resp = await _client.post(
      ApiEndpoints.addContribution(goalId),
      data: data,
    );
    return GoalContributionModel.fromJson(
      resp.data['contribution'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<GoalContributionModel>> getContributions(String goalId) async {
    final resp = await _client.get(ApiEndpoints.addContribution(goalId));
    final list = resp.data['contributions'] as List<dynamic>;
    return list
        .map((j) => GoalContributionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<GoalContributionModel> updateContribution(
    String goalId,
    String cid,
    Map<String, dynamic> data,
  ) async {
    final resp = await _client.put(
      '${ApiEndpoints.addContribution(goalId)}/$cid',
      data: data,
    );
    return GoalContributionModel.fromJson(
      resp.data['contribution'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteContribution(String goalId, String cid) async {
    await _client.delete('${ApiEndpoints.addContribution(goalId)}/$cid');
  }

  @override
  Future<Map<String, dynamic>> getRecommendations() async {
    final resp = await _client.get(ApiEndpoints.goalRecommendations);
    return resp.data as Map<String, dynamic>;
  }
}
