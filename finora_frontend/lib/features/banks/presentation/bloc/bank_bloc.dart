import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/bank_connection_entity.dart';
import '../../domain/usecases/get_institutions_usecase.dart';
import '../../domain/usecases/connect_bank_usecase.dart';
import '../../domain/usecases/get_bank_accounts_usecase.dart';
import '../../domain/usecases/get_sync_status_usecase.dart';
import '../../domain/usecases/sync_bank_usecase.dart';
import '../../domain/usecases/disconnect_bank_usecase.dart';
import 'bank_event.dart';
import 'bank_state.dart';

/// BLoC for Open Banking (RF-10)
///
/// Flow for connecting a bank:
///  1. ConnectBankRequested → calls backend → gets authUrl
///  2. Emits BankConnectAuthUrlReady → UI opens browser via url_launcher
///  3. UI dispatches PollSyncStatus every 3s (up to 60 attempts = 3 min)
///  4. When status == 'linked' → emits BankConnectSuccess
class BankBloc extends Bloc<BankEvent, BankState> {
  final GetInstitutionsUseCase getInstitutions;
  final ConnectBankUseCase connectBank;
  final GetBankAccountsUseCase getBankAccounts;
  final GetSyncStatusUseCase getSyncStatus;
  final SyncBankUseCase syncBank;
  final DisconnectBankUseCase disconnectBank;

  Timer? _pollingTimer;
  static const int _maxPollAttempts = 60;
  static const Duration _pollInterval = Duration(seconds: 3);

  BankBloc({
    required this.getInstitutions,
    required this.connectBank,
    required this.getBankAccounts,
    required this.getSyncStatus,
    required this.syncBank,
    required this.disconnectBank,
  }) : super(const BankInitial()) {
    on<LoadInstitutions>(_onLoadInstitutions);
    on<ConnectBankRequested>(_onConnectBankRequested);
    on<PollSyncStatus>(_onPollSyncStatus);
    on<LoadBankAccounts>(_onLoadBankAccounts);
    on<SyncBankRequested>(_onSyncBankRequested);
    on<DisconnectBankRequested>(_onDisconnectBankRequested);
    on<CancelBankPolling>(_onCancelBankPolling);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }

  // ──────────────────────────────────────────
  // Load institutions
  // ──────────────────────────────────────────
  Future<void> _onLoadInstitutions(
    LoadInstitutions event,
    Emitter<BankState> emit,
  ) async {
    emit(const InstitutionsLoading());
    try {
      final institutions = await getInstitutions(country: 'ES');
      emit(InstitutionsLoaded(institutions));
    } catch (e) {
      emit(InstitutionsError(e.toString()));
    }
  }

  // ──────────────────────────────────────────
  // Connect bank: get auth URL → open browser → start polling
  // ──────────────────────────────────────────
  Future<void> _onConnectBankRequested(
    ConnectBankRequested event,
    Emitter<BankState> emit,
  ) async {
    try {
      final result = await connectBank(event.institutionId);
      final connectionId = result['connectionId']!;
      final authUrl = result['authUrl']!;

      // Emit so UI can navigate to connecting page first
      emit(BankConnectAuthUrlReady(
        connectionId: connectionId,
        authUrl: authUrl,
        institutionName: event.institutionId,
      ));

      // Launch browser for OAuth
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // Start polling timer
      _startPolling(connectionId);
    } catch (e) {
      emit(BankConnectFailure(e.toString()));
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
      emit(const BankConnectFailure('Tiempo de espera agotado. Por favor, inténtalo de nuevo.'));
      return;
    }

    try {
      final syncStatus = await getSyncStatus(event.connectionId);
      if (syncStatus.status == BankConnectionStatus.linked) {
        _pollingTimer?.cancel();
        // Load accounts now
        final accounts = await getBankAccounts();
        emit(BankConnectSuccess(accounts));
      } else if (syncStatus.status == BankConnectionStatus.failed) {
        _pollingTimer?.cancel();
        emit(const BankConnectFailure('Error al conectar el banco. Por favor, inténtalo de nuevo.'));
      } else {
        // Still pending — emit polling state to update UI progress indicator
        final currentState = state;
        final institutionName = currentState is BankConnectAuthUrlReady
            ? currentState.institutionName
            : currentState is BankConnectPolling
                ? currentState.institutionName
                : 'tu banco';
        emit(BankConnectPolling(
          connectionId: event.connectionId,
          institutionName: institutionName,
          attempt: event.attempt,
        ));
      }
    } catch (_) {
      // Network error during poll — silently continue unless max attempts reached
    }
  }

  Future<void> _onCancelBankPolling(
    CancelBankPolling event,
    Emitter<BankState> emit,
  ) async {
    _pollingTimer?.cancel();
    emit(const BankInitial());
  }

  // ──────────────────────────────────────────
  // Load all linked accounts
  // ──────────────────────────────────────────
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

  // ──────────────────────────────────────────
  // Sync bank
  // ──────────────────────────────────────────
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

  // ──────────────────────────────────────────
  // Disconnect bank
  // ──────────────────────────────────────────
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
}
