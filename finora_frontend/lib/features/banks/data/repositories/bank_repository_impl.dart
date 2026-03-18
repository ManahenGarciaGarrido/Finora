import '../../domain/entities/bank_institution_entity.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/entities/bank_card_entity.dart';
import '../../domain/entities/bank_sync_status_entity.dart';
import '../../domain/entities/bank_connection_entity.dart';
import '../../domain/repositories/bank_repository.dart';
import '../datasources/bank_remote_datasource.dart';
import '../models/bank_account_model.dart';

class BankRepositoryImpl implements BankRepository {
  final BankRemoteDataSource _remoteDataSource;

  BankRepositoryImpl({required BankRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  @override
  Future<List<BankInstitutionEntity>> getInstitutions({String country = 'ES'}) {
    return _remoteDataSource.getInstitutions(country: country);
  }

  @override
  Future<Map<String, dynamic>> connectBank(String institutionId) {
    return _remoteDataSource.connectBank(institutionId);
  }

  @override
  Future<List<BankAccountEntity>> importSelectedBankAccounts({
    required String connectionId,
    required List<String> selectedAccountIds,
  }) {
    return _remoteDataSource.importSelectedBankAccounts(
      connectionId: connectionId,
      selectedAccountIds: selectedAccountIds,
    );
  }

  @override
  Future<List<BankAccountEntity>> getBankAccounts() {
    return _remoteDataSource.getBankAccounts();
  }

  @override
  Future<BankSyncStatusEntity> getSyncStatus(String connectionId) async {
    final data = await _remoteDataSource.getSyncStatus(connectionId);

    final status = BankConnectionStatusX.fromString(
      (data['status'] as String?) ?? 'pending',
    );

    final List<dynamic> rawAccounts = (data['accounts'] as List<dynamic>?) ?? [];
    final accounts = rawAccounts
        .map((json) => BankAccountModel.fromJson(json as Map<String, dynamic>))
        .toList();

    return BankSyncStatusEntity(
      status: status,
      institutionName: data['institution_name'] as String?,
      institutionLogo: data['institution_logo'] as String?,
      linkedAt: data['linked_at'] != null
          ? DateTime.parse(data['linked_at'] as String)
          : null,
      lastSyncAt: data['last_sync_at'] != null
          ? DateTime.parse(data['last_sync_at'] as String)
          : null,
      accounts: accounts,
    );
  }

  @override
  Future<List<BankAccountEntity>> syncBank(String connectionId) {
    return _remoteDataSource.syncBank(connectionId);
  }

  @override
  Future<void> disconnectBank(String connectionId) {
    return _remoteDataSource.disconnectBank(connectionId);
  }

  @override
  Future<BankAccountEntity> setupBankAccount({
    required String connectionId,
    required String accountName,
    required String accountType,
    String? iban,
    int balanceCents = 0,
  }) {
    return _remoteDataSource.setupBankAccount(
      connectionId: connectionId,
      accountName: accountName,
      accountType: accountType,
      iban: iban,
      balanceCents: balanceCents,
    );
  }

  @override
  Future<List<BankCardEntity>> getBankCards() {
    return _remoteDataSource.getBankCards();
  }

  @override
  Future<void> deleteBankCard(String cardId) {
    return _remoteDataSource.deleteBankCard(cardId);
  }

  @override
  Future<BankCardEntity> addBankCard({
    required String bankAccountId,
    required String cardName,
    required String cardType,
    String? lastFour,
  }) {
    return _remoteDataSource.addBankCard(
      bankAccountId: bankAccountId,
      cardName: cardName,
      cardType: cardType,
      lastFour: lastFour,
    );
  }

  @override
  Future<Map<String, int>> importCsvTransactions({
    required String bankAccountId,
    required List<Map<String, dynamic>> rows,
  }) {
    return _remoteDataSource.importCsvTransactions(
      bankAccountId: bankAccountId,
      rows: rows,
    );
  }

  @override
  Future<Map<String, dynamic>> importBankTransactions(
    String connectionId, {
    String? fromDate,
  }) {
    return _remoteDataSource.importBankTransactions(
      connectionId,
      fromDate: fromDate,
    );
  }

  @override
  Future<void> exchangePublicToken({
    required String connectionId,
    required String publicToken,
    required String institutionName,
  }) {
    return _remoteDataSource.exchangePublicToken(
      connectionId: connectionId,
      publicToken: publicToken,
      institutionName: institutionName,
    );
  }
}
