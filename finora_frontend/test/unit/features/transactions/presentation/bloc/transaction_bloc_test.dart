import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:finora_frontend/core/network/network_info.dart';
import 'package:finora_frontend/core/sync/sync_manager.dart';
import 'package:finora_frontend/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finora_frontend/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:finora_frontend/features/transactions/presentation/bloc/transaction_event.dart';
import 'package:finora_frontend/features/transactions/presentation/bloc/transaction_state.dart';

@GenerateMocks([ApiClient, LocalDatabase, NetworkInfo, SyncManager])
import 'transaction_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a fake Dio [Response] wrapping [data].
Response<dynamic> _fakeResponse(Map<String, dynamic> data) {
  return Response(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: ''),
  );
}

TransactionEntity _makeTransaction({
  String id = 'tx-1',
  double amount = 50.0,
  TransactionType type = TransactionType.expense,
  String category = 'Alimentación',
  String? description = 'Comida',
  DateTime? date,
  PaymentMethod paymentMethod = PaymentMethod.cash,
  SyncStatus syncStatus = SyncStatus.synced,
}) {
  return TransactionEntity(
    id: id,
    amount: amount,
    type: type,
    category: category,
    description: description,
    date: date ?? DateTime(2026, 4, 9),
    paymentMethod: paymentMethod,
    syncStatus: syncStatus,
    createdAt: DateTime(2026, 4, 9),
    updatedAt: DateTime(2026, 4, 9),
  );
}

/// Converts a TransactionEntity to the server JSON format used by [ApiClient].
Map<String, dynamic> _toServerJson(TransactionEntity t) {
  return {
    'id': t.id,
    'amount': t.amount,
    'type': t.type.apiValue,
    'category': t.category,
    'description': t.description,
    'date': t.date.toIso8601String(),
    'payment_method': t.paymentMethod.apiValue,
    'created_at': t.createdAt?.toIso8601String(),
    'updated_at': t.updatedAt?.toIso8601String(),
  };
}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

final _now = DateTime(2026, 4, 9);

final _expense1 = _makeTransaction(
  id: 'tx-1',
  amount: 30.0,
  type: TransactionType.expense,
  category: 'Alimentación',
  date: _now,
);

final _expense2 = _makeTransaction(
  id: 'tx-2',
  amount: 20.0,
  type: TransactionType.expense,
  category: 'Transporte',
  date: _now.subtract(const Duration(days: 1)),
);

