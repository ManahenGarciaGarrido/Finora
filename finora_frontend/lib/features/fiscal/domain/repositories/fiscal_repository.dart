import '../entities/fiscal_transaction_entity.dart';
import '../entities/irpf_result_entity.dart';
import '../entities/tax_event_entity.dart';

abstract class FiscalRepository {
  Future<List<FiscalTransactionEntity>> getDeductibles({int? year});
  Future<List<FiscalTransactionEntity>> getAllTransactions({int? year});
  Future<FiscalTransactionEntity> tagTransaction(
    String transactionId,
    String? fiscalCategory,
  );
  Future<IrpfResultEntity> estimateIrpf({
    required double annualIncome,
    double extraDeductions,
  });
  Future<List<TaxEventEntity>> getCalendar({int? year});
  Future<List<FiscalTransactionEntity>> exportFiscal({int? year});
  Future<String> downloadExport({int? year, required String format});
}
