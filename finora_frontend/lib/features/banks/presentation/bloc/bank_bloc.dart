import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bank_connection_entity.dart';
import '../../domain/usecases/get_institutions_usecase.dart';
import '../../domain/usecases/connect_bank_usecase.dart';
import '../../domain/usecases/get_bank_accounts_usecase.dart';
import '../../domain/usecases/get_sync_status_usecase.dart';
import '../../domain/usecases/sync_bank_usecase.dart';
import '../../domain/usecases/disconnect_bank_usecase.dart';
import '../../domain/usecases/setup_bank_account_usecase.dart';
import '../../domain/usecases/get_bank_cards_usecase.dart';
import '../../domain/usecases/add_bank_card_usecase.dart';
import '../../domain/usecases/delete_bank_card_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/usecases/import_csv_usecase.dart';
import '../../domain/usecases/import_bank_transactions_usecase.dart';
import '../../domain/usecases/exchange_public_token_usecase.dart';
import '../../domain/usecases/import_selected_accounts_usecase.dart';
import '../../domain/entities/pending_bank_account_entity.dart';
import 'bank_event.dart';
import 'bank_state.dart';

/// BLoC for Open Banking (RF-10)
class BankBloc extends Bloc<BankEvent, BankState> {
  final GetInstitutionsUseCase getInstitutions;
  final ConnectBankUseCase connectBank;
  final GetBankAccountsUseCase getBankAccounts;
  final GetSyncStatusUseCase getSyncStatus;
  final SyncBankUseCase syncBank;
  final DisconnectBankUseCase disconnectBank;
  final SetupBankAccountUseCase setupBankAccount;
  final GetBankCardsUseCase getBankCards;
  final AddBankCardUseCase addBankCard;
  final DeleteBankCardUseCase deleteBankCard;
  final ImportCsvUseCase importCsv;
  final ImportBankTransactionsUseCase importBankTransactions;
  final ExchangePublicTokenUseCase exchangePublicToken;
  final ImportSelectedAccountsUseCase importSelectedAccounts;

  Timer? _pollingTimer;
  Timer? _periodicSyncTimer;
  static const int _maxPollAttempts = 60;
  static const Duration _pollInterval = Duration(seconds: 3);
  // RF-11: sincronización automática cada 6 horas mientras la app está abierta
  static const Duration _periodicSyncInterval = Duration(hours: 6);

  BankBloc({
    required this.getInstitutions,
    required this.connectBank,
    required this.getBankAccounts,
    required this.getSyncStatus,
    required this.syncBank,
    required this.disconnectBank,
    required this.setupBankAccount,
    required this.getBankCards,
    required this.addBankCard,
    required this.deleteBankCard,
    required this.importCsv,
    required this.importBankTransactions,
    required this.exchangePublicToken,
    required this.importSelectedAccounts,
  }) : super(const BankInitial()) {
    on<LoadInstitutions>(_onLoadInstitutions);
    on<ConnectBankRequested>(_onConnectBankRequested);
    on<ConfirmBankAccountSelection>(_onConfirmBankAccountSelection);
    on<PollSyncStatus>(_onPollSyncStatus);
    on<ExchangePublicToken>(_onExchangePublicToken);
    on<LoadBankAccounts>(_onLoadBankAccounts);
    on<SyncBankRequested>(_onSyncBankRequested);
    on<DisconnectBankRequested>(_onDisconnectBankRequested);
    on<CancelBankPolling>(_onCancelBankPolling);
    on<SetupBankAccountRequested>(_onSetupBankAccountRequested);
    on<LoadBankCards>(_onLoadBankCards);
    on<AddBankCardRequested>(_onAddBankCardRequested);
    on<DeleteBankCardRequested>(_onDeleteBankCardRequested);
    on<ImportCsvRequested>(_onImportCsvRequested);
    // RF-11
    on<ImportBankTransactionsRequested>(_onImportBankTransactions);
    on<CheckPeriodicSyncRequested>(_onCheckPeriodicSync);

    // RF-11: iniciar timer de sincronización periódica
    _startPeriodicSyncTimer();
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _periodicSyncTimer?.cancel();
    return super.close();
  }

