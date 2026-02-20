import '../repositories/bank_repository.dart';

class DisconnectBankUseCase {
  final BankRepository repository;
  DisconnectBankUseCase(this.repository);

  Future<void> call(String connectionId) => repository.disconnectBank(connectionId);
}
