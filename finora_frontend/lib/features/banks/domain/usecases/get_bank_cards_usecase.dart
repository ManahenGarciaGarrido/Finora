import '../entities/bank_card_entity.dart';
import '../repositories/bank_repository.dart';

class GetBankCardsUseCase {
  final BankRepository repository;
  GetBankCardsUseCase(this.repository);

  Future<List<BankCardEntity>> call() => repository.getBankCards();
}
