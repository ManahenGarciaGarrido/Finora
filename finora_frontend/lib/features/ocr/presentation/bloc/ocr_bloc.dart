import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/csv_preview_entity.dart';
import '../../domain/repositories/ocr_repository.dart';
import 'ocr_event.dart';
import 'ocr_state.dart';

class OcrBloc extends Bloc<OcrEvent, OcrState> {
  final OcrRepository _repo;

  OcrBloc(this._repo) : super(const OcrInitial()) {
    on<ExtractReceiptText>(_onExtract);
    on<ImportReceipt>(_onImportReceipt);
    on<ParseCsv>(_onParseCsv);
    on<ParsePdf>(_onParsePdf);
    on<ImportCsvRows>(_onImportCsv);
  }

  Future<void> _onExtract(ExtractReceiptText e, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    try {
      final receipt = await _repo.extractFromText(e.rawText);
      emit(ReceiptExtracted(receipt));
    } catch (err) {
      emit(OcrError(_msg(err)));
    }
  }

  Future<void> _onImportReceipt(ImportReceipt e, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    try {
      await _repo.importReceipt(
        amount: e.amount,
        date: e.date,
        description: e.description,
        category: e.category,
      );
      emit(const ReceiptImported());
    } catch (err) {
      emit(OcrError(_msg(err)));
    }
  }

  Future<void> _onParseCsv(ParseCsv e, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    try {
      final preview = await _repo.parseCsv(e.csvContent);
      emit(CsvParsed(preview));
    } catch (err) {
      emit(OcrError(_msg(err)));
    }
  }

  Future<void> _onParsePdf(ParsePdf e, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    try {
      final preview = await _repo.parsePdf(e.pdfBase64);
      emit(CsvParsed(preview));
    } catch (err) {
      emit(OcrError(_msg(err)));
    }
  }

  Future<void> _onImportCsv(ImportCsvRows e, Emitter<OcrState> emit) async {
    emit(const OcrLoading());
    try {
      final result = await _repo.importCsvRows(
        e.rows.cast<CsvRowEntity>(),
        skipDuplicates: e.skipDuplicates,
      );
      emit(
        CsvImported(
          imported: (result['imported'] as num?)?.toInt() ?? 0,
          skipped: (result['skipped'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (err) {
      emit(OcrError(_msg(err)));
    }
  }

  String _msg(Object e) => e.toString().replaceAll('Exception: ', '');
}
