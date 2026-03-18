import '../entities/household_entity.dart';
import '../entities/household_member_entity.dart';
import '../entities/shared_transaction_entity.dart';
import '../entities/balance_entity.dart';

abstract class HouseholdRepository {
  Future<HouseholdEntity?> getHousehold();
  Future<HouseholdEntity> createHousehold(String name);
  Future<void> deleteHousehold();
  Future<void> inviteMember(String email);
  Future<void> removeMember(String userId);
  Future<List<HouseholdMemberEntity>> getMembers();
  Future<void> createSharedTransaction(Map<String, dynamic> data);
  Future<List<SharedTransactionEntity>> getSharedTransactions();
  Future<List<BalanceEntity>> getBalances();
  Future<void> settleBalance(String withUserId);
}
