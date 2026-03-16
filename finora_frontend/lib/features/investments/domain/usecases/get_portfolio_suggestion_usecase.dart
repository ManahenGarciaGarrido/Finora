import '../entities/portfolio_suggestion_entity.dart';
import '../repositories/investments_repository.dart';

class GetPortfolioSuggestionUseCase {
  final InvestmentsRepository _repo;
  GetPortfolioSuggestionUseCase(this._repo);
  Future<PortfolioSuggestionEntity> call() => _repo.getPortfolioSuggestion();
}
