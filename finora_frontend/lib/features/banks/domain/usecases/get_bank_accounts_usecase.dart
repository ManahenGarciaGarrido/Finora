import '../entities/bank_account_entity.dart';
import '../repositories/bank_repository.dart';

class GetBankAccountsUseCase {
  final BankRepository repository;
  GetBankAccountsUseCase(this.repository);

  Future<List<BankAccountEntity>> call() => repository.getBankAccounts();
}
