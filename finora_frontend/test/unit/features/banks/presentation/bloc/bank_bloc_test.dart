import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_institution_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_card_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_sync_status_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_connection_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/pending_bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_institutions_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/connect_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_bank_accounts_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_sync_status_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/sync_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/disconnect_bank_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/setup_bank_account_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/get_bank_cards_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/add_bank_card_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/delete_bank_card_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/import_csv_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/import_bank_transactions_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/exchange_public_token_usecase.dart';
import 'package:finora_frontend/features/banks/domain/usecases/import_selected_accounts_usecase.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_bloc.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_event.dart';
import 'package:finora_frontend/features/banks/presentation/bloc/bank_state.dart';

@GenerateMocks([
  GetInstitutionsUseCase,
  ConnectBankUseCase,
  GetBankAccountsUseCase,
  GetSyncStatusUseCase,
  SyncBankUseCase,
  DisconnectBankUseCase,
  SetupBankAccountUseCase,
  GetBankCardsUseCase,
  AddBankCardUseCase,
  DeleteBankCardUseCase,
  ImportCsvUseCase,
  ImportBankTransactionsUseCase,
  ExchangePublicTokenUseCase,
  ImportSelectedAccountsUseCase,
])
import 'bank_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helper factory functions
// ---------------------------------------------------------------------------

BankAccountEntity makeAccount({
  String id = 'acc-1',
  String connectionId = 'conn-1',
}) =>
    BankAccountEntity(
      id: id,
      connectionId: connectionId,
      accountName: 'Test Account',
      accountType: 'current',
      currency: 'EUR',
      balanceCents: 100000,
    );

BankCardEntity makeCard({String id = 'card-1'}) => BankCardEntity(
      id: id,
      bankAccountId: 'acc-1',
      userId: 'user-1',
      cardName: 'My Visa',
      cardType: 'debit',
      lastFour: '1234',
    );

BankInstitutionEntity makeInstitution({String id = 'inst-1'}) =>
    BankInstitutionEntity(
      id: id,
      name: 'Test Bank',
      countries: const ['ES'],
    );

