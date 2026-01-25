import '../../domain/entities/consent.dart';

/// Modelo para serializar/deserializar consentimientos del usuario
class UserConsentsModel extends UserConsents {
  const UserConsentsModel({
    required super.userId,
    required super.consents,
    required super.lastUpdated,
    super.history,
  });

  /// Crea un modelo desde JSON
  factory UserConsentsModel.fromJson(Map<String, dynamic> json) {
    final consentsJson = json['consents'] as Map<String, dynamic>? ?? {};
    final consents = <ConsentType, bool>{};

    consentsJson.forEach((key, value) {
      final type = ConsentTypeExtension.fromKey(key);
      if (type != null) {
        consents[type] = value as bool;
      }
    });

    final historyJson = json['history'] as List<dynamic>? ?? [];
    final history = historyJson
        .map((e) => ConsentHistoryEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return UserConsentsModel(
      userId: json['userId'] as String? ?? '',
      consents: consents,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      history: history,
    );
  }

  /// Convierte el modelo a JSON
  Map<String, dynamic> toJson() {
    final consentsJson = <String, bool>{};
    consents.forEach((key, value) {
      consentsJson[key.key] = value;
    });

    return {
      'userId': userId,
      'consents': consentsJson,
      'lastUpdated': lastUpdated.toIso8601String(),
      'history': history.map((e) => (e as ConsentHistoryEntryModel).toJson()).toList(),
    };
  }

  /// Crea un modelo desde la entidad
  factory UserConsentsModel.fromEntity(UserConsents entity) {
    return UserConsentsModel(
      userId: entity.userId,
      consents: entity.consents,
      lastUpdated: entity.lastUpdated,
      history: entity.history,
    );
  }

  /// Convierte solo los consentimientos a JSON para enviar al servidor
  Map<String, bool> consentsToJson() {
    final consentsJson = <String, bool>{};
    consents.forEach((key, value) {
      consentsJson[key.key] = value;
    });
    return consentsJson;
  }
}

/// Modelo para entrada del historial de consentimientos
class ConsentHistoryEntryModel extends ConsentHistoryEntry {
  const ConsentHistoryEntryModel({
    required super.timestamp,
    required super.action,
    super.consentType,
    super.consents,
    super.ipAddress,
    super.userAgent,
  });

  factory ConsentHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    Map<ConsentType, bool>? consents;
    if (json['consents'] != null) {
      consents = <ConsentType, bool>{};
      (json['consents'] as Map<String, dynamic>).forEach((key, value) {
        final type = ConsentTypeExtension.fromKey(key);
        if (type != null) {
          consents![type] = value as bool;
        }
      });
    }

    ConsentType? consentType;
    if (json['consentType'] != null) {
      consentType = ConsentTypeExtension.fromKey(json['consentType'] as String);
    }

    return ConsentHistoryEntryModel(
      timestamp: DateTime.parse(json['timestamp'] as String),
      action: json['action'] as String,
      consentType: consentType,
      consents: consents,
      ipAddress: json['ipAddress'] as String?,
      userAgent: json['userAgent'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final consentsJson = <String, bool>{};
    consents?.forEach((key, value) {
      consentsJson[key.key] = value;
    });

    return {
      'timestamp': timestamp.toIso8601String(),
      'action': action,
      if (consentType != null) 'consentType': consentType!.key,
      if (consents != null) 'consents': consentsJson,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (userAgent != null) 'userAgent': userAgent,
    };
  }
}
