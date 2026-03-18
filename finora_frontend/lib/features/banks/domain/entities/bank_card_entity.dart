import 'package:equatable/equatable.dart';

/// Represents a payment card associated with a bank account (RF-10)
class BankCardEntity extends Equatable {
  final String id;
  final String bankAccountId;
  final String userId;
  final String cardName;
  final String cardType; // debit, credit, prepaid
  final String? lastFour;
  final DateTime? createdAt;

  const BankCardEntity({
    required this.id,
    required this.bankAccountId,
    required this.userId,
    required this.cardName,
    this.cardType = 'debit',
    this.lastFour,
    this.createdAt,
  });

  String get cardTypeLabel {
    switch (cardType) {
      case 'credit':
        return 'Crédito';
      case 'prepaid':
        return 'Prepago';
      case 'debit':
      default:
        return 'Débito';
    }
  }

  String get displayName {
    if (lastFour != null) return '$cardName ••••$lastFour';
    return cardName;
  }

  @override
  List<Object?> get props => [id, bankAccountId, cardType];
}
