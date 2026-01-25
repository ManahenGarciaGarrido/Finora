import '../../domain/entities/privacy_policy.dart';

/// Modelo para serializar/deserializar la política de privacidad
class PrivacyPolicyModel extends PrivacyPolicy {
  const PrivacyPolicyModel({
    required super.version,
    required super.lastUpdated,
    required super.effectiveDate,
    required super.language,
    required super.controller,
    required super.sections,
  });

  factory PrivacyPolicyModel.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyModel(
      version: json['version'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      effectiveDate: DateTime.parse(json['effectiveDate'] as String),
      language: json['language'] as String,
      controller: DataControllerModel.fromJson(json['controller'] as Map<String, dynamic>),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => PrivacySectionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'effectiveDate': effectiveDate.toIso8601String(),
      'language': language,
      'controller': (controller as DataControllerModel).toJson(),
      'sections': sections.map((e) => (e as PrivacySectionModel).toJson()).toList(),
    };
  }
}

/// Modelo para el controlador de datos
class DataControllerModel extends DataController {
  const DataControllerModel({
    required super.name,
    required super.address,
    required super.email,
    required super.dpo,
  });

  factory DataControllerModel.fromJson(Map<String, dynamic> json) {
    return DataControllerModel(
      name: json['name'] as String,
      address: json['address'] as String,
      email: json['email'] as String,
      dpo: DPOInfoModel.fromJson(json['dpo'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'email': email,
      'dpo': (dpo as DPOInfoModel).toJson(),
    };
  }
}

/// Modelo para información del DPO
class DPOInfoModel extends DPOInfo {
  const DPOInfoModel({
    required super.role,
    required super.email,
    required super.responsibilities,
    required super.contactInstructions,
  });

  factory DPOInfoModel.fromJson(Map<String, dynamic> json) {
    return DPOInfoModel(
      role: json['role'] as String,
      email: json['email'] as String,
      responsibilities: (json['responsibilities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      contactInstructions: json['contactInstructions'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'email': email,
      'responsibilities': responsibilities,
      'contactInstructions': contactInstructions,
    };
  }
}

/// Modelo para sección de privacidad
class PrivacySectionModel extends PrivacySection {
  const PrivacySectionModel({
    required super.id,
    required super.title,
    required super.content,
    super.items,
  });

  factory PrivacySectionModel.fromJson(Map<String, dynamic> json) {
    return PrivacySectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      items: json['items'] != null
          ? (json['items'] as List<dynamic>).map((e) => e as String).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      if (items != null) 'items': items,
    };
  }
}

/// Modelo para información del procesamiento de datos
class DataProcessingInfoModel extends DataProcessingInfo {
  const DataProcessingInfoModel({
    required super.controller,
    required super.purposes,
    required super.dataMinimization,
    required super.thirdParties,
    required super.internationalTransfers,
    required super.automatedDecisions,
  });

  factory DataProcessingInfoModel.fromJson(Map<String, dynamic> json) {
    return DataProcessingInfoModel(
      controller: DataControllerModel.fromJson(json['controller'] as Map<String, dynamic>),
      purposes: (json['purposes'] as List<dynamic>)
          .map((e) => DataPurposeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dataMinimization: DataMinimizationModel.fromJson(
          json['dataMinimization'] as Map<String, dynamic>),
      thirdParties: ThirdPartyInfoModel.fromJson(json['thirdParties'] as Map<String, dynamic>),
      internationalTransfers: InternationalTransferInfoModel.fromJson(
          json['internationalTransfers'] as Map<String, dynamic>),
      automatedDecisions: AutomatedDecisionInfoModel.fromJson(
          json['automatedDecisions'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'controller': (controller as DataControllerModel).toJson(),
      'purposes': purposes.map((e) => (e as DataPurposeModel).toJson()).toList(),
      'dataMinimization': (dataMinimization as DataMinimizationModel).toJson(),
      'thirdParties': (thirdParties as ThirdPartyInfoModel).toJson(),
      'internationalTransfers': (internationalTransfers as InternationalTransferInfoModel).toJson(),
      'automatedDecisions': (automatedDecisions as AutomatedDecisionInfoModel).toJson(),
    };
  }
}

/// Modelo para propósito de datos
class DataPurposeModel extends DataPurpose {
  const DataPurposeModel({
    required super.purpose,
    required super.description,
    required super.legalBasis,
    required super.dataCategories,
    required super.retention,
  });

  factory DataPurposeModel.fromJson(Map<String, dynamic> json) {
    return DataPurposeModel(
      purpose: json['purpose'] as String,
      description: json['description'] as String,
      legalBasis: json['legalBasis'] as String,
      dataCategories: (json['dataCategories'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      retention: json['retention'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purpose': purpose,
      'description': description,
      'legalBasis': legalBasis,
      'dataCategories': dataCategories,
      'retention': retention,
    };
  }
}

/// Modelo para minimización de datos
class DataMinimizationModel extends DataMinimization {
  const DataMinimizationModel({
    required super.principle,
    required super.practices,
  });

  factory DataMinimizationModel.fromJson(Map<String, dynamic> json) {
    return DataMinimizationModel(
      principle: json['principle'] as String,
      practices: (json['practices'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'principle': principle,
      'practices': practices,
    };
  }
}

/// Modelo para información de terceros
class ThirdPartyInfoModel extends ThirdPartyInfo {
  const ThirdPartyInfoModel({
    required super.current,
    required super.note,
  });

  factory ThirdPartyInfoModel.fromJson(Map<String, dynamic> json) {
    return ThirdPartyInfoModel(
      current: (json['current'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'note': note,
    };
  }
}

/// Modelo para transferencias internacionales
class InternationalTransferInfoModel extends InternationalTransferInfo {
  const InternationalTransferInfoModel({
    required super.status,
    required super.safeguards,
  });

  factory InternationalTransferInfoModel.fromJson(Map<String, dynamic> json) {
    return InternationalTransferInfoModel(
      status: json['status'] as String,
      safeguards: json['safeguards'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'safeguards': safeguards,
    };
  }
}

/// Modelo para decisiones automatizadas
class AutomatedDecisionInfoModel extends AutomatedDecisionInfo {
  const AutomatedDecisionInfoModel({
    required super.status,
    required super.note,
  });

  factory AutomatedDecisionInfoModel.fromJson(Map<String, dynamic> json) {
    return AutomatedDecisionInfoModel(
      status: json['status'] as String,
      note: json['note'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'note': note,
    };
  }
}
