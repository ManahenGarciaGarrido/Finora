import '../repositories/investments_repository.dart';

class SimulateReturnsUseCase {
  final InvestmentsRepository _repo;
  SimulateReturnsUseCase(this._repo);
  Future<Map<String, dynamic>> call(Map<String, dynamic> data) =>
      _repo.simulateReturns(data);
}
