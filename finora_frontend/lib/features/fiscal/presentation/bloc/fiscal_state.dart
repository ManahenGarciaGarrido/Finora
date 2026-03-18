import '../../domain/entities/fiscal_transaction_entity.dart';
import '../../domain/entities/irpf_result_entity.dart';
import '../../domain/entities/tax_event_entity.dart';

abstract class FiscalState {
  const FiscalState();
}

class FiscalInitial extends FiscalState {
  const FiscalInitial();
}

class FiscalLoading extends FiscalState {
  const FiscalLoading();
}

class DeductiblesLoaded extends FiscalState {
  final List<FiscalTransactionEntity> transactions;
  final double total;
  const DeductiblesLoaded(this.transactions, this.total);
}

class TransactionTagged extends FiscalState {
  final FiscalTransactionEntity transaction;
  const TransactionTagged(this.transaction);
}

class IrpfEstimated extends FiscalState {
  final IrpfResultEntity result;
  const IrpfEstimated(this.result);
}

class CalendarLoaded extends FiscalState {
  final List<TaxEventEntity> events;
  const CalendarLoaded(this.events);
}

class AllTransactionsLoaded extends FiscalState {
  final List<FiscalTransactionEntity> transactions;
  const AllTransactionsLoaded(this.transactions);
}

class FiscalExported extends FiscalState {
  final List<FiscalTransactionEntity> transactions;
  const FiscalExported(this.transactions);
}

class FiscalExportReady extends FiscalState {
  final String filePath;
  final String format;
  const FiscalExportReady({required this.filePath, required this.format});
}

class FiscalError extends FiscalState {
  final String message;
  const FiscalError(this.message);
}
