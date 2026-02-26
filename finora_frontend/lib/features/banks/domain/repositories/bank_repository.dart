import '../entities/bank_institution_entity.dart';
import '../entities/bank_account_entity.dart';
import '../entities/bank_card_entity.dart';
import '../entities/bank_sync_status_entity.dart';

/// Abstract repository for Open Banking operations (RF-10)
abstract class BankRepository {
  /// List available banking institutions
  Future<List<BankInstitutionEntity>> getInstitutions({String country = 'ES'});

  /// Start connection — returns {connectionId, authUrl, isMock, pendingAccounts}
  Future<Map<String, dynamic>> connectBank(String institutionId);

  /// Import selected accounts after user confirms selection
  Future<List<BankAccountEntity>> importSelectedBankAccounts({
    required String connectionId,
    required List<String> selectedAccountIds,
  });

  /// Get all linked bank accounts for the user
  Future<List<BankAccountEntity>> getBankAccounts();

  /// Poll connection status (used for OAuth callback detection)
  Future<BankSyncStatusEntity> getSyncStatus(String connectionId);

  /// Force re-sync balances
  Future<List<BankAccountEntity>> syncBank(String connectionId);

  /// Disconnect a bank and remove its accounts
  Future<void> disconnectBank(String connectionId);

  /// Create a bank account from the setup page
  Future<BankAccountEntity> setupBankAccount({
    required String connectionId,
    required String accountName,
    required String accountType,
    String? iban,
    int balanceCents = 0,
  });

  /// Get all bank cards for the user
  Future<List<BankCardEntity>> getBankCards();

  /// Delete a card by id
  Future<void> deleteBankCard(String cardId);

  /// Add a card to a bank account
  Future<BankCardEntity> addBankCard({
    required String bankAccountId,
    required String cardName,
    required String cardType,
    String? lastFour,
  });

  /// Import transactions from CSV rows (with deduplication)
  Future<Map<String, int>> importCsvTransactions({
    required String bankAccountId,
    required List<Map<String, dynamic>> rows,
  });

  /// RF-11: Import bank transactions from Salt Edge for a connection
  Future<Map<String, dynamic>> importBankTransactions(
    String connectionId, {
    String? fromDate,
  });

  /// RF-10: Exchange Plaid public_token for access_token (called from Flutter,
  /// not from the WebView, to avoid Android WebView network restrictions).
  Future<void> exchangePublicToken({
    required String connectionId,
    required String publicToken,
    required String institutionName,
  });
}
