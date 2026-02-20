import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/bank_institution_model.dart';
import '../models/bank_account_model.dart';

abstract class BankRemoteDataSource {
  Future<List<BankInstitutionModel>> getInstitutions({String country = 'ES'});
  Future<Map<String, String>> connectBank(String institutionId);
  Future<List<BankAccountModel>> getBankAccounts();
  Future<Map<String, dynamic>> getSyncStatus(String connectionId);
  Future<List<BankAccountModel>> syncBank(String connectionId);
  Future<void> disconnectBank(String connectionId);
}

class BankRemoteDataSourceImpl implements BankRemoteDataSource {
  final ApiClient _apiClient;

  BankRemoteDataSourceImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<List<BankInstitutionModel>> getInstitutions({String country = 'ES'}) async {
    final response = await _apiClient.get(
      ApiEndpoints.bankInstitutions,
      queryParameters: {'country': country},
    );
    final List<dynamic> list = response.data['institutions'] ?? [];
    return list
        .map((json) => BankInstitutionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, String>> connectBank(String institutionId) async {
    final response = await _apiClient.post(
      ApiEndpoints.connectBank,
      data: {'institution_id': institutionId},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'connectionId': data['connection_id'] as String,
      'authUrl': data['auth_url'] as String,
    };
  }

  @override
  Future<List<BankAccountModel>> getBankAccounts() async {
    final response = await _apiClient.get(ApiEndpoints.bankAccounts);
    final List<dynamic> list = response.data['accounts'] ?? [];
    return list
        .map((json) => BankAccountModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> getSyncStatus(String connectionId) async {
    final response = await _apiClient.get(ApiEndpoints.bankSyncStatus(connectionId));
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<List<BankAccountModel>> syncBank(String connectionId) async {
    final response = await _apiClient.post(ApiEndpoints.syncBank(connectionId));
    final List<dynamic> list = response.data['accounts'] ?? [];
    return list
        .map((json) => BankAccountModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> disconnectBank(String connectionId) async {
    await _apiClient.delete(ApiEndpoints.disconnectBank(connectionId));
  }
}
