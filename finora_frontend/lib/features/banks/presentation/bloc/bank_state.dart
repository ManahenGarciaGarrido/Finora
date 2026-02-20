import 'package:equatable/equatable.dart';
import '../../domain/entities/bank_institution_entity.dart';
import '../../domain/entities/bank_account_entity.dart';

abstract class BankState extends Equatable {
  const BankState();

  @override
  List<Object?> get props => [];
}

/// Initial state — nothing loaded yet
class BankInitial extends BankState {
  const BankInitial();
}

// ============================================================
// INSTITUTIONS (selector sheet)
// ============================================================

class InstitutionsLoading extends BankState {
  const InstitutionsLoading();
}

class InstitutionsLoaded extends BankState {
  final List<BankInstitutionEntity> institutions;
  const InstitutionsLoaded(this.institutions);

  @override
  List<Object?> get props => [institutions];
}

class InstitutionsError extends BankState {
  final String message;
  const InstitutionsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// CONNECT BANK (OAuth flow)
// ============================================================

/// OAuth URL retrieved — open browser now
class BankConnectAuthUrlReady extends BankState {
  final String connectionId;
  final String authUrl;
  final String institutionName;
  const BankConnectAuthUrlReady({
    required this.connectionId,
    required this.authUrl,
    required this.institutionName,
  });

  @override
  List<Object?> get props => [connectionId, authUrl, institutionName];
}

/// Waiting for the user to complete OAuth in browser
class BankConnectPolling extends BankState {
  final String connectionId;
  final String institutionName;
  final int attempt;
  const BankConnectPolling({
    required this.connectionId,
    required this.institutionName,
    required this.attempt,
  });

  @override
  List<Object?> get props => [connectionId, attempt];
}

/// OAuth completed — bank linked successfully
class BankConnectSuccess extends BankState {
  final List<BankAccountEntity> accounts;
  const BankConnectSuccess(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

/// OAuth failed or timed out
class BankConnectFailure extends BankState {
  final String message;
  const BankConnectFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// BANK ACCOUNTS LIST
// ============================================================

class BankAccountsLoading extends BankState {
  const BankAccountsLoading();
}

class BankAccountsLoaded extends BankState {
  final List<BankAccountEntity> accounts;
  const BankAccountsLoaded(this.accounts);

  @override
  List<Object?> get props => [accounts];
}

class BankAccountsError extends BankState {
  final String message;
  const BankAccountsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// SYNC / DISCONNECT
// ============================================================

class BankSyncing extends BankState {
  const BankSyncing();
}

class BankDisconnecting extends BankState {
  const BankDisconnecting();
}
