import '../../domain/entities/bank_card_entity.dart';

class BankCardModel extends BankCardEntity {
  const BankCardModel({
    required super.id,
    required super.bankAccountId,
    required super.userId,
    required super.cardName,
    super.cardType,
    super.lastFour,
    super.createdAt,
  });

  factory BankCardModel.fromJson(Map<String, dynamic> json) {
    return BankCardModel(
      id: json['id'] as String,
      bankAccountId: json['bank_account_id'] as String,
      userId: json['user_id'] as String,
      cardName: (json['card_name'] as String?) ?? 'Tarjeta',
      cardType: (json['card_type'] as String?) ?? 'debit',
      lastFour: json['last_four'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
