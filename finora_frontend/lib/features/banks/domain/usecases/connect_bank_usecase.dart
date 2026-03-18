import '../repositories/bank_repository.dart';

class ConnectBankUseCase {
  final BankRepository repository;
  ConnectBankUseCase(this.repository);

  /// Returns {connectionId, authUrl, isMock, pendingAccounts}
  Future<Map<String, dynamic>> call(String institutionId) =>
      repository.connectBank(institutionId);
}
