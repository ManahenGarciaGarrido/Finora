abstract class FiscalEvent {
  const FiscalEvent();
}

class LoadDeductibles extends FiscalEvent {
  final int? year;
  const LoadDeductibles({this.year});
}

class TagTransaction extends FiscalEvent {
  final String transactionId;
  final String? fiscalCategory;
  const TagTransaction(this.transactionId, {this.fiscalCategory});
}

class EstimateIrpf extends FiscalEvent {
  final double annualIncome;
  final double extraDeductions;
  const EstimateIrpf(this.annualIncome, {this.extraDeductions = 0});
}

class LoadCalendar extends FiscalEvent {
  final int? year;
  const LoadCalendar({this.year});
}

class LoadAllTransactions extends FiscalEvent {
  final int? year;
  const LoadAllTransactions({this.year});
}

class ExportFiscal extends FiscalEvent {
  final int? year;
  final String format; // 'csv' | 'xlsx'
  const ExportFiscal({this.year, this.format = 'xlsx'});
}
