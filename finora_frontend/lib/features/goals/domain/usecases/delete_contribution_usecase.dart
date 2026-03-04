import '../repositories/goals_repository.dart';

class DeleteContributionUseCase {
  final GoalsRepository _repo;
  DeleteContributionUseCase(this._repo);
  Future<void> call(String goalId, String contributionId) =>
      _repo.deleteContribution(goalId, contributionId);
}
