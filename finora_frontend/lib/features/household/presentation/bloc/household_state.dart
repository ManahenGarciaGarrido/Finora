import '../../domain/entities/household_entity.dart';
import '../../domain/entities/household_member_entity.dart';
import '../../domain/entities/shared_transaction_entity.dart';
import '../../domain/entities/balance_entity.dart';

abstract class HouseholdState {
  const HouseholdState();
}

class HouseholdInitial extends HouseholdState {
  const HouseholdInitial();
}

class HouseholdLoading extends HouseholdState {
  const HouseholdLoading();
}

class HouseholdLoaded extends HouseholdState {
  final HouseholdEntity? household;
  const HouseholdLoaded(this.household);
}

class HouseholdCreated extends HouseholdState {
  final HouseholdEntity household;
  const HouseholdCreated(this.household);
}

class MembersLoaded extends HouseholdState {
  final List<HouseholdMemberEntity> members;
  const MembersLoaded(this.members);
}

class MemberInvited extends HouseholdState {
  const MemberInvited();
}

class TransactionsLoaded extends HouseholdState {
  final List<SharedTransactionEntity> transactions;
  const TransactionsLoaded(this.transactions);
}

class BalancesLoaded extends HouseholdState {
  final List<BalanceEntity> balances;
  const BalancesLoaded(this.balances);
}

class BalanceSettled extends HouseholdState {
  const BalanceSettled();
}

class HouseholdError extends HouseholdState {
  final String message;
  const HouseholdError(this.message);
}
