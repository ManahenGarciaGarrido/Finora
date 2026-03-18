import '../../../../core/network/api_client.dart';
import '../models/investor_profile_model.dart';
import '../models/portfolio_suggestion_model.dart';
import '../models/market_index_model.dart';

abstract class InvestmentsRemoteDataSource {
  Future<InvestorProfileModel?> getProfile();
  Future<InvestorProfileModel> saveProfile(Map<String, dynamic> data);
  Future<PortfolioSuggestionModel> getPortfolioSuggestion();
  Future<Map<String, dynamic>> simulateReturns(Map<String, dynamic> data);
  Future<List<MarketIndexModel>> getIndices();
  Future<List<Map<String, dynamic>>> getGlossary();
  Future<Map<String, dynamic>> getChart(String ticker, String period);
}

class InvestmentsRemoteDataSourceImpl implements InvestmentsRemoteDataSource {
  final ApiClient _client;
  InvestmentsRemoteDataSourceImpl(this._client);

  @override
  Future<InvestorProfileModel?> getProfile() async {
    final r = await _client.get('/investments/profile');
    final p = r.data['profile'];
    if (p == null) return null;
    return InvestorProfileModel.fromJson(p as Map<String, dynamic>);
  }

  @override
  Future<InvestorProfileModel> saveProfile(Map<String, dynamic> data) async {
    final r = await _client.post('/investments/profile', data: data);
    return InvestorProfileModel.fromJson(
      r.data['profile'] as Map<String, dynamic>,
    );
  }

  @override
  Future<PortfolioSuggestionModel> getPortfolioSuggestion() async {
    final r = await _client.get('/investments/portfolio/suggest');
    return PortfolioSuggestionModel.fromJson(r.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> simulateReturns(
    Map<String, dynamic> data,
  ) async {
    final r = await _client.post('/investments/simulator', data: data);
    return r.data as Map<String, dynamic>;
  }

  @override
  Future<List<MarketIndexModel>> getIndices() async {
    final r = await _client.get('/investments/indices');
    return (r.data['indices'] as List)
        .map((j) => MarketIndexModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getGlossary() async {
    final r = await _client.get('/investments/glossary');
    return List<Map<String, dynamic>>.from(r.data['glossary'] as List);
  }

  @override
  Future<Map<String, dynamic>> getChart(String ticker, String period) async {
    final r = await _client.get('/investments/chart/$ticker?period=$period');
    return r.data as Map<String, dynamic>;
  }
}
