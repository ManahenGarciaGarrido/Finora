import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/banks/data/models/bank_account_model.dart';
import 'package:finora_frontend/features/banks/data/models/bank_card_model.dart';

void main() {
  // ── BankAccountModel ─────────────────────────────────────────────────────────
  group('BankAccountModel.fromJson', () {
    const tAccountJson = <String, dynamic>{
      'id': 'acc-1',
      'connection_id': 'conn-1',
      'external_account_id': 'ext-123',
      'iban': 'ES9121000418450200051332',
      'account_name': 'Cuenta Corriente',
      'account_type': 'current',
      'currency': 'EUR',
      'balance_cents': 150050,
      'institution_name': 'Santander',
      'institution_logo': 'https://logo.url/santander.png',
      'last_sync_at': '2024-06-01T12:00:00.000Z',
    };

    test('mapea todos los campos correctamente', () {
      final model = BankAccountModel.fromJson(tAccountJson);

      expect(model.id, 'acc-1');
      expect(model.connectionId, 'conn-1');
      expect(model.externalAccountId, 'ext-123');
      expect(model.iban, 'ES9121000418450200051332');
      expect(model.accountName, 'Cuenta Corriente');
      expect(model.accountType, 'current');
      expect(model.currency, 'EUR');
      expect(model.balanceCents, 150050);
      expect(model.institutionName, 'Santander');
      expect(model.lastSyncAt, DateTime.parse('2024-06-01T12:00:00.000Z'));
    });

    test('usa defaults cuando campos opcionales son null', () {
      final minJson = <String, dynamic>{
        'id': 'acc-2',
        'balance_cents': 0,
      };

      final model = BankAccountModel.fromJson(minJson);

      expect(model.connectionId, '');               // default
      expect(model.accountName, 'Cuenta bancaria'); // default
      expect(model.accountType, 'current');         // default
      expect(model.currency, 'EUR');                // default
      expect(model.iban, isNull);
      expect(model.lastSyncAt, isNull);
    });

    test('balance_cents como String se parsea correctamente', () {
      final json = <String, dynamic>{
        'id': 'acc-3',
        'balance_cents': '250000',
      };
      expect(BankAccountModel.fromJson(json).balanceCents, 250000);
    });

    test('balance_cents inválido resulta en 0', () {
      final json = <String, dynamic>{
        'id': 'acc-4',
        'balance_cents': 'invalid',
      };
      expect(BankAccountModel.fromJson(json).balanceCents, 0);
    });
  });

  group('BankAccountEntity getters', () {
    final tModel = BankAccountModel.fromJson(<String, dynamic>{
      'id': 'acc-1',
      'balance_cents': 150050,
      'iban': 'ES9121000418450200051332',
    });

    test('balance convierte cents a euros correctamente', () {
      expect(tModel.balance, closeTo(1500.50, 0.001));
    });

    test('maskedIban muestra solo los últimos 4 dígitos', () {
      expect(tModel.maskedIban, contains('1332'));
      expect(tModel.maskedIban, contains('••••'));
    });

    test('maskedIban con null retorna ****', () {
      final model = BankAccountModel.fromJson(<String, dynamic>{'id': 'x', 'balance_cents': 0});
      expect(model.maskedIban, '****');
    });
  });

  // ── BankCardModel ────────────────────────────────────────────────────────────
  group('BankCardModel.fromJson', () {
    const tCardJson = <String, dynamic>{
      'id': 'card-1',
      'bank_account_id': 'acc-1',
      'user_id': 'user-1',
      'card_name': 'Visa Débito',
      'card_type': 'debit',
      'last_four': '4321',
      'created_at': '2024-01-01T00:00:00.000Z',
    };

    test('mapea todos los campos correctamente', () {
      final model = BankCardModel.fromJson(tCardJson);

      expect(model.id, 'card-1');
      expect(model.bankAccountId, 'acc-1');
      expect(model.userId, 'user-1');
      expect(model.cardName, 'Visa Débito');
      expect(model.cardType, 'debit');
      expect(model.lastFour, '4321');
      expect(model.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('usa defaults cuando campos opcionales son null', () {
      final model = BankCardModel.fromJson(<String, dynamic>{
        'id': 'card-2',
        'bank_account_id': 'acc-1',
        'user_id': 'user-1',
      });

      expect(model.cardName, 'Tarjeta');  // default
      expect(model.cardType, 'debit');    // default
      expect(model.lastFour, isNull);
      expect(model.createdAt, isNull);
    });
  });
}


