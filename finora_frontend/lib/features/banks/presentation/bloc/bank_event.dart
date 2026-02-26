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

/// User selected an institution → initiate OAuth or setup flow
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

/// User confirmed setup of a new bank account
class SetupBankAccountRequested extends BankEvent {
  final String connectionId;
  final String accountName;
  final String accountType;
  final String? iban;
  final int balanceCents;

  const SetupBankAccountRequested({
    required this.connectionId,
    required this.accountName,
    required this.accountType,
    this.iban,
    this.balanceCents = 0,
  });

  @override
  List<Object?> get props => [connectionId, accountName, accountType];
}

/// Load all bank cards for the user
class LoadBankCards extends BankEvent {
  const LoadBankCards();
}

/// Add a card to a bank account
class AddBankCardRequested extends BankEvent {
  final String bankAccountId;
  final String cardName;
  final String cardType;
  final String? lastFour;

  const AddBankCardRequested({
    required this.bankAccountId,
    required this.cardName,
    required this.cardType,
    this.lastFour,
  });

  @override
  List<Object?> get props => [bankAccountId, cardName, cardType];
}

/// RF-11: Importar transacciones desde Salt Edge para una conexión bancaria
class ImportBankTransactionsRequested extends BankEvent {
  /// [connectionId] identifica la conexión. Si es null, importa todas.
  final String? connectionId;
  const ImportBankTransactionsRequested({this.connectionId});

  @override
  List<Object?> get props => [connectionId];
}

/// RF-11: Comprobar si corresponde realizar sincronización periódica
/// (se dispara al arrancar la app y al volver al tab Cuentas)
class CheckPeriodicSyncRequested extends BankEvent {
  const CheckPeriodicSyncRequested();
}

/// RF-10: Flutter recibió el public_token de Plaid Link vía canal JS.
/// Lanza el intercambio desde el cliente HTTP Dart (no desde el WebView).
class ExchangePublicToken extends BankEvent {
  final String connectionId;
  final String publicToken;
  final String institutionName;

  const ExchangePublicToken({
    required this.connectionId,
    required this.publicToken,
    required this.institutionName,
  });

  @override
  List<Object?> get props => [connectionId, publicToken];
}

/// Usuario confirmó las cuentas que quiere vincular desde la pantalla de selección
class ConfirmBankAccountSelection extends BankEvent {
  final String connectionId;
  final List<String> selectedAccountIds;

  const ConfirmBankAccountSelection({
    required this.connectionId,
    required this.selectedAccountIds,
  });

  @override
  List<Object?> get props => [connectionId, selectedAccountIds];
}

/// Delete a bank card by id
class DeleteBankCardRequested extends BankEvent {
  final String cardId;
  const DeleteBankCardRequested(this.cardId);

  @override
  List<Object?> get props => [cardId];
}

/// CU-02 FA2: El usuario canceló explícitamente el flujo de autorización
/// en la pantalla del banco (sin completar ni rechazar permisos formalmente).
class CancelledByUser extends BankEvent {
  const CancelledByUser();
}

/// Import CSV transactions for a bank account
class ImportCsvRequested extends BankEvent {
  final String bankAccountId;
  final List<Map<String, dynamic>> rows;

  const ImportCsvRequested({required this.bankAccountId, required this.rows});

  @override
  List<Object?> get props => [bankAccountId, rows.length];
}
