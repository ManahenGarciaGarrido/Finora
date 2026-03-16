import '../repositories/debts_repository.dart';

class GetStrategiesUseCase {
  final DebtsRepository _repo;
  GetStrategiesUseCase(this._repo);
  Future<Map<String, dynamic>> call() => _repo.getStrategies();
}
