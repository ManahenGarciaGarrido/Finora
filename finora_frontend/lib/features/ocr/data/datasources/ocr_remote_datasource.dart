import '../../../../core/network/api_client.dart';
import '../models/ocr_models.dart';
import '../../domain/entities/csv_preview_entity.dart';

abstract class OcrRemoteDataSource {
  Future<ExtractedReceiptModel> extractFromText(String rawText);
  Future<void> importReceipt({
    required double amount,
    required String date,
    required String description,
    String? category,
  });
  Future<CsvPreviewModel> parseCsv(String csvContent);
  Future<Map<String, dynamic>> importCsvRows(
    List<CsvRowEntity> rows, {
    bool skipDuplicates,
  });
}

class OcrRemoteDataSourceImpl implements OcrRemoteDataSource {
  final ApiClient _client;
  OcrRemoteDataSourceImpl(this._client);

  @override
  Future<ExtractedReceiptModel> extractFromText(String rawText) async {
    final res = await _client.post('/ocr/extract', data: {'raw_text': rawText});
    return ExtractedReceiptModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> importReceipt({
    required double amount,
    required String date,
    required String description,
    String? category,
  }) async {
    await _client.post(
      '/ocr/import-receipt',
      data: {
        'amount': amount,
        'date': date,
        'description': description,
        if (category != null) 'category': category,
      },
    );
  }

  @override
  Future<CsvPreviewModel> parseCsv(String csvContent) async {
    final res = await _client.post(
      '/ocr/parse-csv',
      data: {'csv_content': csvContent},
    );
    return CsvPreviewModel.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> importCsvRows(
    List<CsvRowEntity> rows, {
    bool skipDuplicates = true,
  }) async {
    final res = await _client.post(
      '/ocr/import-csv',
      data: {
        'rows': rows
            .map(
              (r) => {
                'amount': r.amount,
                'date': r.date,
                'description': r.description,
              },
            )
            .toList(),
        'skip_duplicates': skipDuplicates,
      },
    );
    return res.data as Map<String, dynamic>;
  }
}
