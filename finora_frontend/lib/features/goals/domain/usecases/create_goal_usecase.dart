import '../entities/savings_goal_entity.dart';
import '../repositories/goals_repository.dart';

class CreateGoalUseCase {
  final GoalsRepository _repo;
  CreateGoalUseCase(this._repo);

  Future<SavingsGoalEntity> call({
    required String name,
    required String icon,
    required String color,
    required double targetAmount,
    DateTime? deadline,
    String? category,
    String? notes,
    double? monthlyTarget,
  }) => _repo.createGoal(
    name: name,
    icon: icon,
    color: color,
    targetAmount: targetAmount,
    deadline: deadline,
    category: category,
    notes: notes,
    monthlyTarget: monthlyTarget,
  );
}
