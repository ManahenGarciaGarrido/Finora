import '../entities/bank_account_entity.dart';
import '../repositories/bank_repository.dart';

class SetupBankAccountUseCase {
  final BankRepository repository;
  SetupBankAccountUseCase(this.repository);

  Future<BankAccountEntity> call({
    required String connectionId,
    required String accountName,
    required String accountType,
    String? iban,
    int balanceCents = 0,
  }) {
    return repository.setupBankAccount(
      connectionId: connectionId,
      accountName: accountName,
      accountType: accountType,
      iban: iban,
      balanceCents: balanceCents,
    );
  }
}
