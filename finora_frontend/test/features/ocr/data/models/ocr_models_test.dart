import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/ocr/data/models/ocr_models.dart';
import 'package:finora_frontend/features/ocr/domain/entities/extracted_receipt_entity.dart';
import 'package:finora_frontend/features/ocr/domain/entities/csv_preview_entity.dart';

void main() {
  // ── ExtractedReceiptModel ─────────────────────────────────────────────────
  group('ExtractedReceiptModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'amount': 49.99,
        'date': '2024-06-01',
        'description': 'Supermercado Mercadona',
        'merchant': 'Mercadona',
        'suggested_category': 'food',
        'raw_lines': ['Mercadona', 'Total: 49.99€'],
        'confidence': 'high',
      };

      final model = ExtractedReceiptModel.fromJson(json);

      expect(model.amount, 49.99);
      expect(model.date, '2024-06-01');
      expect(model.description, 'Supermercado Mercadona');
      expect(model.merchant, 'Mercadona');
      expect(model.suggestedCategory, 'food');
      expect(model.rawLines, ['Mercadona', 'Total: 49.99€']);
      expect(model.confidence, 'high');
    });

    test('amount es null cuando no está en el JSON', () {
      final model = ExtractedReceiptModel.fromJson(<String, dynamic>{
        'amount': null,
        'date': '2024-01-01',
        'description': 'Ticket',
        'raw_lines': <String>[],
        'confidence': 'low',
      });
      expect(model.amount, isNull);
    });

    test('raw_lines vacía cuando es null', () {
      final model = ExtractedReceiptModel.fromJson(<String, dynamic>{
        'date': '2024-01-01',
        'description': 'Test',
        'raw_lines': null,
        'confidence': 'low',
      });
      expect(model.rawLines, isEmpty);
    });

    test('confidence usa "low" por defecto cuando es null', () {
      final model = ExtractedReceiptModel.fromJson(<String, dynamic>{
        'date': '2024-01-01',
        'description': 'Test',
        'raw_lines': <String>[],
        'confidence': null,
      });
      expect(model.confidence, 'low');
    });

    test('es instancia de ExtractedReceiptEntity', () {
      final model = ExtractedReceiptModel.fromJson(<String, dynamic>{
        'date': '2024-01-01',
        'description': 'Test',
        'raw_lines': <String>[],
        'confidence': 'medium',
      });
      expect(model, isA<ExtractedReceiptEntity>());
    });
  });

  // ── CsvRowModel ───────────────────────────────────────────────────────────
  group('CsvRowModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'index': 0,
        'amount': 99.50,
        'date': '2024-01-15',
        'description': 'Alquiler',
        'type': 'expense',
      };

      final model = CsvRowModel.fromJson(json);

      expect(model.index, 0);
      expect(model.amount, 99.50);
      expect(model.date, '2024-01-15');
      expect(model.description, 'Alquiler');
      expect(model.type, 'expense');
    });

    test('type usa "expense" por defecto cuando es null', () {
      final model = CsvRowModel.fromJson(<String, dynamic>{
        'index': 1,
        'amount': 50.0,
        'description': 'Test',
        'type': null,
      });
      expect(model.type, 'expense');
    });

    test('convierte amount desde String', () {
      final model = CsvRowModel.fromJson(<String, dynamic>{
        'index': 0,
        'amount': '123.45',
        'description': 'Test',
      });
      expect(model.amount, 123.45);
    });
  });

  // ── CsvPreviewModel ───────────────────────────────────────────────────────
  group('CsvPreviewModel.fromJson', () {
    test('mapea headers, rows, totalRows y columnMapping correctamente', () {
      final json = <String, dynamic>{
        'headers': ['fecha', 'importe', 'descripcion'],
        'rows': [
          <String, dynamic>{
            'index': 0,
            'amount': 50.0,
            'date': '2024-01-01',
            'description': 'Compra',
          },
        ],
        'total_rows': 1,
        'column_mapping': <String, dynamic>{
          'fecha': 0,
          'importe': 1,
          'descripcion': 2,
        },
      };

      final model = CsvPreviewModel.fromJson(json);

      expect(model.headers, ['fecha', 'importe', 'descripcion']);
      expect(model.rows.length, 1);
      expect(model.totalRows, 1);
      expect(model.columnMapping['fecha'], 0);
    });

    test('headers vacía y rows vacías cuando son null', () {
      final model = CsvPreviewModel.fromJson(<String, dynamic>{
        'headers': null,
        'rows': null,
        'total_rows': 0,
        'column_mapping': null,
      });
      expect(model.headers, isEmpty);
      expect(model.rows, isEmpty);
      expect(model.columnMapping, isEmpty);
    });

    test('es instancia de CsvPreviewEntity', () {
      final model = CsvPreviewModel.fromJson(<String, dynamic>{
        'headers': <String>[],
        'rows': <Map<String, dynamic>>[],
        'total_rows': 0,
        'column_mapping': <String, dynamic>{},
      });
      expect(model, isA<CsvPreviewEntity>());
    });
  });
}
