import '../repositories/goals_repository.dart';

class GetGoalProgressUseCase {
  final GoalsRepository _repo;
  GetGoalProgressUseCase(this._repo);
  Future<Map<String, dynamic>> call(String id) => _repo.getGoalProgress(id);
}
