import '../entities/bank_institution_entity.dart';
import '../entities/bank_account_entity.dart';
import '../entities/bank_card_entity.dart';
import '../entities/bank_sync_status_entity.dart';

/// Abstract repository for Open Banking operations (RF-10)
abstract class BankRepository {
  /// List available banking institutions
  Future<List<BankInstitutionEntity>> getInstitutions({String country = 'ES'});

  /// Start OAuth connection — returns {connectionId, authUrl, institutionName}
  Future<Map<String, String>> connectBank(String institutionId);

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
}
