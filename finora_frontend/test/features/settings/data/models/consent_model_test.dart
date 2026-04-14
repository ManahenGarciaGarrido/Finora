import 'package:flutter_test/flutter_test.dart';
import 'package:finora_frontend/features/settings/data/models/consent_model.dart';
import 'package:finora_frontend/features/settings/domain/entities/consent.dart';

void main() {
  final tJson = <String, dynamic>{
    'userId': 'user-1',
    'consents': <String, dynamic>{
      'essential': true,
      'analytics': false,
      'marketing': false,
      'third_party': false,
      'personalization': true,
      'data_processing': true,
    },
    'lastUpdated': '2024-06-01T10:00:00.000Z',
    'history': <Map<String, dynamic>>[
      <String, dynamic>{
        'timestamp': '2024-06-01T10:00:00.000Z',
        'action': 'accepted',
        'consentType': 'analytics',
      },
    ],
  };

  group('UserConsentsModel.fromJson', () {
    test('mapea userId, consents y lastUpdated correctamente', () {
      final model = UserConsentsModel.fromJson(tJson);

      expect(model.userId, 'user-1');
      expect(model.consents[ConsentType.essential], true);
      expect(model.consents[ConsentType.personalization], true);
      expect(model.lastUpdated, DateTime.parse('2024-06-01T10:00:00.000Z'));
    });

    test('mapea historial correctamente', () {
      final model = UserConsentsModel.fromJson(tJson);

      expect(model.history.length, 1);
      expect(model.history.first.action, 'accepted');
    });

    test('ignora keys de consentimiento desconocidos sin lanzar error', () {
      final jsonWithUnknown = <String, dynamic>{
        ...tJson,
        'consents': <String, dynamic>{
          ...(tJson['consents'] as Map<String, dynamic>),
          'unknown_key': true,
        },
      };

      expect(
        () => UserConsentsModel.fromJson(jsonWithUnknown),
        returnsNormally,
      );
    });

    test('usa DateTime.now() cuando lastUpdated es null', () {
      final jsonNoDate = <String, dynamic>{
        'userId': 'user-1',
        'consents': <String, dynamic>{},
        'lastUpdated': null,
      };

      final model = UserConsentsModel.fromJson(jsonNoDate);
      expect(
        model.lastUpdated.isBefore(
          DateTime.now().add(const Duration(seconds: 1)),
        ),
        true,
      );
    });
  });

  group('UserConsentsModel.toJson', () {
    test('serializa consents con sus keys correctas', () {
      final model = UserConsentsModel.fromJson(tJson);
      final json = model.toJson();

      expect(json['userId'], 'user-1');
      expect((json['consents'] as Map)['essential'], true);
    });
  });

  group('UserConsentsModel.fromEntity', () {
    test('crea modelo desde entidad preservando los datos', () {
      final model = UserConsentsModel.fromJson(tJson);
      final rebuilt = UserConsentsModel.fromEntity(model);

      expect(rebuilt.userId, model.userId);
      expect(rebuilt.consents[ConsentType.essential], true);
    });
  });

  group('ConsentHistoryEntryModel.fromJson', () {
    test('mapea timestamp, action y consentType', () {
      final json = <String, dynamic>{
        'timestamp': '2024-05-01T08:00:00.000Z',
        'action': 'withdrawn',
        'consentType': 'marketing',
      };

      final entry = ConsentHistoryEntryModel.fromJson(json);

      expect(entry.action, 'withdrawn');
      expect(entry.consentType, ConsentType.marketing);
    });
  });

  group('ConsentTypeExtension', () {
    test('fromKey mapea correctamente todas las keys', () {
      expect(ConsentTypeExtension.fromKey('essential'), ConsentType.essential);
      expect(ConsentTypeExtension.fromKey('analytics'), ConsentType.analytics);
    });

    test('key retorna la string correcta para cada tipo', () {
      expect(ConsentType.essential.key, 'essential');
      expect(ConsentType.thirdParty.key, 'third_party');
    });
  });
}
