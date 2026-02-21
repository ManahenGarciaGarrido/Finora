import '../entities/bank_card_entity.dart';
import '../repositories/bank_repository.dart';

class AddBankCardUseCase {
  final BankRepository repository;
  AddBankCardUseCase(this.repository);

  Future<BankCardEntity> call({
    required String bankAccountId,
    required String cardName,
    required String cardType,
    String? lastFour,
  }) {
    return repository.addBankCard(
      bankAccountId: bankAccountId,
      cardName: cardName,
      cardType: cardType,
      lastFour: lastFour,
    );
  }
}
