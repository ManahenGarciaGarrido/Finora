abstract class OcrEvent {
  const OcrEvent();
}

class ExtractReceiptText extends OcrEvent {
  final String rawText;
  const ExtractReceiptText(this.rawText);
}

class ImportReceipt extends OcrEvent {
  final double amount;
  final String date;
  final String description;
  final String? category;
  const ImportReceipt({
    required this.amount,
    required this.date,
    required this.description,
    this.category,
  });
}

class ParseCsv extends OcrEvent {
  final String csvContent;
  const ParseCsv(this.csvContent);
}

class ImportCsvRows extends OcrEvent {
  final List<dynamic> rows; // List<CsvRowEntity>
  final bool skipDuplicates;
  const ImportCsvRows(this.rows, {this.skipDuplicates = true});
}

class ParsePdf extends OcrEvent {
  final String pdfBase64;
  const ParsePdf(this.pdfBase64);
}
