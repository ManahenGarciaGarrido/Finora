import '../repositories/bank_repository.dart';

class DeleteBankCardUseCase {
  final BankRepository repository;
  DeleteBankCardUseCase(this.repository);

  Future<void> call(String cardId) => repository.deleteBankCard(cardId);
}
