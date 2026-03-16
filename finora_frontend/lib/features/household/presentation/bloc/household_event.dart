abstract class HouseholdEvent {
  const HouseholdEvent();
}

class LoadHousehold extends HouseholdEvent {
  const LoadHousehold();
}

class CreateHousehold extends HouseholdEvent {
  final String name;
  const CreateHousehold(this.name);
}

class InviteMember extends HouseholdEvent {
  final String email;
  const InviteMember(this.email);
}

class RemoveMember extends HouseholdEvent {
  final String userId;
  const RemoveMember(this.userId);
}

class LoadMembers extends HouseholdEvent {
  const LoadMembers();
}

class LoadSharedTransactions extends HouseholdEvent {
  const LoadSharedTransactions();
}

class CreateSharedTransaction extends HouseholdEvent {
  final Map<String, dynamic> data;
  const CreateSharedTransaction(this.data);
}

class LoadBalances extends HouseholdEvent {
  const LoadBalances();
}

class SettleBalance extends HouseholdEvent {
  final String withUserId;
  const SettleBalance(this.withUserId);
}
