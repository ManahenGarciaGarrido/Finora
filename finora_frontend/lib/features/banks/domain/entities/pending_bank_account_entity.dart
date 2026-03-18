/// Cuenta bancaria pendiente de confirmar importación (selección post-conexión).
/// Contiene el saldo en divisa original y su equivalente en EUR con tasa real.
class PendingBankAccountEntity {
  final String externalAccountId;
  final String name;
  final String originalCurrency;
  final int originalBalanceCents;
  final int balanceEurCents;
  final String? iban;

  const PendingBankAccountEntity({
    required this.externalAccountId,
    required this.name,
    required this.originalCurrency,
    required this.originalBalanceCents,
    required this.balanceEurCents,
    this.iban,
  });

  double get balanceEur => balanceEurCents / 100.0;
  double get originalBalance => originalBalanceCents / 100.0;
}
