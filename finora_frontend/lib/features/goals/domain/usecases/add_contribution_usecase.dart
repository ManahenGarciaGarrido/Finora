import '../entities/goal_contribution_entity.dart';
import '../repositories/goals_repository.dart';

class AddContributionUseCase {
  final GoalsRepository _repo;
  AddContributionUseCase(this._repo);

  Future<GoalContributionEntity> call({
    required String goalId,
    required double amount,
    DateTime? date,
    String? note,
    String? bankAccountId,
  }) => _repo.addContribution(
    goalId: goalId,
    amount: amount,
    date: date,
    note: note,
    bankAccountId: bankAccountId,
  );
}
