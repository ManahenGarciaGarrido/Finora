import '../repositories/goals_repository.dart';

class GetRecommendationsUseCase {
  final GoalsRepository _repo;
  GetRecommendationsUseCase(this._repo);
  Future<Map<String, dynamic>> call() => _repo.getRecommendations();
}
