import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/household/data/models/household_model.dart';
import 'package:finora_frontend/features/household/domain/entities/household_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/household_member_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/shared_transaction_entity.dart';
import 'package:finora_frontend/features/household/domain/entities/balance_entity.dart';

void main() {
  // ── HouseholdModel ────────────────────────────────────────────────────────
  group('HouseholdModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'id': 'hh-1',
        'name': 'Familia García',
        'owner_id': 'user-1',
        'invite_code': 'ABC123',
        'created_at': '2024-01-01T00:00:00.000Z',
      };

      final model = HouseholdModel.fromJson(json);

      expect(model.id, 'hh-1');
      expect(model.name, 'Familia García');
      expect(model.ownerId, 'user-1');
      expect(model.inviteCode, 'ABC123');
      expect(model.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('inviteCode puede ser null', () {
      final model = HouseholdModel.fromJson(<String, dynamic>{
        'id': 'hh-2',
        'name': 'Hogar',
        'owner_id': 'user-2',
        'invite_code': null,
        'created_at': '2024-01-01T00:00:00.000Z',
      });

      expect(model.inviteCode, isNull);
    });

    test('es instancia de HouseholdEntity', () {
      final model = HouseholdModel.fromJson(<String, dynamic>{
        'id': 'x',
        'name': 'x',
        'owner_id': 'x',
        'created_at': '2024-01-01T00:00:00.000Z',
      });
      expect(model, isA<HouseholdEntity>());
    });
  });

  // ── HouseholdMemberModel ──────────────────────────────────────────────────
  group('HouseholdMemberModel.fromJson', () {
    test('mapea todos los campos correctamente', () {
      final json = <String, dynamic>{
        'id': 'mem-1',
        'user_id': 'user-2',
        'role': 'member',
        'name': 'Ana García',
        'email': 'ana@example.com',
        'joined_at': '2024-02-01T00:00:00.000Z',
      };

      final model = HouseholdMemberModel.fromJson(json);

      expect(model.id, 'mem-1');
      expect(model.userId, 'user-2');
      expect(model.role, 'member');
      expect(model.name, 'Ana García');
      expect(model.email, 'ana@example.com');
      expect(model.joinedAt, DateTime.parse('2024-02-01T00:00:00.000Z'));
    });

    test('role usa "member" como valor por defecto', () {
      final model = HouseholdMemberModel.fromJson(<String, dynamic>{
        'id': 'm-2',
        'user_id': 'u-2',
        'role': null,
        'joined_at': '2024-01-01T00:00:00.000Z',
      });
      expect(model.role, 'member');
    });

    test('es instancia de HouseholdMemberEntity', () {
      final model = HouseholdMemberModel.fromJson(<String, dynamic>{
        'id': 'x',
        'user_id': 'x',
        'joined_at': '2024-01-01T00:00:00.000Z',
      });
      expect(model, isA<HouseholdMemberEntity>());
    });
  });

  // ── SharedTransactionModel ────────────────────────────────────────────────
  group('SharedTransactionModel.fromJson', () {
    test('mapea correctamente', () {
      final json = <String, dynamic>{
        'id': 'st-1',
        'amount': 100.0,
        'description': 'Cena familiar',
        'created_by_name': 'Pedro',
        'created_at': '2024-03-01T00:00:00.000Z',
        'splits': [
          {'user_id': 'u-1', 'amount': 50.0},
          {'user_id': 'u-2', 'amount': 50.0},
        ],
      };

      final model = SharedTransactionModel.fromJson(json);

      expect(model.id, 'st-1');
      expect(model.amount, 100.0);
      expect(model.description, 'Cena familiar');
      expect(model.createdByName, 'Pedro');
      expect(model.splits.length, 2);
    });

    test('createdByName usa string vacía por defecto', () {
      final model = SharedTransactionModel.fromJson(<String, dynamic>{
        'id': 'st-2',
        'amount': 50.0,
        'description': 'Compra',
        'created_by_name': null,
        'created_at': '2024-01-01T00:00:00.000Z',
        'splits': null,
      });
      expect(model.createdByName, '');
      expect(model.splits, isEmpty);
    });

    test('es instancia de SharedTransactionEntity', () {
      final model = SharedTransactionModel.fromJson(<String, dynamic>{
        'id': 'x',
        'amount': 10.0,
        'description': 'x',
        'created_at': '2024-01-01T00:00:00.000Z',
        'splits': [],
      });
      expect(model, isA<SharedTransactionEntity>());
    });
  });

  // ── BalanceModel ──────────────────────────────────────────────────────────
  group('BalanceModel.fromJson', () {
    test('mapea payerId, owerId y amount correctamente', () {
      final json = <String, dynamic>{
        'payer_id': 'user-1',
        'ower_id': 'user-2',
        'amount': 25.50,
      };

      final model = BalanceModel.fromJson(json);

      expect(model.payerId, 'user-1');
      expect(model.owerId, 'user-2');
      expect(model.amount, 25.50);
    });

    test('es instancia de BalanceEntity', () {
      final model = BalanceModel.fromJson(<String, dynamic>{
        'payer_id': 'x',
        'ower_id': 'y',
        'amount': 10,
      });
      expect(model, isA<BalanceEntity>());
    });
  });
}

