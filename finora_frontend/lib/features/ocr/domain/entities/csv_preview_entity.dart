class CsvRowEntity {
  final int index;
  final double amount;
  final String? date;
  final String description;
  final String type;
  bool selected;

  CsvRowEntity({
    required this.index,
    required this.amount,
    this.date,
    required this.description,
    this.type = 'expense',
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
