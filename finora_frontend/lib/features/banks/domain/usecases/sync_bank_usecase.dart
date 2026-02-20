import '../entities/bank_account_entity.dart';
import '../repositories/bank_repository.dart';

class SyncBankUseCase {
  final BankRepository repository;
  SyncBankUseCase(this.repository);

  Future<List<BankAccountEntity>> call(String connectionId) =>
      repository.syncBank(connectionId);
}
