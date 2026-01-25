import 'package:equatable/equatable.dart';

import 'consent.dart';

/// Entidad que representa la exportación completa de datos del usuario
/// Según el derecho de portabilidad - Art. 20 GDPR
class UserDataExport extends Equatable {
  final ExportMetadata metadata;
  final PersonalData personalData;
  final UserConsents consents;
  final FinancialDataExport financialData;
  final List<ActivityLogEntry> activityLog;
  final DataProcessingExportInfo dataProcessingInfo;

  const UserDataExport({
    required this.metadata,
    required this.personalData,
    required this.consents,
    required this.financialData,
    required this.activityLog,
    required this.dataProcessingInfo,
  });

  @override
  List<Object?> get props => [
        metadata,
        personalData,
        consents,
        financialData,
        activityLog,
        dataProcessingInfo,
      ];
}

/// Metadatos de la exportación
class ExportMetadata extends Equatable {
  final DateTime exportDate;
  final String format;
  final String gdprArticle;
  final String requestedBy;

  const ExportMetadata({
    required this.exportDate,
    required this.format,
    required this.gdprArticle,
    required this.requestedBy,
  });

  @override
  List<Object?> get props => [exportDate, format, gdprArticle, requestedBy];
}

/// Datos personales del usuario
class PersonalData extends Equatable {
  final String userId;
  final String email;
  final String name;
  final String? phoneNumber;
  final DateTime registrationDate;
  final DateTime? lastLoginDate;

  const PersonalData({
    required this.userId,
    required this.email,
    required this.name,
    this.phoneNumber,
    required this.registrationDate,
    this.lastLoginDate,
  });

  @override
  List<Object?> get props => [
        userId,
        email,
        name,
        phoneNumber,
        registrationDate,
        lastLoginDate,
      ];
}

/// Datos financieros exportados
class FinancialDataExport extends Equatable {
  final List<TransactionExport> transactions;
  final List<BankAccountExport> bankAccounts;
  final List<SavingsGoalExport> savingsGoals;
  final List<BudgetExport> budgets;

  const FinancialDataExport({
    this.transactions = const [],
    this.bankAccounts = const [],
    this.savingsGoals = const [],
    this.budgets = const [],
  });

  @override
  List<Object?> get props => [transactions, bankAccounts, savingsGoals, budgets];
}

/// Transacción exportada
class TransactionExport extends Equatable {
  final String id;
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final String type;

  const TransactionExport({
    required this.id,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    required this.type,
  });

  @override
  List<Object?> get props => [id, amount, category, description, date, type];
}

/// Cuenta bancaria exportada
class BankAccountExport extends Equatable {
  final String id;
  final String bankName;
  final String accountType;
  final DateTime connectedDate;
  final DateTime? lastSyncDate;

  const BankAccountExport({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.connectedDate,
    this.lastSyncDate,
  });

  @override
  List<Object?> get props => [id, bankName, accountType, connectedDate, lastSyncDate];
}

/// Objetivo de ahorro exportado
class SavingsGoalExport extends Equatable {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final DateTime createdDate;

  const SavingsGoalExport({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
    required this.createdDate,
  });

  @override
  List<Object?> get props => [id, name, targetAmount, currentAmount, targetDate, createdDate];
}

/// Presupuesto exportado
class BudgetExport extends Equatable {
  final String id;
  final String category;
  final double limit;
  final double spent;
  final String period;
  final DateTime startDate;

  const BudgetExport({
    required this.id,
    required this.category,
    required this.limit,
    required this.spent,
    required this.period,
    required this.startDate,
  });

  @override
  List<Object?> get props => [id, category, limit, spent, period, startDate];
}

/// Entrada del registro de actividad
class ActivityLogEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String action;
  final String? ipAddress;
  final int? statusCode;

  const ActivityLogEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.action,
    this.ipAddress,
    this.statusCode,
  });

  @override
  List<Object?> get props => [id, timestamp, eventType, action, ipAddress, statusCode];
}

/// Información de procesamiento de datos para exportación
class DataProcessingExportInfo extends Equatable {
  final List<String> purposes;
  final String legalBasis;
  final List<String> recipients;
  final String retentionPeriod;

  const DataProcessingExportInfo({
    required this.purposes,
    required this.legalBasis,
    required this.recipients,
    required this.retentionPeriod,
  });

  @override
  List<Object?> get props => [purposes, legalBasis, recipients, retentionPeriod];
}

/// Recibo de eliminación de cuenta
/// Según el derecho al olvido - Art. 17 GDPR
class AccountDeletionReceipt extends Equatable {
  final String receiptId;
  final String userId;
  final DateTime deletionDate;
  final List<String> dataDeleted;
  final List<String> retainedForLegal;
  final GDPRComplianceInfo gdprCompliance;

  const AccountDeletionReceipt({
    required this.receiptId,
    required this.userId,
    required this.deletionDate,
    required this.dataDeleted,
    required this.retainedForLegal,
    required this.gdprCompliance,
  });

  @override
  List<Object?> get props => [
        receiptId,
        userId,
        deletionDate,
        dataDeleted,
        retainedForLegal,
        gdprCompliance,
      ];
}

/// Información de cumplimiento GDPR para eliminación
class GDPRComplianceInfo extends Equatable {
  final String article;
  final String processingTime;
  final String backupDeletion;

  const GDPRComplianceInfo({
    required this.article,
    required this.processingTime,
    required this.backupDeletion,
  });

  @override
  List<Object?> get props => [article, processingTime, backupDeletion];
}
