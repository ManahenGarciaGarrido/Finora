import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_debts_usecase.dart';
import '../../domain/usecases/create_debt_usecase.dart';
import '../../domain/usecases/update_debt_usecase.dart';
import '../../domain/usecases/delete_debt_usecase.dart';
import '../../domain/usecases/get_strategies_usecase.dart';
import '../../domain/usecases/calculate_loan_usecase.dart';
import 'debt_event.dart';
import 'debt_state.dart';

class DebtBloc extends Bloc<DebtEvent, DebtState> {
  final GetDebtsUseCase getDebts;
  final CreateDebtUseCase createDebt;
  final UpdateDebtUseCase updateDebt;
  final DeleteDebtUseCase deleteDebt;
  final GetStrategiesUseCase getStrategies;
  final CalculateLoanUseCase calculateLoan;

  DebtBloc({
    required this.getDebts,
    required this.createDebt,
    required this.updateDebt,
    required this.deleteDebt,
    required this.getStrategies,
    required this.calculateLoan,
  }) : super(const DebtInitial()) {
    on<LoadDebts>(_onLoad);
    on<CreateDebt>(_onCreate);
    on<UpdateDebt>(_onUpdate);
    on<DeleteDebt>(_onDelete);
    on<LoadStrategies>(_onStrategies);
    on<CalculateLoan>(_onCalculate);
    on<CalculateMortgage>(_onCalculateMortgage);
  }

  Future<void> _onLoad(LoadDebts e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      emit(DebtsLoaded(await getDebts()));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onCreate(CreateDebt e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      emit(DebtCreated(await createDebt(e.data)));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onUpdate(UpdateDebt e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      emit(DebtUpdated(await updateDebt(e.id, e.data)));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onDelete(DeleteDebt e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      await deleteDebt(e.id);
      emit(DebtDeleted(e.id));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onStrategies(LoadStrategies e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      emit(StrategiesLoaded(await getStrategies()));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onCalculate(CalculateLoan e, Emitter<DebtState> emit) async {
    emit(const DebtLoading());
    try {
      emit(LoanCalculated(await calculateLoan(e.data)));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  Future<void> _onCalculateMortgage(
    CalculateMortgage e,
    Emitter<DebtState> emit,
  ) async {
    emit(const DebtLoading());
    try {
      // Reuse calculateLoan datasource with mortgage endpoint via bloc event
      emit(LoanCalculated(await calculateLoan(e.data)));
    } catch (err) {
      emit(DebtError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
