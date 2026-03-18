import '../repositories/debts_repository.dart';

class DeleteDebtUseCase {
  final DebtsRepository _repo;
  DeleteDebtUseCase(this._repo);
  Future<void> call(String id) => _repo.deleteDebt(id);
}
