import '../../domain/entities/fiscal_transaction_entity.dart';
import '../../domain/entities/irpf_result_entity.dart';
import '../../domain/entities/tax_event_entity.dart';
import '../../domain/repositories/fiscal_repository.dart';
import '../datasources/fiscal_remote_datasource.dart';

class FiscalRepositoryImpl implements FiscalRepository {
  final FiscalRemoteDataSource _ds;
  FiscalRepositoryImpl(this._ds);

  @override
  Future<List<FiscalTransactionEntity>> getDeductibles({int? year}) =>
      _ds.getDeductibles(year: year);

  @override
  Future<FiscalTransactionEntity> tagTransaction(
    String transactionId,
    String? fiscalCategory,
  ) => _ds.tagTransaction(transactionId, fiscalCategory);

  @override
  Future<IrpfResultEntity> estimateIrpf({
    required double annualIncome,
    double extraDeductions = 0,
  }) => _ds.estimateIrpf(
    annualIncome: annualIncome,
    extraDeductions: extraDeductions,
  );

  @override
  Future<List<TaxEventEntity>> getCalendar({int? year}) =>
      _ds.getCalendar(year: year);

  @override
  Future<List<FiscalTransactionEntity>> exportFiscal({int? year}) =>
      _ds.exportFiscal(year: year);
}
