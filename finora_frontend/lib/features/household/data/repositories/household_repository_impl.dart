import '../../domain/entities/household_entity.dart';
import '../../domain/entities/household_member_entity.dart';
import '../../domain/entities/shared_transaction_entity.dart';
import '../../domain/entities/balance_entity.dart';
import '../../domain/repositories/household_repository.dart';
import '../datasources/household_remote_datasource.dart';

class HouseholdRepositoryImpl implements HouseholdRepository {
  final HouseholdRemoteDataSource _ds;
  HouseholdRepositoryImpl(this._ds);

  @override
  Future<HouseholdEntity?> getHousehold() => _ds.getHousehold();

  @override
  Future<HouseholdEntity> createHousehold(String name) =>
      _ds.createHousehold(name);

  @override
  Future<void> deleteHousehold() => _ds.deleteHousehold();

  @override
  Future<void> inviteMember(String email) => _ds.inviteMember(email);

  @override
  Future<void> removeMember(String userId) => _ds.removeMember(userId);

  @override
  Future<List<HouseholdMemberEntity>> getMembers() => _ds.getMembers();

  @override
  Future<void> createSharedTransaction(Map<String, dynamic> data) =>
      _ds.createSharedTransaction(data);

  @override
  Future<List<SharedTransactionEntity>> getSharedTransactions() =>
      _ds.getSharedTransactions();

  @override
  Future<List<BalanceEntity>> getBalances() => _ds.getBalances();

  @override
  Future<void> settleBalance(String withUserId) =>
      _ds.settleBalance(withUserId);
}
