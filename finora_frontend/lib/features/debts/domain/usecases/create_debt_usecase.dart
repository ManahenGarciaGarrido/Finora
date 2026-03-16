import '../entities/debt_entity.dart';
import '../repositories/debts_repository.dart';

class CreateDebtUseCase {
  final DebtsRepository _repo;
  CreateDebtUseCase(this._repo);
  Future<DebtEntity> call(Map<String, dynamic> data) => _repo.createDebt(data);
}
