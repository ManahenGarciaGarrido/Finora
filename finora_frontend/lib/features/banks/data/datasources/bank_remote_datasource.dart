import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/bank_institution_model.dart';
import '../models/bank_account_model.dart';
import '../models/bank_card_model.dart';

abstract class BankRemoteDataSource {
  Future<List<BankInstitutionModel>> getInstitutions({String country = 'ES'});
  Future<Map<String, String>> connectBank(String institutionId);
  Future<List<BankAccountModel>> getBankAccounts();
  Future<Map<String, dynamic>> getSyncStatus(String connectionId);
  Future<List<BankAccountModel>> syncBank(String connectionId);
  Future<void> disconnectBank(String connectionId);
  Future<BankAccountModel> setupBankAccount({
    required String connectionId,
    required String accountName,
    required String accountType,
    String? iban,
    int balanceCents = 0,
  });
  Future<List<BankCardModel>> getBankCards();
  Future<BankCardModel> addBankCard({
    required String bankAccountId,
    required String cardName,
    required String cardType,
    String? lastFour,
  });
  Future<Map<String, int>> importCsvTransactions({
    required String bankAccountId,
    required List<Map<String, dynamic>> rows,
  });
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
      // auth_url is absent in mock mode (connection already linked)
      'authUrl': (data['auth_url'] as String?) ?? '',
      'institutionName': (data['institution_name'] as String?) ?? institutionId,
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

  @override
  Future<BankAccountModel> setupBankAccount({
    required String connectionId,
    required String accountName,
    required String accountType,
    String? iban,
    int balanceCents = 0,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bankAccountSetup,
      data: {
        'connection_id': connectionId,
        'account_name': accountName,
        'account_type': accountType,
        'iban': iban,
        'balance_cents': balanceCents,
      },
    );
    return BankAccountModel.fromJson(
      response.data['account'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<BankCardModel>> getBankCards() async {
    final response = await _apiClient.get(ApiEndpoints.bankCards);
    final List<dynamic> list = response.data['cards'] ?? [];
    return list
        .map((json) => BankCardModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<BankCardModel> addBankCard({
    required String bankAccountId,
    required String cardName,
    required String cardType,
    String? lastFour,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bankAccountCards(bankAccountId),
      data: {
        'card_name': cardName,
        'card_type': cardType,
        'last_four': lastFour,
      },
    );
    return BankCardModel.fromJson(
      response.data['card'] as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, int>> importCsvTransactions({
    required String bankAccountId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bankAccountImportCsv(bankAccountId),
      data: {'rows': rows},
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'imported': (data['imported'] as num?)?.toInt() ?? 0,
      'skipped': (data['skipped'] as num?)?.toInt() ?? 0,
    };
  }
}
