class FiscalTransactionEntity {
  final String id;
  final String description;
  final double amount;
  final String date;
  final String? category;
  final String? fiscalCategory;

  const FiscalTransactionEntity({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.category,
    this.fiscalCategory,
  });
}
