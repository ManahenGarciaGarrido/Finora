import '../entities/bank_account_entity.dart';
import '../repositories/bank_repository.dart';

class ImportSelectedAccountsUseCase {
  final BankRepository repository;
  ImportSelectedAccountsUseCase(this.repository);

  Future<List<BankAccountEntity>> call({
    required String connectionId,
    required List<String> selectedAccountIds,
  }) =>
      repository.importSelectedBankAccounts(
        connectionId: connectionId,
        selectedAccountIds: selectedAccountIds,
      );
}
