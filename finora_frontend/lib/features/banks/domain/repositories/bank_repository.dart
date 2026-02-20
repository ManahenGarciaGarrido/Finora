import '../entities/bank_institution_entity.dart';
import '../entities/bank_account_entity.dart';
import '../entities/bank_sync_status_entity.dart';

/// Abstract repository for Open Banking operations (RF-10)
abstract class BankRepository {
  /// List available banking institutions
  Future<List<BankInstitutionEntity>> getInstitutions({String country = 'ES'});

  /// Start OAuth connection — returns {connectionId, authUrl}
  Future<Map<String, String>> connectBank(String institutionId);

  /// Get all linked bank accounts for the user
  Future<List<BankAccountEntity>> getBankAccounts();

  /// Poll connection status (used for OAuth callback detection)
  Future<BankSyncStatusEntity> getSyncStatus(String connectionId);

  /// Force re-sync balances
  Future<List<BankAccountEntity>> syncBank(String connectionId);

  /// Disconnect a bank and remove its accounts
  Future<void> disconnectBank(String connectionId);
}
