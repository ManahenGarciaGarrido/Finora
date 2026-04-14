import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/fiscal/data/models/fiscal_models.dart';
import 'package:finora_frontend/features/fiscal/domain/entities/fiscal_transaction_entity.dart';

void main() {
  // ── FiscalTransactionModel ────────────────────────────────────────────────
  group('FiscalTransactionModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'id': 'tx-1',
        'description': 'Seguro médico',
        'amount': 120.50,
        'date': '2024-06-01',
        'category': 'health',
        'fiscal_category': 'deductible',
      };

      final model = FiscalTransactionModel.fromJson(json);

      expect(model.id, 'tx-1');
      expect(model.description, 'Seguro médico');
      expect(model.amount, 120.50);
      expect(model.date, '2024-06-01');
      expect(model.category, 'health');
      expect(model.fiscalCategory, 'deductible');
    });

    test('usa valores por defecto cuando los campos son null', () {
      final json = <String, dynamic>{
        'id': null,
        'description': null,
        'amount': null,
        'date': null,
      };

      final model = FiscalTransactionModel.fromJson(json);

      expect(model.id, '');
      expect(model.description, '');
      expect(model.amount, 0.0);
      expect(model.date, '');
      expect(model.category, isNull);
      expect(model.fiscalCategory, isNull);
    });

    test('convierte amount desde String', () {
      final json = <String, dynamic>{
        'id': 'tx-2',
        'description': 'Gastos',
        'amount': '250.75',
        'date': '2024-01-01',
      };

      final model = FiscalTransactionModel.fromJson(json);
      expect(model.amount, 250.75);
    });

    test('es instancia de FiscalTransactionEntity', () {
      final model = FiscalTransactionModel.fromJson(<String, dynamic>{
        'id': 'x',
        'description': 'desc',
        'amount': 10.0,
        'date': '2024-01-01',
      });
      expect(model, isA<FiscalTransactionEntity>());
    });
  });

  // ── TaxBracketModel ───────────────────────────────────────────────────────
  group('TaxBracketModel.fromJson', () {
    test('mapea todos los campos incluyendo to opcional', () {
      final json = <String, dynamic>{
        'from': 0.0,
        'to': 12450.0,
        'rate': 19.0,
        'taxable_amount': 10000.0,
        'tax': 1900.0,
      };

      final model = TaxBracketModel.fromJson(json);

      expect(model.from, 0.0);
      expect(model.to, 12450.0);
      expect(model.rate, 19.0);
      expect(model.taxableAmount, 10000.0);
      expect(model.tax, 1900.0);
    });

    test('to es null cuando no está presente', () {
      final json = <String, dynamic>{
        'from': 60000.0,
        'to': null,
        'rate': 47.0,
        'taxable_amount': 5000.0,
        'tax': 2350.0,
      };

      final model = TaxBracketModel.fromJson(json);
      expect(model.to, isNull);
    });
  });

  // ── IrpfResultModel ───────────────────────────────────────────────────────
  group('IrpfResultModel.fromJson', () {
    test('mapea correctamente con lista de brackets', () {
      final json = <String, dynamic>{
        'annual_income': 30000.0,
        'deductible_total': 2000.0,
        'taxable_base': 28000.0,
        'estimated_tax': 5320.0,
        'net_income': 24680.0,
        'effective_rate': 17.73,
        'brackets': [
          {
            'from': 0.0,
            'to': 12450.0,
            'rate': 19.0,
            'taxable_amount': 12450.0,
            'tax': 2365.5,
          },
        ],
      };

      final model = IrpfResultModel.fromJson(json);

      expect(model.annualIncome, 30000.0);
      expect(model.deductibleTotal, 2000.0);
      expect(model.taxableBase, 28000.0);
      expect(model.estimatedTax, 5320.0);
      expect(model.netIncome, 24680.0);
      expect(model.effectiveRate, 17.73);
      expect(model.brackets.length, 1);
      expect(model.brackets.first.rate, 19.0);
    });

    test('lista brackets vacía no lanza error', () {
      final json = <String, dynamic>{
        'annual_income': 10000.0,
        'deductible_total': 0.0,
        'taxable_base': 10000.0,
        'estimated_tax': 1900.0,
        'net_income': 8100.0,
        'effective_rate': 19.0,
        'brackets': null,
      };

      final model = IrpfResultModel.fromJson(json);
      expect(model.brackets, isEmpty);
    });
  });

  // ── TaxEventModel ─────────────────────────────────────────────────────────
  group('TaxEventModel.fromJson', () {
    test('mapea date, title y type correctamente', () {
      final json = <String, dynamic>{
        'date': '2024-04-30',
        'title': 'Declaración IRPF',
        'type': 'deadline',
      };

      final model = TaxEventModel.fromJson(json);

      expect(model.date, '2024-04-30');
      expect(model.title, 'Declaración IRPF');
      expect(model.type, 'deadline');
    });

    test('usa valores por defecto cuando los campos son null', () {
      final model = TaxEventModel.fromJson(<String, dynamic>{
        'date': null,
        'title': null,
        'type': null,
      });

      expect(model.date, '');
      expect(model.title, '');
      expect(model.type, '');
    });
  });
}

