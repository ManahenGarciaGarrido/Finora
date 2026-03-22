class ExtractedReceiptEntity {
  final double? amount;
  final String date;
  final String description;
  final String? merchant;
  final String? suggestedCategory;
  final List<String> rawLines;
  final String confidence;

  const ExtractedReceiptEntity({
    this.amount,
    required this.date,
    required this.description,
    this.merchant,
    this.suggestedCategory,
    required this.rawLines,
    required this.confidence,
  });
}
