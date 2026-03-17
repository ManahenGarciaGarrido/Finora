class ExtractedReceiptEntity {
  final double? amount;
  final String date;
  final String description;
  final List<String> rawLines;
  final String confidence;

  const ExtractedReceiptEntity({
    this.amount,
    required this.date,
    required this.description,
    required this.rawLines,
    required this.confidence,
  });
}
