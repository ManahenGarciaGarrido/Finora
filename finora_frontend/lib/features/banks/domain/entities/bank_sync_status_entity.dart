import 'package:equatable/equatable.dart';
import 'bank_account_entity.dart';
import 'bank_connection_entity.dart';

/// Returned by GET /banks/:id/sync-status (RF-10)
class BankSyncStatusEntity extends Equatable {
  final BankConnectionStatus status;
  final String? institutionName;
  final String? institutionLogo;
  final DateTime? linkedAt;
  final DateTime? lastSyncAt;
  final List<BankAccountEntity> accounts;

  const BankSyncStatusEntity({
    required this.status,
    this.institutionName,
    this.institutionLogo,
    this.linkedAt,
    this.lastSyncAt,
    this.accounts = const [],
  });

  @override
  List<Object?> get props => [status, accounts];
}
