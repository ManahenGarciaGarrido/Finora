import '../entities/debt_entity.dart';
import '../repositories/debts_repository.dart';

class GetDebtsUseCase {
  final DebtsRepository _repo;
  GetDebtsUseCase(this._repo);
  Future<List<DebtEntity>> call() => _repo.getDebts();
}
