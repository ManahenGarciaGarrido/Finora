import '../entities/market_index_entity.dart';
import '../repositories/investments_repository.dart';

class GetIndicesUseCase {
  final InvestmentsRepository _repo;
  GetIndicesUseCase(this._repo);
  Future<List<MarketIndexEntity>> call() => _repo.getIndices();
}
