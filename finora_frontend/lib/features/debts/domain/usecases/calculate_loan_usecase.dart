import '../repositories/debts_repository.dart';

class CalculateLoanUseCase {
  final DebtsRepository _repo;
  CalculateLoanUseCase(this._repo);
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) =>
      _repo.calculateLoan(data);
}