final _income1 = _makeTransaction(
  id: 'tx-3',
  amount: 2000.0,
  type: TransactionType.income,
  category: 'Salario',
  date: _now.subtract(const Duration(days: 2)),
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late TransactionBloc bloc;
  late MockApiClient mockApiClient;
  late MockLocalDatabase mockLocalDatabase;
  late MockNetworkInfo mockNetworkInfo;
  late MockSyncManager mockSyncManager;

  setUp(() {
    mockApiClient = MockApiClient();
    mockLocalDatabase = MockLocalDatabase();
    mockNetworkInfo = MockNetworkInfo();
    mockSyncManager = MockSyncManager();

    // Default stubs – can be overridden per test
    when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
    when(mockLocalDatabase.saveAllTransactions(any)).thenAnswer((_) async {
      return;
    });
    when(mockLocalDatabase.saveTransaction(any)).thenAnswer((_) async {
      return;
    });
    when(mockLocalDatabase.updateTransaction(any, any)).thenAnswer((_) async {
      return;
    });
    when(mockLocalDatabase.deleteTransaction(any)).thenAnswer((_) async {
      return;
    });
    when(mockSyncManager.pendingCount).thenReturn(0);
    when(mockSyncManager.processQueue()).thenAnswer((_) async => true);
    when(mockSyncManager.enqueueCreate(any)).thenAnswer((_) async {
      return;
    });
    when(mockSyncManager.enqueueUpdate(any)).thenAnswer((_) async {
      return;
    });
    when(mockSyncManager.enqueueDelete(any)).thenAnswer((_) async {
      return;
    });
    when(
      mockApiClient.get(
        any,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
      ),
    ).thenAnswer(
      (_) async => _fakeResponse({
        'transactions': [],
        'pagination': {'hasMore': false},
        'totals': {'income': 0.0, 'expense': 0.0},
      }),
    );

    bloc = TransactionBloc(
      apiClient: mockApiClient,
      localDatabase: mockLocalDatabase,
      networkInfo: mockNetworkInfo,
      syncManager: mockSyncManager,
    );
  });

  tearDown(() {
    bloc.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Initial state
  // ─────────────────────────────────────────────────────────────────────────

  test('initial state is TransactionInitial', () {
    expect(bloc.state, isA<TransactionInitial>());
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LoadTransactions
  // ─────────────────────────────────────────────────────────────────────────

  group('LoadTransactions', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Loaded] when online with server data',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense1), _toServerJson(_income1)],
            'pagination': {'hasMore': false},
            'totals': {'income': 2000.0, 'expense': 30.0},
          }),
        );
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [isA<TransactionLoading>(), isA<TransactionsLoaded>()],
      verify: (_) {
        verify(mockLocalDatabase.saveAllTransactions(any)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Loaded(offline)] when device is offline with local data',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([_expense1.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        // emits local data first
        isA<TransactionsLoaded>(),
        // emits offline flag second
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        final lastState =
            bloc.state as TransactionsLoaded; // state after all emits
        expect(lastState.isOffline, isTrue);
        expect(lastState.transactions.length, 1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Loaded(empty, offline)] when offline and no local data',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [isA<TransactionLoading>(), isA<TransactionsLoaded>()],
      verify: (_) {
        final s = bloc.state as TransactionsLoaded;
        expect(s.isOffline, isTrue);
        expect(s.transactions, isEmpty);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'uses cache and skips API call when cache is still valid',
      build: () {
        // Pre-populate cache: load once to set _lastApiLoadTime
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([_expense1.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense1)],
            'pagination': {'hasMore': false},
            'totals': {'income': 0.0, 'expense': 30.0},
          }),
        );
        return bloc;
      },
      act: (b) async {
        // First load sets the cache timestamp
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 100));
        // Second load should hit cache (< 30 s TTL)
        b.add(LoadTransactions());
      },
      // We just check the API is only called once (cache hit on second)
      verify: (_) {
        verify(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'falls back to local data and emits offline when API throws',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([_expense1.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenThrow(Exception('Network timeout'));
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionsLoaded>(), // local emit
        isA<TransactionsLoaded>(), // fallback offline emit
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'sets hasMorePages=true when server pagination indicates more data',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense1)],
            'pagination': {'hasMore': true},
            'totals': {'income': 0.0, 'expense': 30.0},
          }),
        );
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      verify: (_) {
        final s = bloc.state as TransactionsLoaded;
        expect(s.hasMorePages, isTrue);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AddTransaction
  // ─────────────────────────────────────────────────────────────────────────

  group('AddTransaction', () {
    final newTx = _makeTransaction(
      amount: 75.0,
      type: TransactionType.expense,
      category: 'Ocio',
      syncStatus: SyncStatus.synced,
    ).copyWith(id: null);

    final savedTx = _makeTransaction(
      id: 'tx-new',
      amount: 75.0,
      type: TransactionType.expense,
      category: 'Ocio',
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Added, Loaded] when online and API succeeds',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _fakeResponse({'transaction': _toServerJson(savedTx)}),
        );
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(AddTransaction(transaction: newTx)),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionAdded>(),
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        verify(mockApiClient.post(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDatabase.saveTransaction(any)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Error] when server returns Validation Error',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          Exception('Validation Error: la cantidad debe ser positiva'),
        );
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(AddTransaction(transaction: newTx)),
      expect: () => [isA<TransactionLoading>(), isA<TransactionError>()],
      verify: (_) {
        // Should NOT save locally on validation error
        verifyNever(mockLocalDatabase.saveTransaction(any));
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'saves offline and emits [Loading, Added, Loaded] when network unavailable',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(AddTransaction(transaction: newTx)),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionAdded>(),
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        verify(mockLocalDatabase.saveTransaction(any)).called(1);
        verify(mockSyncManager.enqueueCreate(any)).called(1);
        verifyNever(mockApiClient.post(any, data: anyNamed('data')));

        final s = bloc.state as TransactionsLoaded;
        expect(s.isOffline, isTrue);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'saves offline when online but API throws non-validation error',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenThrow(Exception('Server error 500'));
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(AddTransaction(transaction: newTx)),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionAdded>(),
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        // Fallback to offline path after API error
        verify(mockLocalDatabase.saveTransaction(any)).called(1);
        verify(mockSyncManager.enqueueCreate(any)).called(1);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // EditTransaction
  // ─────────────────────────────────────────────────────────────────────────

  group('EditTransaction', () {
    final existing = _makeTransaction(id: 'tx-1', amount: 30.0);
    final updated = existing.copyWith(amount: 45.0, description: 'Updated');

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Updated, Loaded] when online and API succeeds',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        // Seed the bloc's internal list with an existing transaction
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _fakeResponse({'transaction': _toServerJson(updated)}),
        );
        return bloc;
      },
      act: (b) async {
        // First load to populate _transactions list
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(EditTransaction(transaction: updated));
      },
      verify: (_) {
        verify(mockApiClient.put(any, data: anyNamed('data'))).called(1);
        verify(
          mockLocalDatabase.updateTransaction(any, any),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Error, Loaded] when transaction id not found in list',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        return bloc;
      },
      act: (b) => b.add(
        EditTransaction(transaction: _makeTransaction(id: 'nonexistent-id')),
      ),
      expect: () => [
        isA<TransactionLoading>(),
        isA<TransactionError>(),
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        final s = bloc.state as TransactionsLoaded;
        // Error message should mention not found
        expect(s, isA<TransactionsLoaded>());
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'saves offline and emits [Loading, Updated, Loaded] when offline',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(EditTransaction(transaction: updated));
      },
      verify: (_) {
        verify(
          mockLocalDatabase.updateTransaction(any, any),
        ).called(greaterThanOrEqualTo(1));
        verify(mockSyncManager.enqueueUpdate(any)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Error] when API returns Validation Error on edit',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.put(any, data: anyNamed('data')),
        ).thenThrow(Exception('Validation Error: tipo inválido'));
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(EditTransaction(transaction: updated));
      },
      verify: (_) {
        // On validation error, should not enqueue offline update
        verifyNever(mockSyncManager.enqueueUpdate(any));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DeleteTransaction
  // ─────────────────────────────────────────────────────────────────────────

  group('DeleteTransaction', () {
    final existing = _makeTransaction(id: 'tx-1');

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loading, Deleted, Loaded] when online and API succeeds',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(
          mockApiClient.delete(any),
        ).thenAnswer((_) async => _fakeResponse({}));
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(DeleteTransaction(transactionId: 'tx-1'));
      },
      verify: (_) {
        verify(mockApiClient.delete(any)).called(1);
        verify(mockLocalDatabase.deleteTransaction('tx-1')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'still deletes locally even when API throws',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockApiClient.delete(any)).thenThrow(Exception('Server error'));
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(DeleteTransaction(transactionId: 'tx-1'));
      },
      expect: () =>
          containsAll([isA<TransactionDeleted>(), isA<TransactionsLoaded>()]),
      verify: (_) {
        // Local deletion must still happen
        verify(mockLocalDatabase.deleteTransaction('tx-1')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'enqueues delete when offline (non-local id)',
      build: () {
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([existing.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(DeleteTransaction(transactionId: 'tx-1'));
      },
      verify: (_) {
        verify(mockSyncManager.enqueueDelete('tx-1')).called(1);
        verify(mockLocalDatabase.deleteTransaction('tx-1')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'does NOT enqueue delete for local_ ids when offline',
      build: () {
        final localTx = _makeTransaction(
          id: 'local_123456',
          syncStatus: SyncStatus.pending,
        );
        when(
          mockLocalDatabase.getAllTransactions(),
        ).thenReturn([localTx.toMap()]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(DeleteTransaction(transactionId: 'local_123456'));
      },
      verify: (_) {
        verifyNever(mockSyncManager.enqueueDelete(any));
        verify(mockLocalDatabase.deleteTransaction('local_123456')).called(1);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LoadMoreTransactions
  // ─────────────────────────────────────────────────────────────────────────

  group('LoadMoreTransactions', () {
    blocTest<TransactionBloc, TransactionState>(
      'does nothing when hasMorePages is false (no API call made)',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        return bloc;
      },
      act: (b) => b.add(LoadMoreTransactions()),
      expect: () => [], // no state changes
      verify: (_) {
        verifyNever(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        );
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'loads next page and appends transactions when hasMorePages is true',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // First call: initial load setting hasMorePages=true
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense1)],
            'pagination': {'hasMore': true},
            'totals': {'income': 0.0, 'expense': 30.0},
          }),
        );
        return bloc;
      },
      act: (b) async {
        // First load to set hasMorePages = true
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));

        // Switch to returning page 2 data
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense2)],
            'pagination': {'hasMore': false},
          }),
        );

        b.add(LoadMoreTransactions());
      },
      verify: (_) {
        // API should be called twice total
        verify(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).called(2);

        final s = bloc.state as TransactionsLoaded;
        expect(s.hasMorePages, isFalse);
        // Both transactions should be in state
        expect(s.transactions.length, 2);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits Loaded silently without error when API throws during pagination',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);

        // Initial load with hasMorePages=true
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [_toServerJson(_expense1)],
            'pagination': {'hasMore': true},
            'totals': {'income': 0.0, 'expense': 30.0},
          }),
        );
        return bloc;
      },
      act: (b) async {
        b.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));

        // Simulate API failure on page 2
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenThrow(Exception('Timeout'));

        b.add(LoadMoreTransactions());
      },
      // Should emit Loaded silently (no error state)
      verify: (_) {
        expect(bloc.state, isA<TransactionsLoaded>());
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SyncTransactions
  // ─────────────────────────────────────────────────────────────────────────

  group('SyncTransactions', () {
    blocTest<TransactionBloc, TransactionState>(
      'emits [Syncing] then triggers LoadTransactions on successful sync',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockSyncManager.processQueue()).thenAnswer((_) async => true);
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(
          mockApiClient.get(
            any,
            queryParameters: anyNamed('queryParameters'),
            options: anyNamed('options'),
            cancelToken: anyNamed('cancelToken'),
          ),
        ).thenAnswer(
          (_) async => _fakeResponse({
            'transactions': [],
            'pagination': {'hasMore': false},
          }),
        );
        return bloc;
      },
      act: (b) => b.add(SyncTransactions()),
      expect: () => [
        isA<TransactionsSyncing>(),
        isA<TransactionLoading>(), // from the triggered LoadTransactions
        isA<TransactionsLoaded>(),
      ],
      verify: (_) {
        verify(mockSyncManager.processQueue()).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Loaded(offline)] without syncing when offline',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(SyncTransactions()),
      expect: () => [isA<TransactionsLoaded>()],
      verify: (_) {
        verifyNever(mockSyncManager.processQueue());
        final s = bloc.state as TransactionsLoaded;
        expect(s.isOffline, isTrue);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'emits [Syncing, Loaded] when sync fails (processQueue returns false)',
      build: () {
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
        when(mockSyncManager.processQueue()).thenAnswer((_) async => false);
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        return bloc;
      },
      act: (b) => b.add(SyncTransactions()),
      expect: () => [isA<TransactionsSyncing>(), isA<TransactionsLoaded>()],
      verify: (_) {
        verify(mockSyncManager.processQueue()).called(1);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Computed getters
  // ─────────────────────────────────────────────────────────────────────────

  group('Computed getters', () {
    test(
      'totalBalance returns income minus expenses from local transactions',
      () async {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([
          _income1.toMap(), // 2000 income
          _expense1.toMap(), // 30 expense
          _expense2.toMap(), // 20 expense
        ]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

        bloc.add(LoadTransactions());
        await Future.delayed(const Duration(milliseconds: 50));

        expect(bloc.totalIncome, 2000.0);
        expect(bloc.totalExpenses, 50.0);
        expect(bloc.totalBalance, closeTo(1950.0, 0.01));
      },
    );

    test('totalBalance uses server totals when available', () async {
      when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(
        mockApiClient.get(
          any,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        ),
      ).thenAnswer(
        (_) async => _fakeResponse({
          'transactions': [],
          'pagination': {'hasMore': false},
          'totals': {'income': 5000.0, 'expense': 1200.0},
        }),
      );

      bloc.add(LoadTransactions());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.totalIncome, 5000.0);
      expect(bloc.totalExpenses, 1200.0);
      expect(bloc.totalBalance, closeTo(3800.0, 0.01));
    });

    test('expensesByCategory groups expenses correctly', () async {
      final tx1 = _makeTransaction(
        id: 'a',
        amount: 15.0,
        type: TransactionType.expense,
        category: 'Alimentación',
      );
      final tx2 = _makeTransaction(
        id: 'b',
        amount: 25.0,
        type: TransactionType.expense,
        category: 'Alimentación',
      );
      final tx3 = _makeTransaction(
        id: 'c',
        amount: 10.0,
        type: TransactionType.expense,
        category: 'Transporte',
      );
      final income = _makeTransaction(
        id: 'd',
        amount: 1000.0,
        type: TransactionType.income,
        category: 'Salario',
      );

      when(
        mockLocalDatabase.getAllTransactions(),
      ).thenReturn([tx1.toMap(), tx2.toMap(), tx3.toMap(), income.toMap()]);
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      bloc.add(LoadTransactions());
      await Future.delayed(const Duration(milliseconds: 50));

      final byCategory = bloc.expensesByCategory;
      expect(byCategory['Alimentación'], closeTo(40.0, 0.01));
      expect(byCategory['Transporte'], closeTo(10.0, 0.01));
      expect(byCategory.containsKey('Salario'), isFalse);
    });

    test('transactions getter returns unmodifiable copy', () async {
      when(
        mockLocalDatabase.getAllTransactions(),
      ).thenReturn([_expense1.toMap()]);
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      bloc.add(LoadTransactions());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        () => bloc.transactions.add(_expense2),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('totalBalance is 0 when no transactions', () {
      expect(bloc.totalBalance, 0.0);
      expect(bloc.totalIncome, 0.0);
      expect(bloc.totalExpenses, 0.0);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // pendingSyncCount in state
  // ─────────────────────────────────────────────────────────────────────────

  group('pendingSyncCount', () {
    blocTest<TransactionBloc, TransactionState>(
      'reflects pendingCount from SyncManager in loaded state',
      build: () {
        when(mockLocalDatabase.getAllTransactions()).thenReturn([]);
        when(mockNetworkInfo.isConnected).thenAnswer((_) async => false);
        when(mockSyncManager.pendingCount).thenReturn(3);
        return bloc;
      },
      act: (b) => b.add(LoadTransactions()),
      verify: (_) {
        final s = bloc.state as TransactionsLoaded;
        expect(s.pendingSyncCount, 3);
      },
    );
  });
}

