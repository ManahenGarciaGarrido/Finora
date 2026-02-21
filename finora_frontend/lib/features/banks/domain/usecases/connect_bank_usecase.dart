import '../repositories/bank_repository.dart';

class ConnectBankUseCase {
  final BankRepository repository;
  ConnectBankUseCase(this.repository);

  /// Returns {connectionId, authUrl}
  Future<Map<String, String>> call(String institutionId) =>
      repository.connectBank(institutionId);
}
