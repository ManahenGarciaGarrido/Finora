import '../../../../core/network/api_client.dart';
import '../models/debt_model.dart';

abstract class DebtsRemoteDataSource {
  Future<List<DebtModel>> getDebts();
  Future<DebtModel> createDebt(Map<String, dynamic> data);
  Future<DebtModel> updateDebt(String id, Map<String, dynamic> data);
  Future<void> deleteDebt(String id);
  Future<Map<String, dynamic>> getStrategies();
  Future<Map<String, dynamic>> calculateLoan(Map<String, dynamic> data);
  Future<Map<String, dynamic>> calculateMortgage(Map<String, dynamic> data);
}

class DebtsRemoteDataSourceImpl implements DebtsRemoteDataSource {
  final ApiClient _client;
  DebtsRemoteDataSourceImpl(this._client);

  @override
  Future<List<DebtModel>> getDebts() async {
    final r = await _client.get('/debts');
    return (r.data['debts'] as List)
        .map((j) => DebtModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DebtModel> createDebt(Map<String, dynamic> data) async {
    final r = await _client.post('/debts', data: data);
    return DebtModel.fromJson(r.data['debt'] as Map<String, dynamic>);
  }

  @override
  Future<DebtModel> updateDebt(String id, Map<String, dynamic> data) async {
    final r = await _client.put('/debts/$id', data: data);
    return DebtModel.fromJson(r.data['debt'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _client.delete('/debts/$id');
  }

  @override
  Future<Map<String, dynamic>> getStrategies() async {
    final r = await _client.get('/debts/strategies');
    return r.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> calculateLoan(Map<String, dynamic> data) async {
    final r = await _client.post('/debts/calculate/loan', data: data);
    return r.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> calculateMortgage(
    Map<String, dynamic> data,
  ) async {
    final r = await _client.post('/debts/calculate/mortgage', data: data);
    return r.data as Map<String, dynamic>;
  }
}
