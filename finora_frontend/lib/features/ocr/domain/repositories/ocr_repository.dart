import '../entities/extracted_receipt_entity.dart';
import '../entities/csv_preview_entity.dart';

abstract class OcrRepository {
  Future<ExtractedReceiptEntity> extractFromText(String rawText);
  Future<void> importReceipt({
    required double amount,
    required String date,
    required String description,
    String? category,
  });
  Future<CsvPreviewEntity> parseCsv(String csvContent);
  Future<CsvPreviewEntity> parsePdf(String pdfBase64);
  Future<Map<String, dynamic>> importCsvRows(
    List<CsvRowEntity> rows, {
    bool skipDuplicates,
  });
}
