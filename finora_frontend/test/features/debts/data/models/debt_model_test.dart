import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/debts/data/models/debt_model.dart';

void main() {
  const tJsonFull = <String, dynamic>{
    'id': 'debt-1',
    'user_id': 'user-1',
    'name': 'Car Loan',
    'type': 'own',
    'creditor_name': 'Banco Santander',
    'amount': 15000.0,
    'remaining_amount': 10000.0,
    'interest_rate': 5.5,
    'due_date': '2028-12-31',
    'monthly_payment': 250.0,
    'notes': 'Monthly auto payment',
    'is_active': true,
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': '2024-06-01T00:00:00.000Z',
  };

  group('DebtModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final model = DebtModel.fromJson(tJsonFull);

      expect(model.id, 'debt-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Car Loan');
      expect(model.type, 'own');
      expect(model.creditorName, 'Banco Santander');
      expect(model.amount, 15000.0);
      expect(model.remainingAmount, 10000.0);
      expect(model.interestRate, 5.5);
      expect(model.dueDate, DateTime(2028, 12, 31));
      expect(model.monthlyPayment, 250.0);
      expect(model.notes, 'Monthly auto payment');
      expect(model.isActive, true);
    });

    test('usa defaults cuando campos opcionales son null', () {
      final minJson = <String, dynamic>{
        'id': 'debt-2',
        'name': 'Personal Loan',
        'amount': 5000,
        'remaining_amount': 5000,
        'interest_rate': 3.0,
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };

      final model = DebtModel.fromJson(minJson);

      expect(model.userId, '');         // default
      expect(model.type, 'own');        // default
      expect(model.creditorName, isNull);
      expect(model.dueDate, isNull);
      expect(model.monthlyPayment, isNull);
      expect(model.notes, isNull);
    });

    test('_d() convierte String numérico a double', () {
      final json = <String, dynamic>{
        ...tJsonFull,
        'amount': '12500.50',
        'interest_rate': '4',
      };

      final model = DebtModel.fromJson(json);

      expect(model.amount, 12500.50);
      expect(model.interestRate, 4.0);
    });
  });

  group('DebtModel.toJson', () {
    test('serializa los campos para el backend', () {
      final model = DebtModel.fromJson(tJsonFull);
      final json = model.toJson();

      expect(json['name'], 'Car Loan');
      expect(json['type'], 'own');
      expect(json['amount'], 15000.0);
      expect(json['interest_rate'], 5.5);
      expect(json['due_date'], '2028-12-31');
    });

    test('due_date es null en toJson cuando no hay fecha', () {
      final minJson = <String, dynamic>{
        'id': 'x',
        'name': 'Loan',
        'amount': 1000,
        'remaining_amount': 1000,
        'interest_rate': 2.0,
        'is_active': true,
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-01T00:00:00.000Z',
      };
      expect(DebtModel.fromJson(minJson).toJson()['due_date'], isNull);
    });
  });

  group('DebtEntity getters heredados', () {
    test('isOwn retorna true cuando type es own', () {
      final model = DebtModel.fromJson(tJsonFull);
      expect(model.isOwn, true);
    });

    test('paidAmount es amount - remainingAmount', () {
      final model = DebtModel.fromJson(tJsonFull);
      expect(model.paidAmount, closeTo(5000.0, 0.01));
    });

    test('progressPercent es (paidAmount / amount) * 100', () {
      final model = DebtModel.fromJson(tJsonFull);
      expect(model.progressPercent, closeTo(33.33, 0.01));
    });

    test('progressPercent es 0 cuando amount es 0', () {
      final json = <String, dynamic>{
        ...tJsonFull,
        'amount': 0,
        'remaining_amount': 0,
      };
      expect(DebtModel.fromJson(json).progressPercent, 0.0);
    });
  });
}

