import '../repositories/goals_repository.dart';

class DeleteGoalUseCase {
  final GoalsRepository _repo;
  DeleteGoalUseCase(this._repo);
  Future<void> call(String id) => _repo.deleteGoal(id);
}
