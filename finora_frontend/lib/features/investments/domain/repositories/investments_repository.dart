import '../entities/investor_profile_entity.dart';
import '../entities/portfolio_suggestion_entity.dart';
import '../entities/market_index_entity.dart';

abstract class InvestmentsRepository {
  Future<InvestorProfileEntity?> getProfile();
  Future<InvestorProfileEntity> saveProfile(Map<String, dynamic> data);
  Future<PortfolioSuggestionEntity> getPortfolioSuggestion();
  Future<Map<String, dynamic>> simulateReturns(Map<String, dynamic> data);
  Future<List<MarketIndexEntity>> getIndices();
  Future<List<Map<String, dynamic>>> getGlossary();
  Future<Map<String, dynamic>> getChart(String ticker, String period);
}
