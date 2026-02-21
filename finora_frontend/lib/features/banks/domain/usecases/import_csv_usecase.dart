import '../repositories/bank_repository.dart';

class ImportCsvUseCase {
  final BankRepository repository;
  ImportCsvUseCase(this.repository);

  Future<Map<String, int>> call({
    required String bankAccountId,
    required List<Map<String, dynamic>> rows,
  }) {
    return repository.importCsvTransactions(
      bankAccountId: bankAccountId,
      rows: rows,
    );
  }
}
