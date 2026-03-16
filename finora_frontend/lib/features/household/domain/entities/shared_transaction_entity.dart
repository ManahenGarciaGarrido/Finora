class SharedTransactionEntity {
  final String id;
  final double amount;
  final String description;
  final String createdByName;
  final DateTime createdAt;
  final List<Map<String, dynamic>> splits;

  const SharedTransactionEntity({
    required this.id,
    required this.amount,
    required this.description,
    required this.createdByName,
    required this.createdAt,
    required this.splits,
  });
}