  // ─── RF-11: Timer de sincronización periódica ──────────────────────────
  void _startPeriodicSyncTimer() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(_periodicSyncInterval, (_) {
      if (!isClosed) add(const CheckPeriodicSyncRequested());
    });
  }

  /// RF-11: Comprobar si han pasado 6 h desde la última sync y, si es así,
  /// disparar importación para todas las cuentas vinculadas.
  Future<void> _onCheckPeriodicSync(
    CheckPeriodicSyncRequested event,
    Emitter<BankState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt('last_bank_import_ms');
      final now = DateTime.now().millisecondsSinceEpoch;
      final sixHoursMs = _periodicSyncInterval.inMilliseconds;

      if (lastMs == null || (now - lastMs) >= sixHoursMs) {
        if (!isClosed) add(const ImportBankTransactionsRequested());
      }
    } catch (_) {
      // No bloquear si SharedPreferences falla
    }
  }

  /// RF-11: Importar transacciones bancarias desde Salt Edge.
  ///
  /// Si [event.connectionId] es null, importa para TODAS las conexiones
  /// obtenidas del estado actual o cargándolas primero.
  Future<void> _onImportBankTransactions(
    ImportBankTransactionsRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankImportInProgress());
    try {
      // Obtener lista de cuentas para extraer connectionIds únicos
      final accounts = await getBankAccounts();

      final connectionIds = event.connectionId != null
          ? [event.connectionId!]
          : accounts.map((a) => a.connectionId).toSet().toList();

      if (connectionIds.isEmpty) {
        emit(BankAccountsLoaded(accounts));
        return;
      }

      int totalImported = 0;
      int totalSkipped = 0;
      DateTime? lastSyncAt;

      for (final connId in connectionIds) {
        try {
          final result = await importBankTransactions(connId);
          totalImported += (result['imported'] as int?) ?? 0;
          totalSkipped += (result['skipped'] as int?) ?? 0;
          if (result['last_sync_at'] != null) {
            lastSyncAt = DateTime.tryParse(result['last_sync_at'] as String);
          }
        } catch (e) {
          // RF-11: Manejo de token expirado — la cuenta requiere re-autenticación
          final msg = e.toString().toLowerCase();
          if (msg.contains('401') ||
              msg.contains('unauthorized') ||
              msg.contains('token')) {
            emit(BankTokenExpired(connId));
            return;
          }
          // Otros errores: continuar con las demás conexiones
        }
      }

      // Guardar timestamp de última importación
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'last_bank_import_ms',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Recargar cuentas con saldos actualizados
      final updatedAccounts = await getBankAccounts();

      emit(
        BankImportSuccess(
          imported: totalImported,
          skipped: totalSkipped,
          lastSyncAt: lastSyncAt ?? DateTime.now(),
          accounts: updatedAccounts,
        ),
      );
    } catch (e) {
      // Volver al estado de cuentas cargadas sin bloquear la UI
      try {
        final accounts = await getBankAccounts();
        emit(BankAccountsLoaded(accounts));
      } catch (_) {
        emit(BankAccountsError(e.toString()));
      }
    }
  }

  Future<void> _onLoadInstitutions(
    LoadInstitutions event,
    Emitter<BankState> emit,
  ) async {
    emit(const InstitutionsLoading());
    try {
      final institutions = await getInstitutions(country: 'ES');
      emit(InstitutionsLoaded(institutions));
    } catch (e) {
      // RNF-16: Mensaje informativo según el tipo de error
      emit(InstitutionsError(_humanReadableError(e)));
    }
  }

  /// RNF-16: Convierte excepciones técnicas en mensajes comprensibles para el usuario.
  static String _humanReadableError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains('timeout') || msg.contains('timed out')) {
      return 'La conexión tardó demasiado. Comprueba tu conexión a Internet e inténtalo de nuevo.';
    }
    if (msg.contains('connection') ||
        msg.contains('socket') ||
        msg.contains('network') ||
        msg.contains('unreachable') ||
        msg.contains('refused')) {
      return 'Sin conexión a Internet. Verifica tu red y vuelve a intentarlo.';
    }
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Tu sesión ha expirado. Vuelve a iniciar sesión.';
    }
    if (msg.contains('503') ||
        msg.contains('service unavailable') ||
        msg.contains('circuit')) {
      return 'El servicio bancario no está disponible temporalmente. Inténtalo en unos minutos.';
    }
    if (msg.contains('500') || msg.contains('server error')) {
      return 'Error en el servidor. Inténtalo de nuevo más tarde.';
    }
    return 'No se pudo completar la operación. Comprueba tu conexión e inténtalo de nuevo.';
  }

  Future<void> _onConnectBankRequested(
    ConnectBankRequested event,
    Emitter<BankState> emit,
  ) async {
    try {
      final result = await connectBank(event.institutionId);
      final connectionId = result['connectionId'] as String;
      final authUrl = result['authUrl'] as String? ?? '';
      final institutionName =
          result['institutionName'] as String? ?? event.institutionId;
      final isMock = result['isMock'] == 'true';
      final pendingAccounts =
          result['pendingAccounts'] as List<PendingBankAccountEntity>? ?? [];

      if (authUrl.isEmpty) {
        if (isMock) {
          // Mock mode: setup manual de cuenta
          emit(
            BankConnectPendingSetup(
              connectionId: connectionId,
              institutionName: institutionName,
            ),
          );
        } else {
          // Sandbox mode: mostrar pantalla de selección de cuentas
          emit(
            BankPendingAccountsReady(
              connectionId: connectionId,
              institutionName: institutionName,
              pendingAccounts: pendingAccounts,
            ),
          );
        }
        return;
      }

      // Flujo OAuth completo (producción futura)
      emit(
        BankConnectAuthUrlReady(
          connectionId: connectionId,
          authUrl: authUrl,
          institutionName: institutionName,
        ),
      );
      _startPolling(connectionId);
    } catch (e) {
      // RNF-16: Mensaje informativo con sugerencia de acción
      emit(BankConnectFailure(_humanReadableError(e)));
    }
  }

  /// Usuario confirmó qué cuentas vincular en la pantalla de selección.
  Future<void> _onConfirmBankAccountSelection(
    ConfirmBankAccountSelection event,
    Emitter<BankState> emit,
  ) async {
    // Mostrar spinner en la misma página de selección
    if (state is BankPendingAccountsReady) {
      final s = state as BankPendingAccountsReady;
      emit(
        BankPendingAccountsReady(
          connectionId: s.connectionId,
          institutionName: s.institutionName,
          pendingAccounts: s.pendingAccounts,
          isImporting: true,
        ),
      );
    }
    try {
      final accounts = await importSelectedAccounts(
        connectionId: event.connectionId,
        selectedAccountIds: event.selectedAccountIds,
      );
      emit(BankConnectSuccess(accounts));
    } catch (e) {
      emit(BankConnectFailure(e.toString()));
    }
  }

  /// RF-10: El WebView capturó el public_token vía canal JS y Flutter hace
  /// el intercambio con su propio cliente HTTP (que sí llega al backend).
  Future<void> _onExchangePublicToken(
    ExchangePublicToken event,
    Emitter<BankState> emit,
  ) async {
    try {
      await exchangePublicToken(
        connectionId: event.connectionId,
        publicToken: event.publicToken,
        institutionName: event.institutionName,
      );
      // Intercambio exitoso: la conexión ya está linked en el backend.
      _pollingTimer?.cancel();
      final accounts = await getBankAccounts();
      emit(BankConnectSuccess(accounts));
    } catch (e) {
      emit(BankConnectFailure('Error al conectar: $e'));
    }
  }

  void _startPolling(String connectionId) {
    _pollingTimer?.cancel();
    int attempt = 0;
    _pollingTimer = Timer.periodic(_pollInterval, (timer) {
      attempt++;
      if (!isClosed) {
        add(PollSyncStatus(connectionId, attempt));
      }
      if (attempt >= _maxPollAttempts) {
        timer.cancel();
      }
    });
  }

  Future<void> _onPollSyncStatus(
    PollSyncStatus event,
    Emitter<BankState> emit,
  ) async {
    if (event.attempt >= _maxPollAttempts) {
      _pollingTimer?.cancel();
      emit(
        const BankConnectFailure(
          'Tiempo de espera agotado. Por favor, inténtalo de nuevo.',
        ),
      );
      return;
    }

    try {
      final syncStatus = await getSyncStatus(event.connectionId);
      if (syncStatus.status == BankConnectionStatus.linked) {
        _pollingTimer?.cancel();
        final accounts = await getBankAccounts();
        emit(BankConnectSuccess(accounts));
      } else if (syncStatus.status == BankConnectionStatus.failed) {
        _pollingTimer?.cancel();
        emit(
          const BankConnectFailure(
            'Error al conectar el banco. Por favor, inténtalo de nuevo.',
          ),
        );
      } else {
        final currentState = state;
        final institutionName = currentState is BankConnectAuthUrlReady
            ? currentState.institutionName
            : currentState is BankConnectPolling
            ? currentState.institutionName
            : 'tu banco';
        emit(
          BankConnectPolling(
            connectionId: event.connectionId,
            institutionName: institutionName,
            attempt: event.attempt,
          ),
        );
      }
    } catch (_) {
      // Network error during poll — silently continue
    }
  }

  Future<void> _onCancelBankPolling(
    CancelBankPolling event,
    Emitter<BankState> emit,
  ) async {
    _pollingTimer?.cancel();
    emit(const BankInitial());
  }

  Future<void> _onLoadBankAccounts(
    LoadBankAccounts event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankAccountsLoading());
    try {
      final accounts = await getBankAccounts();
      emit(BankAccountsLoaded(accounts));
    } catch (e) {
      emit(BankAccountsError(e.toString()));
    }
  }

  Future<void> _onSyncBankRequested(
    SyncBankRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankSyncing());
    try {
      await syncBank(event.connectionId);
      final accounts = await getBankAccounts();
      emit(BankAccountsLoaded(accounts));
    } catch (e) {
      emit(BankAccountsError(e.toString()));
    }
  }

  Future<void> _onDisconnectBankRequested(
    DisconnectBankRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankDisconnecting());
    try {
      await disconnectBank(event.connectionId);
      final accounts = await getBankAccounts();
      emit(BankAccountsLoaded(accounts));
    } catch (e) {
      emit(BankAccountsError(e.toString()));
    }
  }

  Future<void> _onSetupBankAccountRequested(
    SetupBankAccountRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankAccountSetupInProgress());
    try {
      final account = await setupBankAccount(
        connectionId: event.connectionId,
        accountName: event.accountName,
        accountType: event.accountType,
        iban: event.iban,
        balanceCents: event.balanceCents,
      );
      emit(BankAccountSetupSuccess(account));
    } catch (e) {
      emit(BankAccountSetupFailure(e.toString()));
    }
  }

  Future<void> _onLoadBankCards(
    LoadBankCards event,
    Emitter<BankState> emit,
  ) async {
    try {
      final cards = await getBankCards();
      emit(BankCardsLoaded(cards));
    } catch (_) {
      // Non-critical
    }
  }

  Future<void> _onAddBankCardRequested(
    AddBankCardRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankCardAdding());
    try {
      final card = await addBankCard(
        bankAccountId: event.bankAccountId,
        cardName: event.cardName,
        cardType: event.cardType,
        lastFour: event.lastFour,
      );
      emit(BankCardAdded(card));
    } catch (e) {
      emit(BankCardAddFailure(e.toString()));
    }
  }

  Future<void> _onDeleteBankCardRequested(
    DeleteBankCardRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankCardDeleting());
    try {
      await deleteBankCard(event.cardId);
      emit(BankCardDeleted(event.cardId));
    } catch (e) {
      emit(BankCardDeleteFailure(e.toString()));
    }
  }

  Future<void> _onImportCsvRequested(
    ImportCsvRequested event,
    Emitter<BankState> emit,
  ) async {
    emit(const BankCsvImportInProgress());
    try {
      final result = await importCsv(
        bankAccountId: event.bankAccountId,
        rows: event.rows,
      );
      emit(
        BankCsvImportSuccess(
          imported: result['imported'] ?? 0,
          skipped: result['skipped'] ?? 0,
        ),
      );
    } catch (e) {
      emit(BankCsvImportFailure(e.toString()));
    }
  }
}
