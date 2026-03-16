import '../../domain/entities/household_entity.dart';
import '../../domain/entities/household_member_entity.dart';
import '../../domain/entities/shared_transaction_entity.dart';
import '../../domain/entities/balance_entity.dart';

class HouseholdModel extends HouseholdEntity {
  const HouseholdModel({
    required super.id,
    required super.name,
    required super.ownerId,
    super.inviteCode,
    required super.createdAt,
  });

  factory HouseholdModel.fromJson(Map<String, dynamic> j) => HouseholdModel(
    id: j['id'] as String,
    name: j['name'] as String,
    ownerId: j['owner_id'] as String,
    inviteCode: j['invite_code'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class HouseholdMemberModel extends HouseholdMemberEntity {
  const HouseholdMemberModel({
    required super.id,
    required super.userId,
    required super.role,
    super.name,
    super.email,
    required super.joinedAt,
  });

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> j) =>
      HouseholdMemberModel(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        role: j['role'] as String? ?? 'member',
        name: j['name'] as String?,
        email: j['email'] as String?,
        joinedAt: DateTime.parse(j['joined_at'] as String),
      );
}

class SharedTransactionModel extends SharedTransactionEntity {
  const SharedTransactionModel({
    required super.id,
    required super.amount,
    required super.description,
    required super.createdByName,
    required super.createdAt,
    required super.splits,
  });

  factory SharedTransactionModel.fromJson(Map<String, dynamic> j) =>
      SharedTransactionModel(
        id: j['id'] as String,
        amount: (j['amount'] as num).toDouble(),
        description: j['description'] as String,
        createdByName: j['created_by_name'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
        splits: List<Map<String, dynamic>>.from(j['splits'] as List? ?? []),
      );
}

class BalanceModel extends BalanceEntity {
  const BalanceModel({
    required super.payerId,
    required super.owerId,
    required super.amount,
  });

  factory BalanceModel.fromJson(Map<String, dynamic> j) => BalanceModel(
    payerId: j['payer_id'] as String,
    owerId: j['ower_id'] as String,
    amount: (j['amount'] as num).toDouble(),
  );
}
