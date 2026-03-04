import '../entities/savings_goal_entity.dart';
import '../repositories/goals_repository.dart';

class GetGoalsUseCase {
  final GoalsRepository _repo;
  GetGoalsUseCase(this._repo);
  Future<List<SavingsGoalEntity>> call() => _repo.getGoals();
}
