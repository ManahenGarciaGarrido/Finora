import '../../domain/entities/user_data_export.dart';
import 'consent_model.dart';

/// Modelo para la exportación de datos del usuario
class UserDataExportModel extends UserDataExport {
  const UserDataExportModel({
    required super.metadata,
    required super.personalData,
    required super.consents,
    required super.financialData,
    required super.activityLog,
    required super.dataProcessingInfo,
  });

  factory UserDataExportModel.fromJson(Map<String, dynamic> json) {
    return UserDataExportModel(
      metadata: ExportMetadataModel.fromJson(
        json['exportMetadata'] as Map<String, dynamic>,
      ),
      personalData: PersonalDataModel.fromJson(
        json['personalData'] as Map<String, dynamic>,
      ),
      consents: UserConsentsModel.fromJson(
        json['consents'] as Map<String, dynamic>,
      ),
      financialData: FinancialDataExportModel.fromJson(
        json['financialData'] as Map<String, dynamic>,
      ),
      activityLog: (json['activityLog'] as List<dynamic>? ?? [])
          .map((e) => ActivityLogEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      dataProcessingInfo: DataProcessingExportInfoModel.fromJson(
        json['dataProcessingInfo'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exportMetadata': (metadata as ExportMetadataModel).toJson(),
      'personalData': (personalData as PersonalDataModel).toJson(),
      'consents': (consents as UserConsentsModel).toJson(),
      'financialData': (financialData as FinancialDataExportModel).toJson(),
      'activityLog': activityLog
          .map((e) => (e as ActivityLogEntryModel).toJson())
          .toList(),
      'dataProcessingInfo':
          (dataProcessingInfo as DataProcessingExportInfoModel).toJson(),
    };
  }
}

/// Modelo para metadatos de exportación
class ExportMetadataModel extends ExportMetadata {
  const ExportMetadataModel({
    required super.exportDate,
    required super.format,
    required super.gdprArticle,
    required super.requestedBy,
  });

  factory ExportMetadataModel.fromJson(Map<String, dynamic> json) {
    return ExportMetadataModel(
      exportDate: DateTime.parse(json['exportDate'] as String),
      format: json['format'] as String,
      gdprArticle: json['gdprArticle'] as String,
      requestedBy: json['requestedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exportDate': exportDate.toIso8601String(),
      'format': format,
      'gdprArticle': gdprArticle,
      'requestedBy': requestedBy,
    };
  }
}

/// Modelo para datos personales
class PersonalDataModel extends PersonalData {
  const PersonalDataModel({
    required super.userId,
    required super.email,
    required super.name,
    super.phoneNumber,
    required super.registrationDate,
    super.lastLoginDate,
  });

  factory PersonalDataModel.fromJson(Map<String, dynamic> json) {
    return PersonalDataModel(
      userId: json['userId'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'] as String)
          : DateTime.now(),
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'registrationDate': registrationDate.toIso8601String(),
      if (lastLoginDate != null)
        'lastLoginDate': lastLoginDate!.toIso8601String(),
    };
  }
}

/// Modelo para datos financieros exportados
class FinancialDataExportModel extends FinancialDataExport {
  const FinancialDataExportModel({
    super.transactions,
    super.bankAccounts,
    super.savingsGoals,
    super.budgets,
  });

  factory FinancialDataExportModel.fromJson(Map<String, dynamic> json) {
    return FinancialDataExportModel(
      transactions: (json['transactions'] as List<dynamic>? ?? [])
          .map(
            (e) => TransactionExportModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      bankAccounts: (json['bankAccounts'] as List<dynamic>? ?? [])
          .map(
            (e) => BankAccountExportModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      savingsGoals: (json['savingsGoals'] as List<dynamic>? ?? [])
          .map(
            (e) => SavingsGoalExportModel.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      budgets: (json['budgets'] as List<dynamic>? ?? [])
          .map((e) => BudgetExportModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions
          .map((e) => (e as TransactionExportModel).toJson())
          .toList(),
      'bankAccounts': bankAccounts
          .map((e) => (e as BankAccountExportModel).toJson())
          .toList(),
      'savingsGoals': savingsGoals
          .map((e) => (e as SavingsGoalExportModel).toJson())
          .toList(),
      'budgets': budgets.map((e) => (e as BudgetExportModel).toJson()).toList(),
    };
  }
}

/// Modelo para transacción exportada
class TransactionExportModel extends TransactionExport {
  const TransactionExportModel({
    required super.id,
    required super.amount,
    required super.category,
    super.description,
    required super.date,
    required super.type,
  });

  factory TransactionExportModel.fromJson(Map<String, dynamic> json) {
    return TransactionExportModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      if (description != null) 'description': description,
      'date': date.toIso8601String(),
      'type': type,
    };
  }
}

/// Modelo para cuenta bancaria exportada
class BankAccountExportModel extends BankAccountExport {
  const BankAccountExportModel({
    required super.id,
    required super.bankName,
    required super.accountType,
    required super.connectedDate,
    super.lastSyncDate,
  });

  factory BankAccountExportModel.fromJson(Map<String, dynamic> json) {
    return BankAccountExportModel(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountType: json['accountType'] as String,
      connectedDate: DateTime.parse(json['connectedDate'] as String),
      lastSyncDate: json['lastSyncDate'] != null
          ? DateTime.parse(json['lastSyncDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bankName': bankName,
      'accountType': accountType,
      'connectedDate': connectedDate.toIso8601String(),
      if (lastSyncDate != null) 'lastSyncDate': lastSyncDate!.toIso8601String(),
    };
  }
}

/// Modelo para objetivo de ahorro exportado
class SavingsGoalExportModel extends SavingsGoalExport {
  const SavingsGoalExportModel({
    required super.id,
    required super.name,
    required super.targetAmount,
    required super.currentAmount,
    super.targetDate,
    required super.createdDate,
  });

  factory SavingsGoalExportModel.fromJson(Map<String, dynamic> json) {
    return SavingsGoalExportModel(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      currentAmount: (json['currentAmount'] as num).toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'] as String)
          : null,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

/// Modelo para presupuesto exportado
class BudgetExportModel extends BudgetExport {
  const BudgetExportModel({
    required super.id,
    required super.category,
    required super.limit,
    required super.spent,
    required super.period,
    required super.startDate,
  });

  factory BudgetExportModel.fromJson(Map<String, dynamic> json) {
    return BudgetExportModel(
      id: json['id'] as String,
      category: json['category'] as String,
      limit: (json['limit'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      period: json['period'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'limit': limit,
      'spent': spent,
      'period': period,
      'startDate': startDate.toIso8601String(),
    };
  }
}

/// Modelo para entrada del log de actividad
class ActivityLogEntryModel extends ActivityLogEntry {
  const ActivityLogEntryModel({
    required super.id,
    required super.timestamp,
    required super.eventType,
    required super.action,
    super.ipAddress,
    super.statusCode,
  });

  factory ActivityLogEntryModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogEntryModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      eventType: json['eventType'] as String,
      action: json['action'] as String,
      ipAddress: json['ipAddress'] as String?,
      statusCode: json['statusCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'action': action,
      if (ipAddress != null) 'ipAddress': ipAddress,
      if (statusCode != null) 'statusCode': statusCode,
    };
  }
}

/// Modelo para información de procesamiento de datos de exportación
class DataProcessingExportInfoModel extends DataProcessingExportInfo {
  const DataProcessingExportInfoModel({
    required super.purposes,
    required super.legalBasis,
    required super.recipients,
    required super.retentionPeriod,
  });

  factory DataProcessingExportInfoModel.fromJson(Map<String, dynamic> json) {
    return DataProcessingExportInfoModel(
      purposes: (json['purposes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      legalBasis: json['legalBasis'] as String,
      recipients: (json['recipients'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      retentionPeriod: json['retentionPeriod'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'purposes': purposes,
      'legalBasis': legalBasis,
      'recipients': recipients,
      'retentionPeriod': retentionPeriod,
    };
  }
}

/// Modelo para recibo de eliminación de cuenta
class AccountDeletionReceiptModel extends AccountDeletionReceipt {
  const AccountDeletionReceiptModel({
    required super.receiptId,
    required super.userId,
    required super.deletionDate,
    required super.dataDeleted,
    required super.retainedForLegal,
    required super.gdprCompliance,
  });

  factory AccountDeletionReceiptModel.fromJson(Map<String, dynamic> json) {
    return AccountDeletionReceiptModel(
      receiptId: json['receiptId'] as String,
      userId: json['userId'] as String,
      deletionDate: DateTime.parse(json['deletionDate'] as String),
      dataDeleted: (json['dataDeleted'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      retainedForLegal: (json['retainedForLegal'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      gdprCompliance: GDPRComplianceInfoModel.fromJson(
        json['gdprCompliance'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiptId': receiptId,
      'userId': userId,
      'deletionDate': deletionDate.toIso8601String(),
      'dataDeleted': dataDeleted,
      'retainedForLegal': retainedForLegal,
      'gdprCompliance': (gdprCompliance as GDPRComplianceInfoModel).toJson(),
    };
  }
}

/// Modelo para información de cumplimiento GDPR
class GDPRComplianceInfoModel extends GDPRComplianceInfo {
  const GDPRComplianceInfoModel({
    required super.article,
    required super.processingTime,
    required super.backupDeletion,
  });

  factory GDPRComplianceInfoModel.fromJson(Map<String, dynamic> json) {
    return GDPRComplianceInfoModel(
      article: json['article'] as String,
      processingTime: json['processingTime'] as String,
      backupDeletion: json['backupDeletion'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article': article,
      'processingTime': processingTime,
      'backupDeletion': backupDeletion,
    };
  }
}
