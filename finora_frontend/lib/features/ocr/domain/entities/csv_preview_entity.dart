class CsvRowEntity {
  final int index;
  final double amount;
  final String? date;
  final String description;
  bool selected;

  CsvRowEntity({
    required this.index,
    required this.amount,
    this.date,
    required this.description,
    this.selected = true,
  });
}

class CsvPreviewEntity {
  final List<String> headers;
  final List<CsvRowEntity> rows;
  final int totalRows;
  final Map<String, int> columnMapping;

  const CsvPreviewEntity({
    required this.headers,
    required this.rows,
    required this.totalRows,
    required this.columnMapping,
  });
}
