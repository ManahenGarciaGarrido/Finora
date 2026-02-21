import 'package:equatable/equatable.dart';

/// Status of an Open Banking connection (RF-10)
enum BankConnectionStatus { pending, linked, failed, disconnected }

extension BankConnectionStatusX on BankConnectionStatus {
  static BankConnectionStatus fromString(String s) {
    switch (s) {
      case 'linked':
        return BankConnectionStatus.linked;
      case 'failed':
        return BankConnectionStatus.failed;
      case 'disconnected':
        return BankConnectionStatus.disconnected;
      default:
        return BankConnectionStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case BankConnectionStatus.pending:
        return 'pending';
      case BankConnectionStatus.linked:
        return 'linked';
      case BankConnectionStatus.failed:
        return 'failed';
      case BankConnectionStatus.disconnected:
        return 'disconnected';
    }
  }
}

/// Represents a GoCardless requisition / bank connection (RF-10)
class BankConnectionEntity extends Equatable {
  final String id;
  final String? institutionId;
  final String? institutionName;
  final String? institutionLogo;
  final String? authUrl;
  final BankConnectionStatus status;
  final DateTime? linkedAt;
  final DateTime? lastSyncAt;

  const BankConnectionEntity({
    required this.id,
    this.institutionId,
    this.institutionName,
    this.institutionLogo,
    this.authUrl,
    required this.status,
    this.linkedAt,
    this.lastSyncAt,
  });

  @override
  List<Object?> get props => [id, institutionId, status];
}
