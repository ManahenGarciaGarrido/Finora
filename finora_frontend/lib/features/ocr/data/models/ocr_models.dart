import '../../domain/entities/extracted_receipt_entity.dart';
import '../../domain/entities/csv_preview_entity.dart';

double _d(dynamic v, [double fallback = 0.0]) =>
    v == null ? fallback : double.tryParse(v.toString()) ?? fallback;

int _i(dynamic v, [int fallback = 0]) =>
    v == null ? fallback : int.tryParse(v.toString()) ?? fallback;

class ExtractedReceiptModel extends ExtractedReceiptEntity {
  const ExtractedReceiptModel({
    super.amount,
    required super.date,
    required super.description,
    required super.rawLines,
    required super.confidence,
  });

  factory ExtractedReceiptModel.fromJson(Map<String, dynamic> j) {
    final rawList = j['raw_lines'] as List? ?? [];
    return ExtractedReceiptModel(
      amount: j['amount'] != null ? _d(j['amount']) : null,
      date: j['date']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      rawLines: rawList.map((e) => e.toString()).toList(),
      confidence: j['confidence']?.toString() ?? 'low',
    );
  }
}

class CsvRowModel extends CsvRowEntity {
  CsvRowModel({
    required super.index,
    required super.amount,
    super.date,
    required super.description,
    super.selected,
  });

  factory CsvRowModel.fromJson(Map<String, dynamic> j) => CsvRowModel(
    index: _i(j['index']),
    amount: _d(j['amount']),
    date: j['date']?.toString(),
    description: j['description']?.toString() ?? '',
  );
}

class CsvPreviewModel extends CsvPreviewEntity {
  const CsvPreviewModel({
    required super.headers,
    required super.rows,
    required super.totalRows,
    required super.columnMapping,
  });

  factory CsvPreviewModel.fromJson(Map<String, dynamic> j) {
    final headerList = (j['headers'] as List? ?? [])
        .map((e) => e.toString())
        .toList();
    final rowList = (j['rows'] as List? ?? [])
        .map((e) => CsvRowModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final mapping = j['column_mapping'] as Map<String, dynamic>? ?? {};
    return CsvPreviewModel(
      headers: headerList,
      rows: rowList,
      totalRows: _i(j['total_rows']),
      columnMapping: mapping.map((k, v) => MapEntry(k, _i(v))),
    );
  }
}
