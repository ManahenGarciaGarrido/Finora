import 'package:equatable/equatable.dart';
import '../../domain/entities/bank_institution_entity.dart';
import '../../domain/entities/bank_account_entity.dart';
import '../../domain/entities/bank_card_entity.dart';
import '../../domain/entities/pending_bank_account_entity.dart';

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

/// Sandbox mode: cuentas recuperadas de Plaid, esperando selección del usuario
class BankPendingAccountsReady extends BankState {
  final String connectionId;
  final String institutionName;
  final List<PendingBankAccountEntity> pendingAccounts;
  final bool isImporting;

  const BankPendingAccountsReady({
    required this.connectionId,
    required this.institutionName,
    required this.pendingAccounts,
    this.isImporting = false,
  });

  @override
  List<Object?> get props => [connectionId, pendingAccounts, isImporting];
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

// ============================================================
// ACCOUNT SETUP (mock mode setup page)
// ============================================================

/// Mock connect returned a pending connection — navigate to setup page
class BankConnectPendingSetup extends BankState {
  final String connectionId;
  final String institutionName;
  final String? institutionLogo;
  const BankConnectPendingSetup({
    required this.connectionId,
    required this.institutionName,
    this.institutionLogo,
  });

  @override
  List<Object?> get props => [connectionId, institutionName];
}

class BankAccountSetupInProgress extends BankState {
  const BankAccountSetupInProgress();
}

class BankAccountSetupSuccess extends BankState {
  final BankAccountEntity account;
  const BankAccountSetupSuccess(this.account);

  @override
  List<Object?> get props => [account];
}

class BankAccountSetupFailure extends BankState {
  final String message;
  const BankAccountSetupFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// BANK CARDS
// ============================================================

class BankCardsLoaded extends BankState {
  final List<BankCardEntity> cards;
  const BankCardsLoaded(this.cards);

  @override
  List<Object?> get props => [cards];
}

class BankCardAdding extends BankState {
  const BankCardAdding();
}

class BankCardAdded extends BankState {
  final BankCardEntity card;
  const BankCardAdded(this.card);

  @override
  List<Object?> get props => [card];
}

class BankCardAddFailure extends BankState {
  final String message;
  const BankCardAddFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BankCardDeleting extends BankState {
  const BankCardDeleting();
}

class BankCardDeleted extends BankState {
  final String cardId;
  const BankCardDeleted(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

class BankCardDeleteFailure extends BankState {
  final String message;
  const BankCardDeleteFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================
// BANK TRANSACTION IMPORT (RF-11)
// ============================================================

/// Importando transacciones desde Salt Edge
class BankImportInProgress extends BankState {
  const BankImportInProgress();
}

/// Importación completada — incluye contador de nuevas operaciones
class BankImportSuccess extends BankState {
  final int imported;
  final int skipped;
  final DateTime? lastSyncAt;
  /// Cuentas actualizadas tras la importación
  final List<BankAccountEntity> accounts;

  const BankImportSuccess({
    required this.imported,
    required this.skipped,
    this.lastSyncAt,
    required this.accounts,
  });

  @override
  List<Object?> get props => [imported, skipped, lastSyncAt, accounts];
}

/// Token de Salt Edge expirado — requiere re-autenticación
class BankTokenExpired extends BankState {
  final String connectionId;
  const BankTokenExpired(this.connectionId);

  @override
  List<Object?> get props => [connectionId];
}

// ============================================================
// CSV IMPORT
// ============================================================

class BankCsvImportInProgress extends BankState {
  const BankCsvImportInProgress();
}

class BankCsvImportSuccess extends BankState {
  final int imported;
  final int skipped;
  const BankCsvImportSuccess({required this.imported, required this.skipped});

  @override
  List<Object?> get props => [imported, skipped];
}

class BankCsvImportFailure extends BankState {
  final String message;
  const BankCsvImportFailure(this.message);

  @override
  List<Object?> get props => [message];
}
