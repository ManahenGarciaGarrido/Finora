import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/household_repository.dart';
import 'household_event.dart';
import 'household_state.dart';

class HouseholdBloc extends Bloc<HouseholdEvent, HouseholdState> {
  final HouseholdRepository _repo;

  HouseholdBloc(this._repo) : super(const HouseholdInitial()) {
    on<LoadHousehold>(_onLoad);
    on<CreateHousehold>(_onCreate);
    on<InviteMember>(_onInvite);
    on<RemoveMember>(_onRemove);
    on<LoadMembers>(_onLoadMembers);
    on<LoadSharedTransactions>(_onLoadTx);
    on<CreateSharedTransaction>(_onCreateTx);
    on<LoadBalances>(_onLoadBalances);
    on<SettleBalance>(_onSettle);
  }

  Future<void> _onLoad(LoadHousehold e, Emitter<HouseholdState> emit) async {
    emit(const HouseholdLoading());
    try {
      emit(HouseholdLoaded(await _repo.getHousehold()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onCreate(
    CreateHousehold e,
    Emitter<HouseholdState> emit,
  ) async {
    emit(const HouseholdLoading());
    try {
      emit(HouseholdCreated(await _repo.createHousehold(e.name)));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onInvite(InviteMember e, Emitter<HouseholdState> emit) async {
    emit(const HouseholdLoading());
    try {
      await _repo.inviteMember(e.email);
      emit(const MemberInvited());
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onRemove(RemoveMember e, Emitter<HouseholdState> emit) async {
    emit(const HouseholdLoading());
    try {
      await _repo.removeMember(e.userId);
      emit(MembersLoaded(await _repo.getMembers()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onLoadMembers(
    LoadMembers e,
    Emitter<HouseholdState> emit,
  ) async {
    emit(const HouseholdLoading());
    try {
      emit(MembersLoaded(await _repo.getMembers()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onLoadTx(
    LoadSharedTransactions e,
    Emitter<HouseholdState> emit,
  ) async {
    emit(const HouseholdLoading());
    try {
      emit(TransactionsLoaded(await _repo.getSharedTransactions()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onCreateTx(
    CreateSharedTransaction e,
    Emitter<HouseholdState> emit,
  ) async {
    emit(const HouseholdLoading());
    try {
      await _repo.createSharedTransaction(e.data);
      emit(TransactionsLoaded(await _repo.getSharedTransactions()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onLoadBalances(
    LoadBalances e,
    Emitter<HouseholdState> emit,
  ) async {
    emit(const HouseholdLoading());
    try {
      emit(BalancesLoaded(await _repo.getBalances()));
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  Future<void> _onSettle(SettleBalance e, Emitter<HouseholdState> emit) async {
    emit(const HouseholdLoading());
    try {
      await _repo.settleBalance(e.withUserId);
      emit(const BalanceSettled());
    } catch (err) {
      emit(HouseholdError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
