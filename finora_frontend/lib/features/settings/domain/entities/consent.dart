import 'package:equatable/equatable.dart';

/// Tipos de consentimiento GDPR
enum ConsentType {
  essential,
  analytics,
  marketing,
  thirdParty,
  personalization,
  dataProcessing,
}

/// Extensión para obtener información de cada tipo de consentimiento
extension ConsentTypeExtension on ConsentType {
  String get key {
    switch (this) {
      case ConsentType.essential:
        return 'essential';
      case ConsentType.analytics:
        return 'analytics';
      case ConsentType.marketing:
        return 'marketing';
      case ConsentType.thirdParty:
        return 'third_party';
      case ConsentType.personalization:
        return 'personalization';
      case ConsentType.dataProcessing:
        return 'data_processing';
    }
  }

  String get name {
    switch (this) {
      case ConsentType.essential:
        return 'Cookies y datos esenciales';
      case ConsentType.analytics:
        return 'Análisis y mejora del servicio';
      case ConsentType.marketing:
        return 'Comunicaciones de marketing';
      case ConsentType.thirdParty:
        return 'Compartir datos con terceros';
      case ConsentType.personalization:
        return 'Personalización del servicio';
      case ConsentType.dataProcessing:
        return 'Procesamiento de datos financieros';
    }
  }

  String get description {
    switch (this) {
      case ConsentType.essential:
        return 'Necesarios para el funcionamiento básico de la aplicación. Incluye autenticación, seguridad y preferencias de sesión.';
      case ConsentType.analytics:
        return 'Nos permite analizar cómo usas la aplicación para mejorar la experiencia de usuario.';
      case ConsentType.marketing:
        return 'Te enviaremos ofertas, novedades y consejos financieros personalizados.';
      case ConsentType.thirdParty:
        return 'Compartir información con socios para ofrecerte productos financieros relevantes.';
      case ConsentType.personalization:
        return 'Usar tus datos financieros para personalizar recomendaciones y alertas.';
      case ConsentType.dataProcessing:
        return 'Procesar tus transacciones y datos bancarios para ofrecerte análisis financiero.';
    }
  }

  bool get isRequired {
    switch (this) {
      case ConsentType.essential:
      case ConsentType.dataProcessing:
        return true;
      default:
        return false;
    }
  }

  String get legalBasis {
    switch (this) {
      case ConsentType.essential:
      case ConsentType.dataProcessing:
        return 'Ejecución de contrato (Art. 6.1.b GDPR)';
      default:
        return 'Consentimiento (Art. 6.1.a GDPR)';
    }
  }

  static ConsentType? fromKey(String key) {
    switch (key) {
      case 'essential':
        return ConsentType.essential;
      case 'analytics':
        return ConsentType.analytics;
      case 'marketing':
        return ConsentType.marketing;
      case 'third_party':
        return ConsentType.thirdParty;
      case 'personalization':
        return ConsentType.personalization;
      case 'data_processing':
        return ConsentType.dataProcessing;
      default:
        return null;
    }
  }
}

/// Entidad que representa el registro de un consentimiento individual
class ConsentRecord extends Equatable {
  final ConsentType type;
  final bool granted;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  const ConsentRecord({
    required this.type,
    required this.granted,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  @override
  List<Object?> get props => [type, granted, timestamp, ipAddress, userAgent];
}

/// Entidad que representa todos los consentimientos de un usuario
class UserConsents extends Equatable {
  final String userId;
  final Map<ConsentType, bool> consents;
  final DateTime lastUpdated;
  final List<ConsentHistoryEntry> history;

  const UserConsents({
    required this.userId,
    required this.consents,
    required this.lastUpdated,
    this.history = const [],
  });

  /// Verifica si un consentimiento específico está otorgado
  bool hasConsent(ConsentType type) => consents[type] ?? false;

  /// Verifica si todos los consentimientos requeridos están otorgados
  bool get hasRequiredConsents {
    for (final type in ConsentType.values) {
      if (type.isRequired && !hasConsent(type)) {
        return false;
      }
    }
    return true;
  }

  /// Crea una copia con consentimientos actualizados
  UserConsents copyWith({
    String? userId,
    Map<ConsentType, bool>? consents,
    DateTime? lastUpdated,
    List<ConsentHistoryEntry>? history,
  }) {
    return UserConsents(
      userId: userId ?? this.userId,
      consents: consents ?? this.consents,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      history: history ?? this.history,
    );
  }

  /// Obtiene consentimientos por defecto (solo requeridos activos)
  factory UserConsents.defaultConsents(String userId) {
    final consents = <ConsentType, bool>{};
    for (final type in ConsentType.values) {
      consents[type] = type.isRequired;
    }
    return UserConsents(
      userId: userId,
      consents: consents,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, consents, lastUpdated, history];
}

/// Entrada del historial de cambios de consentimiento
class ConsentHistoryEntry extends Equatable {
  final DateTime timestamp;
  final String action;
  final ConsentType? consentType;
  final Map<ConsentType, bool>? consents;
  final String? ipAddress;
  final String? userAgent;

  const ConsentHistoryEntry({
    required this.timestamp,
    required this.action,
    this.consentType,
    this.consents,
    this.ipAddress,
    this.userAgent,
  });

  @override
  List<Object?> get props => [timestamp, action, consentType, consents, ipAddress, userAgent];
}