BankSyncStatusEntity makeSyncStatus(BankConnectionStatus status) =>
    BankSyncStatusEntity(status: status);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BankBloc bloc;
  late MockGetInstitutionsUseCase mockGetInstitutions;
  late MockConnectBankUseCase mockConnectBank;
  late MockGetBankAccountsUseCase mockGetBankAccounts;
  late MockGetSyncStatusUseCase mockGetSyncStatus;
  late MockSyncBankUseCase mockSyncBank;
  late MockDisconnectBankUseCase mockDisconnectBank;
  late MockSetupBankAccountUseCase mockSetupBankAccount;
  late MockGetBankCardsUseCase mockGetBankCards;
  late MockAddBankCardUseCase mockAddBankCard;
  late MockDeleteBankCardUseCase mockDeleteBankCard;
  late MockImportCsvUseCase mockImportCsv;
  late MockImportBankTransactionsUseCase mockImportBankTransactions;
  late MockExchangePublicTokenUseCase mockExchangePublicToken;
  late MockImportSelectedAccountsUseCase mockImportSelectedAccounts;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockGetInstitutions = MockGetInstitutionsUseCase();
    mockConnectBank = MockConnectBankUseCase();
    mockGetBankAccounts = MockGetBankAccountsUseCase();
    mockGetSyncStatus = MockGetSyncStatusUseCase();
    mockSyncBank = MockSyncBankUseCase();
    mockDisconnectBank = MockDisconnectBankUseCase();
    mockSetupBankAccount = MockSetupBankAccountUseCase();
    mockGetBankCards = MockGetBankCardsUseCase();
    mockAddBankCard = MockAddBankCardUseCase();
    mockDeleteBankCard = MockDeleteBankCardUseCase();
    mockImportCsv = MockImportCsvUseCase();
    mockImportBankTransactions = MockImportBankTransactionsUseCase();
    mockExchangePublicToken = MockExchangePublicTokenUseCase();
    mockImportSelectedAccounts = MockImportSelectedAccountsUseCase();

    bloc = BankBloc(
      getInstitutions: mockGetInstitutions,
      connectBank: mockConnectBank,
      getBankAccounts: mockGetBankAccounts,
      getSyncStatus: mockGetSyncStatus,
      syncBank: mockSyncBank,
      disconnectBank: mockDisconnectBank,
      setupBankAccount: mockSetupBankAccount,
      getBankCards: mockGetBankCards,
      addBankCard: mockAddBankCard,
      deleteBankCard: mockDeleteBankCard,
      importCsv: mockImportCsv,
      importBankTransactions: mockImportBankTransactions,
      exchangePublicToken: mockExchangePublicToken,
      importSelectedAccounts: mockImportSelectedAccounts,
    );
  });

  tearDown(() => bloc.close());

  test('initial state is BankInitial', () {
    expect(bloc.state, const BankInitial());
  });

  // ── LoadInstitutions ────────────────────────────────────────────────────────

  group('LoadInstitutions', () {
    final institutions = [makeInstitution(), makeInstitution(id: 'inst-2')];

    blocTest<BankBloc, BankState>(
      'emits [InstitutionsLoading, InstitutionsLoaded] on success',
      build: () {
        when(mockGetInstitutions(country: anyNamed('country')))
            .thenAnswer((_) async => institutions);
        return bloc;
      },
      act: (b) => b.add(const LoadInstitutions()),
      expect: () => [
        const InstitutionsLoading(),
        InstitutionsLoaded(institutions),
      ],
      verify: (_) {
        verify(mockGetInstitutions(country: 'ES')).called(1);
      },
    );

    blocTest<BankBloc, BankState>(
      'emits [InstitutionsLoading, InstitutionsLoaded] with empty list',
      build: () {
        when(mockGetInstitutions(country: anyNamed('country')))
            .thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadInstitutions()),
      expect: () => [
        const InstitutionsLoading(),
        const InstitutionsLoaded([]),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits [InstitutionsLoading, InstitutionsError] on exception',
      build: () {
        when(mockGetInstitutions(country: anyNamed('country')))
            .thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const LoadInstitutions()),
      expect: () => [
        const InstitutionsLoading(),
        isA<InstitutionsError>(),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits timeout-friendly message when timeout error',
      build: () {
        when(mockGetInstitutions(country: anyNamed('country')))
            .thenThrow(Exception('timeout'));
        return bloc;
      },
      act: (b) => b.add(const LoadInstitutions()),
      expect: () => [
        const InstitutionsLoading(),
        isA<InstitutionsError>().having(
          (s) => s.message,
          'message',
          contains('conexión'),
        ),
      ],
    );
  });

  // ── ConnectBankRequested ────────────────────────────────────────────────────

  group('ConnectBankRequested', () {
    blocTest<BankBloc, BankState>(
      'emits BankConnectAuthUrlReady when authUrl is non-empty',
      build: () {
        when(mockConnectBank(any)).thenAnswer(
          (_) async => {
            'connectionId': 'conn-1',
            'authUrl': 'https://auth.bank.com',
            'institutionName': 'Test Bank',
            'isMock': 'false',
          },
        );
        return bloc;
      },
      act: (b) => b.add(const ConnectBankRequested('inst-1')),
      expect: () => [
        isA<BankConnectAuthUrlReady>()
            .having((s) => s.connectionId, 'connectionId', 'conn-1')
            .having((s) => s.authUrl, 'authUrl', 'https://auth.bank.com'),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectPendingSetup when authUrl is empty and isMock=true',
      build: () {
        when(mockConnectBank(any)).thenAnswer(
          (_) async => {
            'connectionId': 'conn-1',
            'authUrl': '',
            'institutionName': 'Mock Bank',
            'isMock': 'true',
          },
        );
        return bloc;
      },
      act: (b) => b.add(const ConnectBankRequested('inst-mock')),
      expect: () => [
        isA<BankConnectPendingSetup>()
            .having((s) => s.connectionId, 'connectionId', 'conn-1'),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankPendingAccountsReady when authUrl is empty and isMock=false',
      build: () {
        when(mockConnectBank(any)).thenAnswer(
          (_) async => {
            'connectionId': 'conn-sandbox',
            'authUrl': '',
            'institutionName': 'Sandbox Bank',
            'isMock': 'false',
            'pendingAccounts': <PendingBankAccountEntity>[],
          },
        );
        return bloc;
      },
      act: (b) => b.add(const ConnectBankRequested('inst-sandbox')),
      expect: () => [
        isA<BankPendingAccountsReady>()
            .having((s) => s.connectionId, 'connectionId', 'conn-sandbox'),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure on exception',
      build: () {
        when(mockConnectBank(any)).thenThrow(Exception('Server error'));
        return bloc;
      },
      act: (b) => b.add(const ConnectBankRequested('inst-1')),
      expect: () => [isA<BankConnectFailure>()],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure with sessionExpired type on 401',
      build: () {
        when(mockConnectBank(any)).thenThrow(Exception('401 unauthorized'));
        return bloc;
      },
      act: (b) => b.add(const ConnectBankRequested('inst-1')),
      expect: () => [
        isA<BankConnectFailure>().having(
          (s) => s.errorType,
          'errorType',
          BankConnectErrorType.sessionExpired,
        ),
      ],
    );
  });

  // ── LoadBankAccounts ────────────────────────────────────────────────────────

  group('LoadBankAccounts', () {
    final accounts = [makeAccount(), makeAccount(id: 'acc-2', connectionId: 'conn-2')];

    blocTest<BankBloc, BankState>(
      'emits [BankAccountsLoading, BankAccountsLoaded] on success',
      build: () {
        when(mockGetBankAccounts()).thenAnswer((_) async => accounts);
        return bloc;
      },
      act: (b) => b.add(const LoadBankAccounts()),
      expect: () => [
        const BankAccountsLoading(),
        BankAccountsLoaded(accounts),
      ],
      verify: (_) => verify(mockGetBankAccounts()).called(1),
    );

    blocTest<BankBloc, BankState>(
      'emits [BankAccountsLoading, BankAccountsLoaded] with empty list',
      build: () {
        when(mockGetBankAccounts()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadBankAccounts()),
      expect: () => [
        const BankAccountsLoading(),
        const BankAccountsLoaded([]),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits [BankAccountsLoading, BankAccountsError] on exception',
      build: () {
        when(mockGetBankAccounts()).thenThrow(Exception('Fetch failed'));
        return bloc;
      },
      act: (b) => b.add(const LoadBankAccounts()),
      expect: () => [
        const BankAccountsLoading(),
        isA<BankAccountsError>(),
      ],
    );
  });

  // ── SyncBankRequested ───────────────────────────────────────────────────────

  group('SyncBankRequested', () {
    final updatedAccounts = [makeAccount()];

    blocTest<BankBloc, BankState>(
      'emits [BankSyncing, BankAccountsLoaded] on success',
      build: () {
        when(mockSyncBank(any)).thenAnswer((_) async => updatedAccounts);
        when(mockGetBankAccounts()).thenAnswer((_) async => updatedAccounts);
        return bloc;
      },
      act: (b) => b.add(const SyncBankRequested('conn-1')),
      expect: () => [
        const BankSyncing(),
        BankAccountsLoaded(updatedAccounts),
      ],
      verify: (_) {
        verify(mockSyncBank('conn-1')).called(1);
        verify(mockGetBankAccounts()).called(1);
      },
    );

    blocTest<BankBloc, BankState>(
      'emits [BankSyncing, BankAccountsError] on exception',
      build: () {
        when(mockSyncBank(any)).thenThrow(Exception('Sync failed'));
        return bloc;
      },
      act: (b) => b.add(const SyncBankRequested('conn-1')),
      expect: () => [
        const BankSyncing(),
        isA<BankAccountsError>(),
      ],
    );
  });

  // ── DisconnectBankRequested ─────────────────────────────────────────────────

  group('DisconnectBankRequested', () {
    final remainingAccounts = [makeAccount(id: 'acc-2', connectionId: 'conn-2')];

    blocTest<BankBloc, BankState>(
      'emits [BankDisconnecting, BankDisconnected, BankAccountsLoaded] on success',
      build: () {
        when(mockDisconnectBank(any)).thenAnswer((_) async {});
        when(mockGetBankAccounts()).thenAnswer((_) async => remainingAccounts);
        return bloc;
      },
      act: (b) => b.add(const DisconnectBankRequested('conn-1', accountName: 'Test Account')),
      expect: () => [
        const BankDisconnecting(),
        isA<BankDisconnected>().having((s) => s.accountName, 'accountName', 'Test Account'),
        BankAccountsLoaded(remainingAccounts),
      ],
      verify: (_) {
        verify(mockDisconnectBank('conn-1')).called(1);
        verify(mockGetBankAccounts()).called(1);
      },
    );

    blocTest<BankBloc, BankState>(
      'emits [BankDisconnecting, BankAccountsError] on exception',
      build: () {
        when(mockDisconnectBank(any)).thenThrow(Exception('Disconnect failed'));
        return bloc;
      },
      act: (b) => b.add(const DisconnectBankRequested('conn-1')),
      expect: () => [
        const BankDisconnecting(),
        isA<BankAccountsError>(),
      ],
    );
  });

  // ── CancelBankPolling ───────────────────────────────────────────────────────

  group('CancelBankPolling', () {
    blocTest<BankBloc, BankState>(
      'emits [BankInitial] on CancelBankPolling',
      build: () => bloc,
      act: (b) => b.add(const CancelBankPolling()),
      expect: () => [const BankInitial()],
    );
  });

  // ── CancelledByUser ─────────────────────────────────────────────────────────

  group('CancelledByUser', () {
    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure with cancelledByUser type',
      build: () => bloc,
      act: (b) => b.add(const CancelledByUser()),
      expect: () => [
        isA<BankConnectFailure>().having(
          (s) => s.errorType,
          'errorType',
          BankConnectErrorType.cancelledByUser,
        ),
      ],
    );
  });

  // ── LoadBankCards ───────────────────────────────────────────────────────────

  group('LoadBankCards', () {
    final cards = [makeCard(), makeCard(id: 'card-2')];

    blocTest<BankBloc, BankState>(
      'emits BankCardsLoaded on success',
      build: () {
        when(mockGetBankCards()).thenAnswer((_) async => cards);
        return bloc;
      },
      act: (b) => b.add(const LoadBankCards()),
      expect: () => [BankCardsLoaded(cards)],
      verify: (_) => verify(mockGetBankCards()).called(1),
    );

    blocTest<BankBloc, BankState>(
      'emits BankCardsLoaded with empty list',
      build: () {
        when(mockGetBankCards()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const LoadBankCards()),
      expect: () => [const BankCardsLoaded([])],
    );

    blocTest<BankBloc, BankState>(
      'emits nothing (non-critical) when getBankCards throws',
      build: () {
        when(mockGetBankCards()).thenThrow(Exception('Cards unavailable'));
        return bloc;
      },
      act: (b) => b.add(const LoadBankCards()),
      expect: () => [],
    );
  });

  // ── AddBankCardRequested ────────────────────────────────────────────────────

  group('AddBankCardRequested', () {
    final newCard = makeCard();

    blocTest<BankBloc, BankState>(
      'emits [BankCardAdding, BankCardAdded] on success',
      build: () {
        when(
          mockAddBankCard(
            bankAccountId: anyNamed('bankAccountId'),
            cardName: anyNamed('cardName'),
            cardType: anyNamed('cardType'),
            lastFour: anyNamed('lastFour'),
          ),
        ).thenAnswer((_) async => newCard);
        return bloc;
      },
      act: (b) => b.add(
        const AddBankCardRequested(
          bankAccountId: 'acc-1',
          cardName: 'My Visa',
          cardType: 'debit',
          lastFour: '1234',
        ),
      ),
      expect: () => [
        const BankCardAdding(),
        BankCardAdded(newCard),
      ],
      verify: (_) {
        verify(
          mockAddBankCard(
            bankAccountId: 'acc-1',
            cardName: 'My Visa',
            cardType: 'debit',
            lastFour: '1234',
          ),
        ).called(1);
      },
    );

    blocTest<BankBloc, BankState>(
      'emits [BankCardAdding, BankCardAddFailure] on exception',
      build: () {
        when(
          mockAddBankCard(
            bankAccountId: anyNamed('bankAccountId'),
            cardName: anyNamed('cardName'),
            cardType: anyNamed('cardType'),
            lastFour: anyNamed('lastFour'),
          ),
        ).thenThrow(Exception('Card already exists'));
        return bloc;
      },
      act: (b) => b.add(
        const AddBankCardRequested(
          bankAccountId: 'acc-1',
          cardName: 'My Visa',
          cardType: 'debit',
        ),
      ),
      expect: () => [
        const BankCardAdding(),
        isA<BankCardAddFailure>(),
      ],
    );
  });

  // ── DeleteBankCardRequested ─────────────────────────────────────────────────

  group('DeleteBankCardRequested', () {
    blocTest<BankBloc, BankState>(
      'emits [BankCardDeleting, BankCardDeleted] on success',
      build: () {
        when(mockDeleteBankCard(any)).thenAnswer((_) async {});
        return bloc;
      },
      act: (b) => b.add(const DeleteBankCardRequested('card-1')),
      expect: () => [
        const BankCardDeleting(),
        const BankCardDeleted('card-1'),
      ],
      verify: (_) => verify(mockDeleteBankCard('card-1')).called(1),
    );

    blocTest<BankBloc, BankState>(
      'emits [BankCardDeleting, BankCardDeleteFailure] on exception',
      build: () {
        when(mockDeleteBankCard(any)).thenThrow(Exception('Card not found'));
        return bloc;
      },
      act: (b) => b.add(const DeleteBankCardRequested('card-99')),
      expect: () => [
        const BankCardDeleting(),
        isA<BankCardDeleteFailure>(),
      ],
    );
  });

  // ── ImportCsvRequested ──────────────────────────────────────────────────────

  group('ImportCsvRequested', () {
    final csvRows = [
      {'date': '2026-01-01', 'amount': '-50.00', 'concept': 'Coffee'},
      {'date': '2026-01-02', 'amount': '-120.00', 'concept': 'Groceries'},
    ];

    blocTest<BankBloc, BankState>(
      'emits [BankCsvImportInProgress, BankCsvImportSuccess] on success',
      build: () {
        when(
          mockImportCsv(
            bankAccountId: anyNamed('bankAccountId'),
            rows: anyNamed('rows'),
          ),
        ).thenAnswer((_) async => {'imported': 2, 'skipped': 0});
        return bloc;
      },
      act: (b) => b.add(
        ImportCsvRequested(bankAccountId: 'acc-1', rows: csvRows),
      ),
      expect: () => [
        const BankCsvImportInProgress(),
        const BankCsvImportSuccess(imported: 2, skipped: 0),
      ],
      verify: (_) {
        verify(
          mockImportCsv(bankAccountId: 'acc-1', rows: csvRows),
        ).called(1);
      },
    );

    blocTest<BankBloc, BankState>(
      'emits [BankCsvImportInProgress, BankCsvImportSuccess] with skipped count',
      build: () {
        when(
          mockImportCsv(
            bankAccountId: anyNamed('bankAccountId'),
            rows: anyNamed('rows'),
          ),
        ).thenAnswer((_) async => {'imported': 1, 'skipped': 1});
        return bloc;
      },
      act: (b) => b.add(
        ImportCsvRequested(bankAccountId: 'acc-1', rows: csvRows),
      ),
      expect: () => [
        const BankCsvImportInProgress(),
        const BankCsvImportSuccess(imported: 1, skipped: 1),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits [BankCsvImportInProgress, BankCsvImportFailure] on exception',
      build: () {
        when(
          mockImportCsv(
            bankAccountId: anyNamed('bankAccountId'),
            rows: anyNamed('rows'),
          ),
        ).thenThrow(Exception('Invalid CSV format'));
        return bloc;
      },
      act: (b) => b.add(
        ImportCsvRequested(bankAccountId: 'acc-1', rows: csvRows),
      ),
      expect: () => [
        const BankCsvImportInProgress(),
        isA<BankCsvImportFailure>(),
      ],
    );
  });

  // ── PollSyncStatus ──────────────────────────────────────────────────────────

  group('PollSyncStatus', () {
    final accounts = [makeAccount()];

    blocTest<BankBloc, BankState>(
      'emits BankConnectSuccess when status is linked',
      build: () {
        when(mockGetSyncStatus(any)).thenAnswer(
          (_) async => makeSyncStatus(BankConnectionStatus.linked),
        );
        when(mockGetBankAccounts()).thenAnswer((_) async => accounts);
        return bloc;
      },
      act: (b) => b.add(const PollSyncStatus('conn-1', 1)),
      expect: () => [BankConnectSuccess(accounts)],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure with permissionDenied when status is failed',
      build: () {
        when(mockGetSyncStatus(any)).thenAnswer(
          (_) async => makeSyncStatus(BankConnectionStatus.failed),
        );
        return bloc;
      },
      act: (b) => b.add(const PollSyncStatus('conn-1', 1)),
      expect: () => [
        isA<BankConnectFailure>().having(
          (s) => s.errorType,
          'errorType',
          BankConnectErrorType.permissionDenied,
        ),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectPolling when status is pending',
      build: () {
        when(mockGetSyncStatus(any)).thenAnswer(
          (_) async => makeSyncStatus(BankConnectionStatus.pending),
        );
        return bloc;
      },
      act: (b) => b.add(const PollSyncStatus('conn-1', 5)),
      expect: () => [
        isA<BankConnectPolling>()
            .having((s) => s.connectionId, 'connectionId', 'conn-1')
            .having((s) => s.attempt, 'attempt', 5),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure with timeout type when attempt >= maxPollAttempts',
      build: () => bloc,
      act: (b) => b.add(const PollSyncStatus('conn-1', 60)),
      expect: () => [
        isA<BankConnectFailure>().having(
          (s) => s.errorType,
          'errorType',
          BankConnectErrorType.timeout,
        ),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits nothing (silent) when getSyncStatus throws during poll',
      build: () {
        when(mockGetSyncStatus(any)).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(const PollSyncStatus('conn-1', 3)),
      expect: () => [],
    );
  });

  // ── SetupBankAccountRequested ───────────────────────────────────────────────

  group('SetupBankAccountRequested', () {
    final account = makeAccount();

    blocTest<BankBloc, BankState>(
      'emits [BankAccountSetupInProgress, BankAccountSetupSuccess] on success',
      build: () {
        when(
          mockSetupBankAccount(
            connectionId: anyNamed('connectionId'),
            accountName: anyNamed('accountName'),
            accountType: anyNamed('accountType'),
            iban: anyNamed('iban'),
            balanceCents: anyNamed('balanceCents'),
          ),
        ).thenAnswer((_) async => account);
        return bloc;
      },
      act: (b) => b.add(
        const SetupBankAccountRequested(
          connectionId: 'conn-1',
          accountName: 'My Account',
          accountType: 'current',
          iban: 'ES9121000418450200051332',
          balanceCents: 50000,
        ),
      ),
      expect: () => [
        const BankAccountSetupInProgress(),
        BankAccountSetupSuccess(account),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits [BankAccountSetupInProgress, BankAccountSetupFailure] on exception',
      build: () {
        when(
          mockSetupBankAccount(
            connectionId: anyNamed('connectionId'),
            accountName: anyNamed('accountName'),
            accountType: anyNamed('accountType'),
            iban: anyNamed('iban'),
            balanceCents: anyNamed('balanceCents'),
          ),
        ).thenThrow(Exception('Setup failed'));
        return bloc;
      },
      act: (b) => b.add(
        const SetupBankAccountRequested(
          connectionId: 'conn-1',
          accountName: 'My Account',
          accountType: 'current',
        ),
      ),
      expect: () => [
        const BankAccountSetupInProgress(),
        isA<BankAccountSetupFailure>(),
      ],
    );
  });

  // ── ExchangePublicToken ─────────────────────────────────────────────────────

  group('ExchangePublicToken', () {
    final accounts = [makeAccount()];

    blocTest<BankBloc, BankState>(
      'emits BankConnectSuccess after successful token exchange',
      build: () {
        when(
          mockExchangePublicToken(
            connectionId: anyNamed('connectionId'),
            publicToken: anyNamed('publicToken'),
            institutionName: anyNamed('institutionName'),
          ),
        ).thenAnswer((_) async {});
        when(mockGetBankAccounts()).thenAnswer((_) async => accounts);
        return bloc;
      },
      act: (b) => b.add(
        const ExchangePublicToken(
          connectionId: 'conn-1',
          publicToken: 'public-token-sandbox-abc',
          institutionName: 'Test Bank',
        ),
      ),
      expect: () => [BankConnectSuccess(accounts)],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure when exchange throws',
      build: () {
        when(
          mockExchangePublicToken(
            connectionId: anyNamed('connectionId'),
            publicToken: anyNamed('publicToken'),
            institutionName: anyNamed('institutionName'),
          ),
        ).thenThrow(Exception('Token exchange failed'));
        return bloc;
      },
      act: (b) => b.add(
        const ExchangePublicToken(
          connectionId: 'conn-1',
          publicToken: 'bad-token',
          institutionName: 'Test Bank',
        ),
      ),
      expect: () => [isA<BankConnectFailure>()],
    );
  });

  // ── ConfirmBankAccountSelection ─────────────────────────────────────────────

  group('ConfirmBankAccountSelection', () {
    final importedAccounts = [makeAccount()];

    blocTest<BankBloc, BankState>(
      'emits BankConnectSuccess after successful account import',
      build: () {
        when(
          mockImportSelectedAccounts(
            connectionId: anyNamed('connectionId'),
            selectedAccountIds: anyNamed('selectedAccountIds'),
          ),
        ).thenAnswer((_) async => importedAccounts);
        return bloc;
      },
      act: (b) => b.add(
        const ConfirmBankAccountSelection(
          connectionId: 'conn-sandbox',
          selectedAccountIds: ['ext-acc-1', 'ext-acc-2'],
        ),
      ),
      expect: () => [BankConnectSuccess(importedAccounts)],
    );

    blocTest<BankBloc, BankState>(
      'emits BankConnectFailure when import throws',
      build: () {
        when(
          mockImportSelectedAccounts(
            connectionId: anyNamed('connectionId'),
            selectedAccountIds: anyNamed('selectedAccountIds'),
          ),
        ).thenThrow(Exception('Import failed'));
        return bloc;
      },
      act: (b) => b.add(
        const ConfirmBankAccountSelection(
          connectionId: 'conn-sandbox',
          selectedAccountIds: ['ext-acc-1'],
        ),
      ),
      expect: () => [isA<BankConnectFailure>()],
    );
  });

  // ── ImportBankTransactionsRequested ─────────────────────────────────────────

  group('ImportBankTransactionsRequested', () {
    final accountsWithConnectionId = [
      BankAccountEntity(
        id: 'acc-1',
        connectionId: 'conn-1',
        accountName: 'Checking',
        balanceCents: 200000,
      ),
    ];

    blocTest<BankBloc, BankState>(
      'emits [BankImportInProgress, BankImportSuccess] when import succeeds',
      build: () {
        when(mockGetBankAccounts()).thenAnswer(
          (_) async => accountsWithConnectionId,
        );
        when(mockImportBankTransactions(any)).thenAnswer(
          (_) async => {
            'imported': 10,
            'skipped': 2,
            'last_sync_at': '2026-04-09T10:00:00Z',
            'duration_ms': 300,
          },
        );
        return bloc;
      },
      act: (b) => b.add(const ImportBankTransactionsRequested()),
      expect: () => [
        const BankImportInProgress(),
        isA<BankImportSuccess>()
            .having((s) => s.imported, 'imported', 10)
            .having((s) => s.skipped, 'skipped', 2),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits [BankImportInProgress, BankAccountsLoaded] when no connections',
      build: () {
        when(mockGetBankAccounts()).thenAnswer((_) async => []);
        return bloc;
      },
      act: (b) => b.add(const ImportBankTransactionsRequested()),
      expect: () => [
        const BankImportInProgress(),
        const BankAccountsLoaded([]),
      ],
    );

    blocTest<BankBloc, BankState>(
      'emits BankTokenExpired when import returns 401',
      build: () {
        when(mockGetBankAccounts()).thenAnswer(
          (_) async => accountsWithConnectionId,
        );
        when(mockImportBankTransactions(any))
            .thenThrow(Exception('401 unauthorized token'));
        return bloc;
      },
      act: (b) => b.add(const ImportBankTransactionsRequested()),
      expect: () => [
        const BankImportInProgress(),
        isA<BankTokenExpired>(),
      ],
    );

    blocTest<BankBloc, BankState>(
      'imports for specific connectionId when provided',
      build: () {
        when(mockGetBankAccounts()).thenAnswer(
          (_) async => accountsWithConnectionId,
        );
        when(mockImportBankTransactions('conn-specific')).thenAnswer(
          (_) async => {
            'imported': 5,
            'skipped': 0,
            'last_sync_at': '2026-04-09T10:00:00Z',
          },
        );
        return bloc;
      },
      act: (b) => b.add(
        const ImportBankTransactionsRequested(connectionId: 'conn-specific'),
      ),
      expect: () => [
        const BankImportInProgress(),
        isA<BankImportSuccess>().having((s) => s.imported, 'imported', 5),
      ],
    );
  });
}

