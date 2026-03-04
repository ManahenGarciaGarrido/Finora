import '../entities/savings_goal_entity.dart';
import '../repositories/goals_repository.dart';

class UpdateGoalUseCase {
  final GoalsRepository _repo;
  UpdateGoalUseCase(this._repo);
  Future<SavingsGoalEntity> call(String id, Map<String, dynamic> data) =>
      _repo.updateGoal(id, data);
}
