import '../../domain/entities/extracted_receipt_entity.dart';
import '../../domain/entities/csv_preview_entity.dart';

abstract class OcrState {
  const OcrState();
}

class OcrInitial extends OcrState {
  const OcrInitial();
}

class OcrLoading extends OcrState {
  const OcrLoading();
}

class ReceiptExtracted extends OcrState {
  final ExtractedReceiptEntity receipt;
  const ReceiptExtracted(this.receipt);
}

class ReceiptImported extends OcrState {
  const ReceiptImported();
}

class CsvParsed extends OcrState {
  final CsvPreviewEntity preview;
  const CsvParsed(this.preview);
}

class CsvImported extends OcrState {
  final int imported;
  final int skipped;
  const CsvImported({required this.imported, required this.skipped});
}

class OcrError extends OcrState {
  final String message;
  const OcrError(this.message);
}
