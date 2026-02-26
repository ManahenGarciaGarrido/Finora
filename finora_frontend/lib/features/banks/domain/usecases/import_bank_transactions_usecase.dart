import '../repositories/bank_repository.dart';

/// RF-11: Importa transacciones bancarias desde Salt Edge para una conexión.
///
/// Retorna un mapa con:
///   - imported: número de transacciones nuevas importadas
///   - skipped:  número de duplicados ignorados
///   - last_sync_at: ISO 8601 timestamp de la sincronización
class ImportBankTransactionsUseCase {
  final BankRepository repository;
  ImportBankTransactionsUseCase(this.repository);

  Future<Map<String, dynamic>> call(
    String connectionId, {
    String? fromDate,
  }) {
    return repository.importBankTransactions(
      connectionId,
      fromDate: fromDate,
    );
  }
}
