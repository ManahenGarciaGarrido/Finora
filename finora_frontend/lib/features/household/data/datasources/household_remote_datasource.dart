import '../../../../core/network/api_client.dart';
import '../models/household_model.dart';

abstract class HouseholdRemoteDataSource {
  Future<HouseholdModel?> getHousehold();
  Future<HouseholdModel> createHousehold(String name);
  Future<void> deleteHousehold();
  Future<void> inviteMember(String email);
  Future<void> removeMember(String userId);
  Future<List<HouseholdMemberModel>> getMembers();
  Future<void> createSharedTransaction(Map<String, dynamic> data);
  Future<List<SharedTransactionModel>> getSharedTransactions();
  Future<List<BalanceModel>> getBalances();
  Future<void> settleBalance(String withUserId);
}

class HouseholdRemoteDataSourceImpl implements HouseholdRemoteDataSource {
  final ApiClient _client;
  HouseholdRemoteDataSourceImpl(this._client);

  @override
  Future<HouseholdModel?> getHousehold() async {
    final r = await _client.get('/household');
    final h = r.data['household'];
    if (h == null) return null;
    return HouseholdModel.fromJson(h as Map<String, dynamic>);
  }

  @override
  Future<HouseholdModel> createHousehold(String name) async {
    final r = await _client.post('/household', data: {'name': name});
    return HouseholdModel.fromJson(r.data['household'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteHousehold() async {
    await _client.delete('/household');
  }

  @override
  Future<void> inviteMember(String email) async {
    await _client.post('/household/invite', data: {'email': email});
  }

  @override
  Future<void> removeMember(String userId) async {
    await _client.delete('/household/members/$userId');
  }

  @override
  Future<List<HouseholdMemberModel>> getMembers() async {
    final r = await _client.get('/household/members');
    return (r.data['members'] as List)
        .map((j) => HouseholdMemberModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createSharedTransaction(Map<String, dynamic> data) async {
    await _client.post('/household/transactions', data: data);
  }

  @override
  Future<List<SharedTransactionModel>> getSharedTransactions() async {
    final r = await _client.get('/household/transactions');
    return (r.data['transactions'] as List)
        .map((j) => SharedTransactionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<BalanceModel>> getBalances() async {
    final r = await _client.get('/household/balances');
    return (r.data['balances'] as List)
        .map((j) => BalanceModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> settleBalance(String withUserId) async {
    await _client.post('/household/settle', data: {'with_user_id': withUserId});
  }
}
