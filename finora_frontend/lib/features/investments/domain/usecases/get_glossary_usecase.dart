import '../repositories/investments_repository.dart';

class GetGlossaryUseCase {
  final InvestmentsRepository _repo;
  GetGlossaryUseCase(this._repo);
  Future<List<Map<String, dynamic>>> call() => _repo.getGlossary();
}
