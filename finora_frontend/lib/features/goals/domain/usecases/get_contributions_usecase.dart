import '../entities/goal_contribution_entity.dart';
import '../repositories/goals_repository.dart';

class GetContributionsUseCase {
  final GoalsRepository _repo;
  GetContributionsUseCase(this._repo);
  Future<List<GoalContributionEntity>> call(String goalId) =>
      _repo.getContributions(goalId);
}
