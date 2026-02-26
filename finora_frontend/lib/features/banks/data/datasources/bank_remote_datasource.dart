import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../models/bank_institution_model.dart';
import '../models/bank_account_model.dart';
import '../models/bank_card_model.dart';
import '../../domain/entities/pending_bank_account_entity.dart';

abstract class BankRemoteDataSource {
  Future<List<BankInstitutionModel>> getInstitutions({String country = 'ES'});
  Future<Map<String, dynamic>> connectBank(String institutionId);
  Future<List<BankAccountModel>> importSelectedBankAccounts({
    required String connectionId,
    required List<String> selectedAccountIds,
  });
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
  Future<void> deleteBankCard(String cardId);
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

  /// RF-11: Importa transacciones desde Salt Edge para una conexión bancaria.
  /// Devuelve {imported, skipped} y la fecha de última sincronización.
  Future<Map<String, dynamic>> importBankTransactions(
    String connectionId, {
    String? fromDate,
  });

  /// RF-10: Intercambia el public_token de Plaid Link por un access_token
  /// permanente y vincula la conexión. Llamado por Flutter (no desde el WebView)
  /// para evitar restricciones de red del WebView de Android.
  Future<void> exchangePublicToken({
    required String connectionId,
    required String publicToken,
    required String institutionName,
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
  Future<Map<String, dynamic>> connectBank(String institutionId) async {
    final response = await _apiClient.post(
      ApiEndpoints.connectBank,
      data: {'institution_id': institutionId},
    );
    final data = response.data as Map<String, dynamic>;

    // Parsear cuentas pendientes de selección (modo sandbox)
    final rawPending = data['pending_accounts'] as List<dynamic>?;
    final pendingAccounts = rawPending?.map((a) {
      final m = a as Map<String, dynamic>;
      return PendingBankAccountEntity(
        externalAccountId:    m['external_account_id'] as String,
        name:                 m['name'] as String,
        originalCurrency:     (m['currency'] as String?) ?? 'USD',
        originalBalanceCents: ((m['balance_cents'] as num?) ?? 0).toInt(),
        balanceEurCents:      ((m['balance_eur_cents'] as num?) ?? 0).toInt(),
        iban:                 m['iban'] as String?,
      );
    }).toList() ?? <PendingBankAccountEntity>[];

    return {
      'connectionId':    data['connection_id'] as String,
      'authUrl':         (data['auth_url'] as String?) ?? '',
      'institutionName': (data['institution_name'] as String?) ?? institutionId,
      'isMock':          ((data['is_mock'] as bool?) ?? false).toString(),
      'pendingAccounts': pendingAccounts,
    };
  }

  @override
  Future<List<BankAccountModel>> importSelectedBankAccounts({
    required String connectionId,
    required List<String> selectedAccountIds,
  }) async {
    await _apiClient.post(
      ApiEndpoints.importBankAccounts(connectionId),
      data: {'selected_account_ids': selectedAccountIds},
    );
    // Tras importar, devolver la lista actualizada de cuentas del usuario
    final response = await _apiClient.get(ApiEndpoints.bankAccounts);
    final List<dynamic> list = response.data['accounts'] ?? [];
    return list
        .map((json) => BankAccountModel.fromJson(json as Map<String, dynamic>))
        .toList();
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
  Future<void> deleteBankCard(String cardId) async {
    await _apiClient.delete(ApiEndpoints.bankCardById(cardId));
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

  @override
  Future<Map<String, dynamic>> importBankTransactions(
    String connectionId, {
    String? fromDate,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.importBankTransactions(connectionId),
      data: fromDate != null ? {'from_date': fromDate} : null,
    );
    final data = response.data as Map<String, dynamic>;
    return {
      'imported': (data['imported'] as num?)?.toInt() ?? 0,
      'skipped': (data['skipped'] as num?)?.toInt() ?? 0,
      'last_sync_at': data['last_sync_at'] as String?,
    };
  }

  @override
  Future<void> exchangePublicToken({
    required String connectionId,
    required String publicToken,
    required String institutionName,
  }) async {
    await _apiClient.post(
      ApiEndpoints.plaidExchange,
      data: {
        'public_token': publicToken,
        'ref': connectionId,
        'institution_name': institutionName,
      },
    );
  }
}
