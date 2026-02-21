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
import '../../domain/usecases/setup_bank_account_usecase.dart';
import '../../domain/usecases/get_bank_cards_usecase.dart';
import '../../domain/usecases/add_bank_card_usecase.dart';
import '../../domain/usecases/import_csv_usecase.dart';
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
  final ImportCsvUseCase importCsv;

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
    required this.setupBankAccount,
    required this.getBankCards,
    required this.addBankCard,
    required this.importCsv,
  }) : super(const BankInitial()) {
    on<LoadInstitutions>(_onLoadInstitutions);
    on<ConnectBankRequested>(_onConnectBankRequested);
    on<PollSyncStatus>(_onPollSyncStatus);
    on<LoadBankAccounts>(_onLoadBankAccounts);
    on<SyncBankRequested>(_onSyncBankRequested);
    on<DisconnectBankRequested>(_onDisconnectBankRequested);
    on<CancelBankPolling>(_onCancelBankPolling);
    on<SetupBankAccountRequested>(_onSetupBankAccountRequested);
    on<LoadBankCards>(_onLoadBankCards);
    on<AddBankCardRequested>(_onAddBankCardRequested);
    on<ImportCsvRequested>(_onImportCsvRequested);
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
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
      emit(InstitutionsError(e.toString()));
    }
  }

  Future<void> _onConnectBankRequested(
    ConnectBankRequested event,
    Emitter<BankState> emit,
  ) async {
    try {
      final result = await connectBank(event.institutionId);
      final connectionId = result['connectionId']!;
      final authUrl = result['authUrl']!;
      final institutionName = result['institutionName'] ?? event.institutionId;

      // Mock mode: navigate to setup page
      if (authUrl.isEmpty) {
        emit(BankConnectPendingSetup(
          connectionId: connectionId,
          institutionName: institutionName,
        ));
        return;
      }

      // Real mode: open browser for OAuth and start polling
      emit(BankConnectAuthUrlReady(
        connectionId: connectionId,
        authUrl: authUrl,
        institutionName: institutionName,
      ));

      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }

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
        final accounts = await getBankAccounts();
        emit(BankConnectSuccess(accounts));
      } else if (syncStatus.status == BankConnectionStatus.failed) {
        _pollingTimer?.cancel();
        emit(const BankConnectFailure('Error al conectar el banco. Por favor, inténtalo de nuevo.'));
      } else {
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
      emit(BankCsvImportSuccess(
        imported: result['imported'] ?? 0,
        skipped: result['skipped'] ?? 0,
      ));
    } catch (e) {
      emit(BankCsvImportFailure(e.toString()));
    }
  }
}
