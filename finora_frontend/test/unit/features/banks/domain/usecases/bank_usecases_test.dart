import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_institution_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_account_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_card_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_sync_status_entity.dart';
import 'package:finora_frontend/features/banks/domain/entities/bank_connection_entity.dart';
import 'package:finora_frontend/features/banks/domain/repositories/bank_repository.dart';
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

@GenerateMocks([BankRepository])
import 'bank_usecases_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helper factory functions
// ---------------------------------------------------------------------------

BankAccountEntity makeAccount({
  String id = 'acc-1',
  String connectionId = 'conn-1',
}) => BankAccountEntity(
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
    BankInstitutionEntity(id: id, name: 'Test Bank', countries: const ['ES']);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  late MockBankRepository mockRepository;

  setUp(() {
    mockRepository = MockBankRepository();
  });

  // ── GetInstitutionsUseCase ──────────────────────────────────────────────────

  group('GetInstitutionsUseCase', () {
    late GetInstitutionsUseCase useCase;
    setUp(() => useCase = GetInstitutionsUseCase(mockRepository));

    test('returns list of institutions from repository', () async {
      final institutions = [makeInstitution(), makeInstitution(id: 'inst-2')];
      when(
        mockRepository.getInstitutions(country: anyNamed('country')),
      ).thenAnswer((_) async => institutions);

      final result = await useCase(country: 'ES');

      expect(result, institutions);
      verify(mockRepository.getInstitutions(country: 'ES')).called(1);
    });

    test('returns empty list when no institutions found', () async {
      when(
        mockRepository.getInstitutions(country: anyNamed('country')),
      ).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('uses default country ES when no country specified', () async {
      when(
        mockRepository.getInstitutions(country: anyNamed('country')),
      ).thenAnswer((_) async => []);

      await useCase();

      verify(mockRepository.getInstitutions(country: 'ES')).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.getInstitutions(country: anyNamed('country')),
      ).thenThrow(Exception('Network error'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── ConnectBankUseCase ──────────────────────────────────────────────────────

  group('ConnectBankUseCase', () {
    late ConnectBankUseCase useCase;
    setUp(() => useCase = ConnectBankUseCase(mockRepository));

    test('returns result map with connectionId and authUrl', () async {
      final result = <String, dynamic>{
        'connectionId': 'conn-1',
        'authUrl': 'https://auth.bank.com',
        'institutionName': 'Test Bank',
        'isMock': 'false',
      };
      when(mockRepository.connectBank(any)).thenAnswer((_) async => result);

      final response = await useCase('inst-1');

      expect(response, result);
      verify(mockRepository.connectBank('inst-1')).called(1);
    });

    test('returns mock map when isMock is true', () async {
      final result = <String, dynamic>{
        'connectionId': 'conn-mock',
        'authUrl': '',
        'isMock': 'true',
      };
      when(mockRepository.connectBank(any)).thenAnswer((_) async => result);

      final response = await useCase('inst-mock');

      expect(response['isMock'], 'true');
      expect(response['authUrl'], '');
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.connectBank(any),
      ).thenThrow(Exception('Connect failed'));

      expect(() => useCase('inst-1'), throwsException);
    });
  });

  // ── GetBankAccountsUseCase ──────────────────────────────────────────────────

  group('GetBankAccountsUseCase', () {
    late GetBankAccountsUseCase useCase;
    setUp(() => useCase = GetBankAccountsUseCase(mockRepository));

    test('returns list of accounts from repository', () async {
      final accounts = [
        makeAccount(),
        makeAccount(id: 'acc-2', connectionId: 'conn-2'),
      ];
      when(mockRepository.getBankAccounts()).thenAnswer((_) async => accounts);

      final result = await useCase();

      expect(result, accounts);
      verify(mockRepository.getBankAccounts()).called(1);
    });

    test('returns empty list when no accounts linked', () async {
      when(mockRepository.getBankAccounts()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.getBankAccounts(),
      ).thenThrow(Exception('Fetch failed'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── GetSyncStatusUseCase ────────────────────────────────────────────────────

  group('GetSyncStatusUseCase', () {
    late GetSyncStatusUseCase useCase;
    setUp(() => useCase = GetSyncStatusUseCase(mockRepository));

    test('returns BankSyncStatusEntity with linked status', () async {
      final statusEntity = BankSyncStatusEntity(
        status: BankConnectionStatus.linked,
        institutionName: 'Test Bank',
        accounts: [makeAccount()],
      );
      when(
        mockRepository.getSyncStatus(any),
      ).thenAnswer((_) async => statusEntity);

      final result = await useCase('conn-1');

      expect(result.status, BankConnectionStatus.linked);
      expect(result.institutionName, 'Test Bank');
      verify(mockRepository.getSyncStatus('conn-1')).called(1);
    });

    test('returns BankSyncStatusEntity with pending status', () async {
      final statusEntity = BankSyncStatusEntity(
        status: BankConnectionStatus.pending,
      );
      when(
        mockRepository.getSyncStatus(any),
      ).thenAnswer((_) async => statusEntity);

      final result = await useCase('conn-1');

      expect(result.status, BankConnectionStatus.pending);
    });

    test('returns BankSyncStatusEntity with failed status', () async {
      final statusEntity = BankSyncStatusEntity(
        status: BankConnectionStatus.failed,
      );
      when(
        mockRepository.getSyncStatus(any),
      ).thenAnswer((_) async => statusEntity);

      final result = await useCase('conn-1');

      expect(result.status, BankConnectionStatus.failed);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.getSyncStatus(any),
      ).thenThrow(Exception('Status unavailable'));

      expect(() => useCase('conn-1'), throwsException);
    });
  });

  // ── SyncBankUseCase ─────────────────────────────────────────────────────────

  group('SyncBankUseCase', () {
    late SyncBankUseCase useCase;
    setUp(() => useCase = SyncBankUseCase(mockRepository));

    test('returns updated accounts after sync', () async {
      final accounts = [makeAccount()];
      when(mockRepository.syncBank(any)).thenAnswer((_) async => accounts);

      final result = await useCase('conn-1');

      expect(result, accounts);
      verify(mockRepository.syncBank('conn-1')).called(1);
    });

    test('propagates exception from repository', () async {
      when(mockRepository.syncBank(any)).thenThrow(Exception('Sync failed'));

      expect(() => useCase('conn-1'), throwsException);
    });
  });

  // ── DisconnectBankUseCase ───────────────────────────────────────────────────

  group('DisconnectBankUseCase', () {
    late DisconnectBankUseCase useCase;
    setUp(() => useCase = DisconnectBankUseCase(mockRepository));

    test('calls repository disconnectBank with correct connectionId', () async {
      when(mockRepository.disconnectBank(any)).thenAnswer((_) async {
        return;
      });

      await useCase('conn-1');

      verify(mockRepository.disconnectBank('conn-1')).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.disconnectBank(any),
      ).thenThrow(Exception('Disconnect failed'));

      expect(() => useCase('conn-1'), throwsException);
    });
  });

  // ── SetupBankAccountUseCase ─────────────────────────────────────────────────

  group('SetupBankAccountUseCase', () {
    late SetupBankAccountUseCase useCase;
    setUp(() => useCase = SetupBankAccountUseCase(mockRepository));

    test('returns created BankAccountEntity on success', () async {
      final account = makeAccount();
      when(
        mockRepository.setupBankAccount(
          connectionId: anyNamed('connectionId'),
          accountName: anyNamed('accountName'),
          accountType: anyNamed('accountType'),
          iban: anyNamed('iban'),
          balanceCents: anyNamed('balanceCents'),
        ),
      ).thenAnswer((_) async => account);

      final result = await useCase(
        connectionId: 'conn-1',
        accountName: 'My Account',
        accountType: 'current',
        iban: 'ES9121000418450200051332',
        balanceCents: 50000,
      );

      expect(result, account);
      verify(
        mockRepository.setupBankAccount(
          connectionId: 'conn-1',
          accountName: 'My Account',
          accountType: 'current',
          iban: 'ES9121000418450200051332',
          balanceCents: 50000,
        ),
      ).called(1);
    });

    test('uses default balanceCents=0 when not provided', () async {
      final account = makeAccount();
      when(
        mockRepository.setupBankAccount(
          connectionId: anyNamed('connectionId'),
          accountName: anyNamed('accountName'),
          accountType: anyNamed('accountType'),
          iban: anyNamed('iban'),
          balanceCents: anyNamed('balanceCents'),
        ),
      ).thenAnswer((_) async => account);

      await useCase(
        connectionId: 'conn-1',
        accountName: 'My Account',
        accountType: 'current',
      );

      verify(
        mockRepository.setupBankAccount(
          connectionId: 'conn-1',
          accountName: 'My Account',
          accountType: 'current',
          iban: null,
          balanceCents: 0,
        ),
      ).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.setupBankAccount(
          connectionId: anyNamed('connectionId'),
          accountName: anyNamed('accountName'),
          accountType: anyNamed('accountType'),
          iban: anyNamed('iban'),
          balanceCents: anyNamed('balanceCents'),
        ),
      ).thenThrow(Exception('Setup failed'));

      expect(
        () => useCase(
          connectionId: 'conn-1',
          accountName: 'My Account',
          accountType: 'current',
        ),
        throwsException,
      );
    });
  });

  // ── GetBankCardsUseCase ─────────────────────────────────────────────────────

  group('GetBankCardsUseCase', () {
    late GetBankCardsUseCase useCase;
    setUp(() => useCase = GetBankCardsUseCase(mockRepository));

    test('returns list of cards from repository', () async {
      final cards = [makeCard(), makeCard(id: 'card-2')];
      when(mockRepository.getBankCards()).thenAnswer((_) async => cards);

      final result = await useCase();

      expect(result, cards);
      verify(mockRepository.getBankCards()).called(1);
    });

    test('returns empty list when no cards', () async {
      when(mockRepository.getBankCards()).thenAnswer((_) async => []);

      final result = await useCase();

      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.getBankCards(),
      ).thenThrow(Exception('Cards unavailable'));

      expect(() => useCase(), throwsException);
    });
  });

  // ── AddBankCardUseCase ──────────────────────────────────────────────────────

  group('AddBankCardUseCase', () {
    late AddBankCardUseCase useCase;
    setUp(() => useCase = AddBankCardUseCase(mockRepository));

    test('returns created BankCardEntity on success', () async {
      final card = makeCard();
      when(
        mockRepository.addBankCard(
          bankAccountId: anyNamed('bankAccountId'),
          cardName: anyNamed('cardName'),
          cardType: anyNamed('cardType'),
          lastFour: anyNamed('lastFour'),
        ),
      ).thenAnswer((_) async => card);

      final result = await useCase(
        bankAccountId: 'acc-1',
        cardName: 'My Visa',
        cardType: 'debit',
        lastFour: '1234',
      );

      expect(result, card);
      verify(
        mockRepository.addBankCard(
          bankAccountId: 'acc-1',
          cardName: 'My Visa',
          cardType: 'debit',
          lastFour: '1234',
        ),
      ).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.addBankCard(
          bankAccountId: anyNamed('bankAccountId'),
          cardName: anyNamed('cardName'),
          cardType: anyNamed('cardType'),
          lastFour: anyNamed('lastFour'),
        ),
      ).thenThrow(Exception('Card add failed'));

      expect(
        () => useCase(
          bankAccountId: 'acc-1',
          cardName: 'My Visa',
          cardType: 'debit',
        ),
        throwsException,
      );
    });
  });

  // ── DeleteBankCardUseCase ───────────────────────────────────────────────────

  group('DeleteBankCardUseCase', () {
    late DeleteBankCardUseCase useCase;
    setUp(() => useCase = DeleteBankCardUseCase(mockRepository));

    test('calls repository deleteBankCard with correct cardId', () async {
      when(mockRepository.deleteBankCard(any)).thenAnswer((_) async {
        return;
      });

      await useCase('card-1');

      verify(mockRepository.deleteBankCard('card-1')).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.deleteBankCard(any),
      ).thenThrow(Exception('Card not found'));

      expect(() => useCase('card-99'), throwsException);
    });
  });

  // ── ImportCsvUseCase ────────────────────────────────────────────────────────

  group('ImportCsvUseCase', () {
    late ImportCsvUseCase useCase;
    setUp(() => useCase = ImportCsvUseCase(mockRepository));

    final csvRows = [
      {'date': '2026-01-01', 'amount': '-50.00', 'concept': 'Coffee'},
    ];

    test('returns import count map on success', () async {
      when(
        mockRepository.importCsvTransactions(
          bankAccountId: anyNamed('bankAccountId'),
          rows: anyNamed('rows'),
        ),
      ).thenAnswer((_) async => {'imported': 1, 'skipped': 0});

      final result = await useCase(bankAccountId: 'acc-1', rows: csvRows);

      expect(result['imported'], 1);
      expect(result['skipped'], 0);
      verify(
        mockRepository.importCsvTransactions(
          bankAccountId: 'acc-1',
          rows: csvRows,
        ),
      ).called(1);
    });

    test('returns map with skipped count for duplicates', () async {
      when(
        mockRepository.importCsvTransactions(
          bankAccountId: anyNamed('bankAccountId'),
          rows: anyNamed('rows'),
        ),
      ).thenAnswer((_) async => {'imported': 0, 'skipped': 1});

      final result = await useCase(bankAccountId: 'acc-1', rows: csvRows);

      expect(result['skipped'], 1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.importCsvTransactions(
          bankAccountId: anyNamed('bankAccountId'),
          rows: anyNamed('rows'),
        ),
      ).thenThrow(Exception('Invalid CSV'));

      expect(
        () => useCase(bankAccountId: 'acc-1', rows: csvRows),
        throwsException,
      );
    });
  });

  // ── ImportBankTransactionsUseCase ───────────────────────────────────────────

  group('ImportBankTransactionsUseCase', () {
    late ImportBankTransactionsUseCase useCase;
    setUp(() => useCase = ImportBankTransactionsUseCase(mockRepository));

    test('returns result map with imported/skipped/last_sync_at', () async {
      final resultMap = <String, dynamic>{
        'imported': 15,
        'skipped': 3,
        'last_sync_at': '2026-04-09T10:00:00Z',
        'duration_ms': 450,
      };
      when(
        mockRepository.importBankTransactions(
          any,
          fromDate: anyNamed('fromDate'),
        ),
      ).thenAnswer((_) async => resultMap);

      final result = await useCase('conn-1');

      expect(result['imported'], 15);
      expect(result['skipped'], 3);
      expect(result['last_sync_at'], '2026-04-09T10:00:00Z');
      verify(
        mockRepository.importBankTransactions('conn-1', fromDate: null),
      ).called(1);
    });

    test('passes optional fromDate to repository', () async {
      when(
        mockRepository.importBankTransactions(
          any,
          fromDate: anyNamed('fromDate'),
        ),
      ).thenAnswer((_) async => {'imported': 5, 'skipped': 0});

      await useCase('conn-1', fromDate: '2026-01-01');

      verify(
        mockRepository.importBankTransactions('conn-1', fromDate: '2026-01-01'),
      ).called(1);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.importBankTransactions(
          any,
          fromDate: anyNamed('fromDate'),
        ),
      ).thenThrow(Exception('Import failed'));

      expect(() => useCase('conn-1'), throwsException);
    });
  });

  // ── ExchangePublicTokenUseCase ──────────────────────────────────────────────

  group('ExchangePublicTokenUseCase', () {
    late ExchangePublicTokenUseCase useCase;
    setUp(() => useCase = ExchangePublicTokenUseCase(mockRepository));

    test(
      'calls repository exchangePublicToken with all required params',
      () async {
        when(
          mockRepository.exchangePublicToken(
            connectionId: anyNamed('connectionId'),
            publicToken: anyNamed('publicToken'),
            institutionName: anyNamed('institutionName'),
          ),
        ).thenAnswer((_) async {
          return;
        });

        await useCase(
          connectionId: 'conn-1',
          publicToken: 'public-token-sandbox-abc',
          institutionName: 'Test Bank',
        );

        verify(
          mockRepository.exchangePublicToken(
            connectionId: 'conn-1',
            publicToken: 'public-token-sandbox-abc',
            institutionName: 'Test Bank',
          ),
        ).called(1);
      },
    );

    test('propagates exception from repository', () async {
      when(
        mockRepository.exchangePublicToken(
          connectionId: anyNamed('connectionId'),
          publicToken: anyNamed('publicToken'),
          institutionName: anyNamed('institutionName'),
        ),
      ).thenThrow(Exception('Token exchange failed'));

      expect(
        () => useCase(
          connectionId: 'conn-1',
          publicToken: 'bad-token',
          institutionName: 'Test Bank',
        ),
        throwsException,
      );
    });
  });

  // ── ImportSelectedAccountsUseCase ───────────────────────────────────────────

  group('ImportSelectedAccountsUseCase', () {
    late ImportSelectedAccountsUseCase useCase;
    setUp(() => useCase = ImportSelectedAccountsUseCase(mockRepository));

    test('returns imported accounts from repository', () async {
      final accounts = [
        makeAccount(),
        makeAccount(id: 'acc-2', connectionId: 'conn-1'),
      ];
      when(
        mockRepository.importSelectedBankAccounts(
          connectionId: anyNamed('connectionId'),
          selectedAccountIds: anyNamed('selectedAccountIds'),
        ),
      ).thenAnswer((_) async => accounts);

      final result = await useCase(
        connectionId: 'conn-sandbox',
        selectedAccountIds: ['ext-1', 'ext-2'],
      );

      expect(result, accounts);
      verify(
        mockRepository.importSelectedBankAccounts(
          connectionId: 'conn-sandbox',
          selectedAccountIds: ['ext-1', 'ext-2'],
        ),
      ).called(1);
    });

    test('returns empty list when no accounts selected', () async {
      when(
        mockRepository.importSelectedBankAccounts(
          connectionId: anyNamed('connectionId'),
          selectedAccountIds: anyNamed('selectedAccountIds'),
        ),
      ).thenAnswer((_) async => []);

      final result = await useCase(
        connectionId: 'conn-sandbox',
        selectedAccountIds: [],
      );

      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      when(
        mockRepository.importSelectedBankAccounts(
          connectionId: anyNamed('connectionId'),
          selectedAccountIds: anyNamed('selectedAccountIds'),
        ),
      ).thenThrow(Exception('Import failed'));

      expect(
        () => useCase(
          connectionId: 'conn-sandbox',
          selectedAccountIds: ['ext-1'],
        ),
        throwsException,
      );
    });
  });
}

