import '../../domain/entities/bank_account_entity.dart';

class BankAccountModel extends BankAccountEntity {
  const BankAccountModel({
    required super.id,
    required super.connectionId,
    super.externalAccountId,
    super.iban,
    required super.accountName,
    super.currency,
    required super.balanceCents,
    super.institutionName,
    super.institutionLogo,
    super.lastSyncAt,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) {
    return BankAccountModel(
      id: json['id'] as String,
      connectionId: (json['connection_id'] as String?) ?? '',
      externalAccountId: json['external_account_id'] as String?,
      iban: json['iban'] as String?,
      accountName: (json['account_name'] as String?) ?? 'Cuenta bancaria',
      currency: (json['currency'] as String?) ?? 'EUR',
      balanceCents: (json['balance_cents'] as num?)?.toInt() ?? 0,
      institutionName: json['institution_name'] as String?,
      institutionLogo: json['institution_logo'] as String?,
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.parse(json['last_sync_at'] as String)
          : null,
    );
  }
}
