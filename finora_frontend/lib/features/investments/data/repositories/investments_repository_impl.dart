import '../../domain/entities/investor_profile_entity.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';
import '../../domain/entities/market_index_entity.dart';
import '../../domain/repositories/investments_repository.dart';
import '../datasources/investments_remote_datasource.dart';

class InvestmentsRepositoryImpl implements InvestmentsRepository {
  final InvestmentsRemoteDataSource _ds;
  InvestmentsRepositoryImpl(this._ds);

  @override
  Future<InvestorProfileEntity?> getProfile() => _ds.getProfile();

  @override
  Future<InvestorProfileEntity> saveProfile(Map<String, dynamic> data) =>
      _ds.saveProfile(data);

  @override
  Future<PortfolioSuggestionEntity> getPortfolioSuggestion() =>
      _ds.getPortfolioSuggestion();

  @override
  Future<Map<String, dynamic>> simulateReturns(Map<String, dynamic> data) =>
      _ds.simulateReturns(data);

  @override
  Future<List<MarketIndexEntity>> getIndices() => _ds.getIndices();

  @override
  Future<List<Map<String, dynamic>>> getGlossary() => _ds.getGlossary();

  @override
  Future<Map<String, dynamic>> getChart(String ticker, String period) =>
      _ds.getChart(ticker, period);
}
