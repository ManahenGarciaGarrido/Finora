import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/fiscal_repository.dart';
import 'fiscal_event.dart';
import 'fiscal_state.dart';

class FiscalBloc extends Bloc<FiscalEvent, FiscalState> {
  final FiscalRepository _repo;

  FiscalBloc(this._repo) : super(const FiscalInitial()) {
    on<LoadDeductibles>(_onLoadDeductibles);
    on<LoadAllTransactions>(_onLoadAll);
    on<TagTransaction>(_onTag);
    on<EstimateIrpf>(_onEstimate);
    on<LoadCalendar>(_onCalendar);
    on<ExportFiscal>(_onExport);
  }

  Future<void> _onLoadDeductibles(
    LoadDeductibles e,
    Emitter<FiscalState> emit,
  ) async {
    emit(const FiscalLoading());
    try {
      final list = await _repo.getDeductibles(year: e.year);
      final total = list.fold(0.0, (sum, t) => sum + t.amount);
      emit(DeductiblesLoaded(list, total));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  Future<void> _onTag(TagTransaction e, Emitter<FiscalState> emit) async {
    try {
      final tx = await _repo.tagTransaction(e.transactionId, e.fiscalCategory);
      emit(TransactionTagged(tx));
      // Reload deductibles list (main page) then all transactions (bottom sheet)
      final list = await _repo.getDeductibles();
      final total = list.fold(0.0, (sum, t) => sum + t.amount);
      emit(DeductiblesLoaded(list, total));
      // Re-emit AllTransactionsLoaded so the bottom sheet refreshes
      final all = await _repo.getAllTransactions();
      emit(AllTransactionsLoaded(all));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  Future<void> _onEstimate(EstimateIrpf e, Emitter<FiscalState> emit) async {
    emit(const FiscalLoading());
    try {
      final result = await _repo.estimateIrpf(
        annualIncome: e.annualIncome,
        extraDeductions: e.extraDeductions,
      );
      emit(IrpfEstimated(result));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  Future<void> _onCalendar(LoadCalendar e, Emitter<FiscalState> emit) async {
    emit(const FiscalLoading());
    try {
      final events = await _repo.getCalendar(year: e.year);
      emit(CalendarLoaded(events));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  Future<void> _onLoadAll(
    LoadAllTransactions e,
    Emitter<FiscalState> emit,
  ) async {
    emit(const FiscalLoading());
    try {
      final list = await _repo.getAllTransactions(year: e.year);
      emit(AllTransactionsLoaded(list));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  Future<void> _onExport(ExportFiscal e, Emitter<FiscalState> emit) async {
    emit(const FiscalLoading());
    try {
      if (e.format == 'json') {
        final data = await _repo.exportFiscal(year: e.year);
        emit(FiscalExported(data));
      } else {
        final path = await _repo.downloadExport(year: e.year, format: e.format);
        emit(FiscalExportReady(filePath: path, format: e.format));
      }
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
