import 'package:equatable/equatable.dart';

abstract class BankEvent extends Equatable {
  const BankEvent();

  @override
  List<Object?> get props => [];
}

/// Load list of available institutions for the selector sheet
class LoadInstitutions extends BankEvent {
  const LoadInstitutions();
}

/// User selected an institution → initiate OAuth
class ConnectBankRequested extends BankEvent {
  final String institutionId;
  const ConnectBankRequested(this.institutionId);

  @override
  List<Object?> get props => [institutionId];
}

/// Timer tick — poll /banks/:id/sync-status
class PollSyncStatus extends BankEvent {
  final String connectionId;
  final int attempt;
  const PollSyncStatus(this.connectionId, this.attempt);

  @override
  List<Object?> get props => [connectionId, attempt];
}

/// Load all linked bank accounts for AccountsPage
class LoadBankAccounts extends BankEvent {
  const LoadBankAccounts();
}

/// User manually triggered sync for a connection
class SyncBankRequested extends BankEvent {
  final String connectionId;
  const SyncBankRequested(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

/// User disconnected a bank
class DisconnectBankRequested extends BankEvent {
  final String connectionId;
  const DisconnectBankRequested(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

/// User closed BankConnectingPage — cancel polling timer
class CancelBankPolling extends BankEvent {
  const CancelBankPolling();
}
