import 'package:equatable/equatable.dart';

/// Represents a bank account retrieved via GoCardless Open Banking (RF-10)
class BankAccountEntity extends Equatable {
  final String id;
  final String connectionId;
  final String? externalAccountId;
  final String? iban;
  final String accountName;
  final String currency;
  final int balanceCents;
  final String? institutionName;
  final String? institutionLogo;
  final DateTime? lastSyncAt;

  const BankAccountEntity({
    required this.id,
    required this.connectionId,
    this.externalAccountId,
    this.iban,
    required this.accountName,
    this.currency = 'EUR',
    required this.balanceCents,
    this.institutionName,
    this.institutionLogo,
    this.lastSyncAt,
  });

  /// Balance as a decimal (e.g. 150050 cents → 1500.50)
  double get balance => balanceCents / 100.0;

  /// Masked IBAN for display (shows last 4 digits)
  String get maskedIban {
    if (iban == null || iban!.length < 4) return iban ?? '****';
    final clean = iban!.replaceAll(' ', '');
    return '•••• •••• •••• ${clean.substring(clean.length - 4)}';
  }

  @override
  List<Object?> get props => [id, connectionId, externalAccountId, balanceCents];
}
