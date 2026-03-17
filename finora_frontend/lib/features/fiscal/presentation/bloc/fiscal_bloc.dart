import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/fiscal_repository.dart';
import 'fiscal_event.dart';
import 'fiscal_state.dart';

class FiscalBloc extends Bloc<FiscalEvent, FiscalState> {
  final FiscalRepository _repo;

  FiscalBloc(this._repo) : super(const FiscalInitial()) {
    on<LoadDeductibles>(_onLoadDeductibles);
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
      add(const LoadDeductibles());
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

  Future<void> _onExport(ExportFiscal e, Emitter<FiscalState> emit) async {
    emit(const FiscalLoading());
    try {
      final data = await _repo.exportFiscal(year: e.year);
      emit(FiscalExported(data));
    } catch (err) {
      emit(FiscalError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
