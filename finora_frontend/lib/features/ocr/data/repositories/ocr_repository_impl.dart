import '../../domain/entities/extracted_receipt_entity.dart';
import '../../domain/entities/csv_preview_entity.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../datasources/ocr_remote_datasource.dart';

class OcrRepositoryImpl implements OcrRepository {
  final OcrRemoteDataSource _ds;
  OcrRepositoryImpl(this._ds);

  @override
  Future<ExtractedReceiptEntity> extractFromText(String rawText) =>
      _ds.extractFromText(rawText);

  @override
  Future<void> importReceipt({
    required double amount,
    required String date,
    required String description,
    String? category,
  }) => _ds.importReceipt(
    amount: amount,
    date: date,
    description: description,
    category: category,
  );

  @override
  Future<CsvPreviewEntity> parseCsv(String csvContent) =>
      _ds.parseCsv(csvContent);

  @override
  Future<CsvPreviewEntity> parsePdf(String pdfBase64) =>
      _ds.parsePdf(pdfBase64);

  @override
  Future<Map<String, dynamic>> importCsvRows(
    List<CsvRowEntity> rows, {
    bool skipDuplicates = true,
  }) => _ds.importCsvRows(rows, skipDuplicates: skipDuplicates);
}
