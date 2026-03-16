class BalanceEntity {
  final String payerId;
  final String owerId;
  final double amount;

  const BalanceEntity({
    required this.payerId,
    required this.owerId,
    required this.amount,
  });
}
