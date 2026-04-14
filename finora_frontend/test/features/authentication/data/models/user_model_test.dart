import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/authentication/data/models/user_model.dart';
import 'package:finora_frontend/features/authentication/domain/entities/user.dart';

void main() {
  const tCreatedAt = '2024-01-15T10:30:00.000Z';
  const tUpdatedAt = '2024-06-01T08:00:00.000Z';

  const tJsonFull = <String, dynamic>{
    'id': 'user-123',
    'email': 'test@finora.app',
    'name': 'Test User',
    'phone_number': '+34600000000',
    'created_at': tCreatedAt,
    'updated_at': tUpdatedAt,
    'is_email_verified': true,
    'is_2fa_enabled': false,
  };

  final tModel = UserModel(
    id: 'user-123',
    email: 'test@finora.app',
    name: 'Test User',
    phoneNumber: '+34600000000',
    createdAt: DateTime.parse(tCreatedAt),
    updatedAt: DateTime.parse(tUpdatedAt),
    isEmailVerified: true,
    is2FAEnabled: false,
  );

  // ── fromJson ────────────────────────────────────────────────────────────────
  group('UserModel.fromJson', () {
    test('mapea todos los campos obligatorios correctamente', () {
      final model = UserModel.fromJson(tJsonFull);

      expect(model.id, 'user-123');
      expect(model.email, 'test@finora.app');
      expect(model.name, 'Test User');
      expect(model.phoneNumber, '+34600000000');
      expect(model.createdAt, DateTime.parse(tCreatedAt));
      expect(model.updatedAt, DateTime.parse(tUpdatedAt));
      expect(model.isEmailVerified, true);
      expect(model.is2FAEnabled, false);
    });

    test('usa valores por defecto cuando campos booleanos son null', () {
      final minJson = <String, dynamic>{
        'id': 'user-1',
        'email': 'a@b.com',
        'name': 'Ana',
        'created_at': tCreatedAt,
      };

      final model = UserModel.fromJson(minJson);

      expect(model.phoneNumber, isNull);
      expect(model.updatedAt, isNull);
      expect(model.isEmailVerified, false);   // default
      expect(model.is2FAEnabled, false);      // default
    });
  });

  // ── toJson ──────────────────────────────────────────────────────────────────
  group('UserModel.toJson', () {
    test('serializa todos los campos correctamente', () {
      final json = tModel.toJson();

      expect(json['id'], 'user-123');
      expect(json['email'], 'test@finora.app');
      expect(json['name'], 'Test User');
      expect(json['phone_number'], '+34600000000');
      expect(json['is_email_verified'], true);
      expect(json['is_2fa_enabled'], false);
    });

    test('updated_at es null cuando no se proporcionó', () {
      final model = UserModel(
        id: 'x',
        email: 'x@x.com',
        name: 'X',
        createdAt: DateTime(2024),
      );
      expect(model.toJson()['updated_at'], isNull);
    });
  });

  // ── fromEntity ──────────────────────────────────────────────────────────────
  group('UserModel.fromEntity', () {
    test('crea UserModel desde User entity con todos los campos', () {
      final entity = User(
        id: 'user-123',
        email: 'test@finora.app',
        name: 'Test User',
        phoneNumber: '+34600000000',
        createdAt: DateTime.parse(tCreatedAt),
        is2FAEnabled: true,
      );

      final model = UserModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.email, entity.email);
      expect(model.is2FAEnabled, true);
    });
  });

  // ── toEntity ────────────────────────────────────────────────────────────────
  group('UserModel.toEntity', () {
    test('retorna User entity con los mismos valores', () {
      final entity = tModel.toEntity();

      expect(entity, isA<User>());
      expect(entity.id, tModel.id);
      expect(entity.email, tModel.email);
      expect(entity.isEmailVerified, tModel.isEmailVerified);
    });
  });

  // ── copyWith ────────────────────────────────────────────────────────────────
  group('UserModel.copyWith', () {
    test('sobreescribe solo los campos indicados', () {
      final updated = tModel.copyWith(name: 'Nuevo Nombre', is2FAEnabled: true);

      expect(updated.name, 'Nuevo Nombre');
      expect(updated.is2FAEnabled, true);
      expect(updated.email, tModel.email);   // sin cambio
      expect(updated.id, tModel.id);          // sin cambio
    });
  });

  // ── Equatable ───────────────────────────────────────────────────────────────
  group('User Equatable', () {
    test('dos usuarios con mismos datos son iguales', () {
      final user1 = tModel.toEntity();
      final user2 = UserModel.fromJson(tJsonFull).toEntity();

      expect(user1, equals(user2));
    });
  });
}
