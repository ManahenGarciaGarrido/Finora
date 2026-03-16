import '../entities/debt_entity.dart';
import '../repositories/debts_repository.dart';

class UpdateDebtUseCase {
  final DebtsRepository _repo;
  UpdateDebtUseCase(this._repo);
  Future<DebtEntity> call(String id, Map<String, dynamic> data) =>
      _repo.updateDebt(id, data);
}
