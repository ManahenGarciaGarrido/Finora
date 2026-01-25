import 'package:equatable/equatable.dart';

/// Entidad que representa la política de privacidad
class PrivacyPolicy extends Equatable {
  final String version;
  final DateTime lastUpdated;
  final DateTime effectiveDate;
  final String language;
  final DataController controller;
  final List<PrivacySection> sections;

  const PrivacyPolicy({
    required this.version,
    required this.lastUpdated,
    required this.effectiveDate,
    required this.language,
    required this.controller,
    required this.sections,
  });

  @override
  List<Object?> get props => [
        version,
        lastUpdated,
        effectiveDate,
        language,
        controller,
        sections,
      ];
}

/// Controlador de datos
class DataController extends Equatable {
  final String name;
  final String address;
  final String email;
  final DPOInfo dpo;

  const DataController({
    required this.name,
    required this.address,
    required this.email,
    required this.dpo,
  });

  @override
  List<Object?> get props => [name, address, email, dpo];
}

/// Información del Data Protection Officer (DPO)
class DPOInfo extends Equatable {
  final String role;
  final String email;
  final List<String> responsibilities;
  final String contactInstructions;

  const DPOInfo({
    required this.role,
    required this.email,
    required this.responsibilities,
    required this.contactInstructions,
  });

  @override
  List<Object?> get props => [role, email, responsibilities, contactInstructions];
}

/// Sección de la política de privacidad
class PrivacySection extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<String>? items;

  const PrivacySection({
    required this.id,
    required this.title,
    required this.content,
    this.items,
  });

  @override
  List<Object?> get props => [id, title, content, items];
}

/// Información sobre el procesamiento de datos
class DataProcessingInfo extends Equatable {
  final DataController controller;
  final List<DataPurpose> purposes;
  final DataMinimization dataMinimization;
  final ThirdPartyInfo thirdParties;
  final InternationalTransferInfo internationalTransfers;
  final AutomatedDecisionInfo automatedDecisions;

  const DataProcessingInfo({
    required this.controller,
    required this.purposes,
    required this.dataMinimization,
    required this.thirdParties,
    required this.internationalTransfers,
    required this.automatedDecisions,
  });

  @override
  List<Object?> get props => [
        controller,
        purposes,
        dataMinimization,
        thirdParties,
        internationalTransfers,
        automatedDecisions,
      ];
}

/// Propósito del procesamiento de datos
class DataPurpose extends Equatable {
  final String purpose;
  final String description;
  final String legalBasis;
  final List<String> dataCategories;
  final String retention;

  const DataPurpose({
    required this.purpose,
    required this.description,
    required this.legalBasis,
    required this.dataCategories,
    required this.retention,
  });

  @override
  List<Object?> get props => [purpose, description, legalBasis, dataCategories, retention];
}

/// Información sobre minimización de datos
class DataMinimization extends Equatable {
  final String principle;
  final List<String> practices;

  const DataMinimization({
    required this.principle,
    required this.practices,
  });

  @override
  List<Object?> get props => [principle, practices];
}

/// Información sobre terceros
class ThirdPartyInfo extends Equatable {
  final List<String> current;
  final String note;

  const ThirdPartyInfo({
    required this.current,
    required this.note,
  });

  @override
  List<Object?> get props => [current, note];
}

/// Información sobre transferencias internacionales
class InternationalTransferInfo extends Equatable {
  final String status;
  final String safeguards;

  const InternationalTransferInfo({
    required this.status,
    required this.safeguards,
  });

  @override
  List<Object?> get props => [status, safeguards];
}

/// Información sobre decisiones automatizadas
class AutomatedDecisionInfo extends Equatable {
  final String status;
  final String note;

  const AutomatedDecisionInfo({
    required this.status,
    required this.note,
  });

  @override
  List<Object?> get props => [status, note];
}
