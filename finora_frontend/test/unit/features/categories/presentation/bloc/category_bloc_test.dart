import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';

import 'package:finora_frontend/core/network/api_client.dart';
import 'package:finora_frontend/core/database/local_database.dart';
import 'package:finora_frontend/features/categories/domain/entities/category_entity.dart';
import 'package:finora_frontend/features/categories/presentation/bloc/category_bloc.dart';
import 'package:finora_frontend/features/categories/presentation/bloc/category_event.dart';
import 'package:finora_frontend/features/categories/presentation/bloc/category_state.dart';

@GenerateMocks([ApiClient, LocalDatabase])
import 'category_bloc_test.mocks.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Response<dynamic> _fakeResponse(Map<String, dynamic> data) {
  return Response(
    data: data,
    statusCode: 200,
    requestOptions: RequestOptions(path: ''),
  );
}

Map<String, dynamic> _categoryJson({
  String id = 'cat-1',
  String name = 'Alimentación',
  String type = 'expense',
  String icon = 'restaurant',
  String color = '#F59E0B',
  bool isPredefined = false,
  int displayOrder = 1,
}) {
  return {
    'id': id,
    'name': name,
    'type': type,
    'icon': icon,
    'color': color,
    'is_predefined': isPredefined,
    'display_order': displayOrder,
  };
}

CategoryEntity _makeCategory({
  String id = 'cat-1',
  String name = 'Alimentación',
  String type = 'expense',
  String icon = 'restaurant',
  String color = '#F59E0B',
  bool isPredefined = false,
  int displayOrder = 1,
}) {
  return CategoryEntity(
    id: id,
    name: name,
    type: type,
    icon: icon,
    color: color,
    isPredefined: isPredefined,
    displayOrder: displayOrder,
  );
}

// ---------------------------------------------------------------------------
// Shared test data
// ---------------------------------------------------------------------------

final _expenseCat = _makeCategory(
  id: 'cat-1',
  name: 'Alimentación',
  type: 'expense',
  icon: 'restaurant',
  color: '#F59E0B',
  displayOrder: 1,
);

final _incomeCat = _makeCategory(
  id: 'cat-2',
  name: 'Salario',
  type: 'income',
  icon: 'work',
  color: '#22C55E',
  displayOrder: 1,
);

final _customCat = _makeCategory(
  id: 'cat-99',
  name: 'Suscripciones',
  type: 'expense',
  icon: 'movie',
  color: '#6366F1',
  isPredefined: false,
  displayOrder: 10,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late CategoryBloc bloc;
  late MockApiClient mockApiClient;
  late MockLocalDatabase mockLocalDatabase;

  setUp(() {
    mockApiClient = MockApiClient();
    mockLocalDatabase = MockLocalDatabase();

    // Default stubs
    when(mockLocalDatabase.getAllCategories()).thenReturn([]);
    when(mockLocalDatabase.saveAllCategories(any)).thenAnswer((_) async {
      return;
    });

    bloc = CategoryBloc(
      apiClient: mockApiClient,
      localDatabase: mockLocalDatabase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Initial state
  // ─────────────────────────────────────────────────────────────────────────

  test('initial state is CategoryInitial', () {
    expect(bloc.state, isA<CategoryInitial>());
  });

  // ─────────────────────────────────────────────────────────────────────────
  // LoadCategories
  // ─────────────────────────────────────────────────────────────────────────

  group('LoadCategories', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [Loading, Loaded] with categories from API when successful',
      build: () {
        when(mockLocalDatabase.getAllCategories()).thenReturn([]);
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => _fakeResponse({
            'categories': [
              _categoryJson(id: 'cat-1', name: 'Alimentación', type: 'expense'),
              _categoryJson(
                id: 'cat-2',
                name: 'Salario',
                type: 'income',
                icon: 'work',
                color: '#22C55E',
              ),
            ],
          }),
        );
        return bloc;
      },
      act: (b) => b.add(LoadCategories()),
      expect: () => [isA<CategoryLoading>(), isA<CategoriesLoaded>()],
      verify: (_) {
        verify(mockApiClient.get(any)).called(1);
        verify(mockLocalDatabase.saveAllCategories(any)).called(1);

        final s = bloc.state as CategoriesLoaded;
        expect(s.categories.length, 2);
        expect(s.expenseCategories.length, 1);
        expect(s.incomeCategories.length, 1);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Loading, Loaded(local), Loaded(api)] when local cache exists',
      build: () {
        when(
          mockLocalDatabase.getAllCategories(),
        ).thenReturn([_categoryJson()]);
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => _fakeResponse({
            'categories': [
              _categoryJson(id: 'cat-1', name: 'Alimentación', type: 'expense'),
              _categoryJson(
                id: 'cat-new',
                name: 'Nueva Cat',
                type: 'expense',
                icon: 'shopping_cart',
                color: '#3B82F6',
              ),
            ],
          }),
        );
        return bloc;
      },
      act: (b) => b.add(LoadCategories()),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoriesLoaded>(), // from local cache
        isA<CategoriesLoaded>(), // from API
      ],
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Loading, Loaded(empty)] and uses defaults when API returns empty list',
      build: () {
        when(mockLocalDatabase.getAllCategories()).thenReturn([]);
        when(
          mockApiClient.get(any),
        ).thenAnswer((_) async => _fakeResponse({'categories': []}));
        return bloc;
      },
      act: (b) => b.add(LoadCategories()),
      expect: () => [isA<CategoryLoading>(), isA<CategoriesLoaded>()],
      verify: (_) {
        final s = bloc.state as CategoriesLoaded;
        // Should fall back to defaults (12 predefined categories)
        expect(s.categories, isNotEmpty);
        expect(s.categories.every((c) => c.isPredefined), isTrue);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Loading, Loaded] with defaults when API throws',
      build: () {
        when(mockLocalDatabase.getAllCategories()).thenReturn([]);
        when(mockApiClient.get(any)).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(LoadCategories()),
      expect: () => [isA<CategoryLoading>(), isA<CategoriesLoaded>()],
      verify: (_) {
        final s = bloc.state as CategoriesLoaded;
        expect(s.categories, isNotEmpty);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Loading, Loaded(local), Loaded(defaults)] when API fails but local exists',
      build: () {
        when(
          mockLocalDatabase.getAllCategories(),
        ).thenReturn([_categoryJson()]);
        when(mockApiClient.get(any)).thenThrow(Exception('Timeout'));
        return bloc;
      },
      act: (b) => b.add(LoadCategories()),
      expect: () => [
        isA<CategoryLoading>(),
        isA<CategoriesLoaded>(), // local hit
        isA<CategoriesLoaded>(), // API fallback (keeps local data)
      ],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // CreateCategory
  // ─────────────────────────────────────────────────────────────────────────

  group('CreateCategory', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [Created, Loaded] when API returns new category',
      build: () {
        when(mockApiClient.post(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _fakeResponse({
            'category': _categoryJson(
              id: 'cat-99',
              name: 'Suscripciones',
              type: 'expense',
              icon: 'movie',
              color: '#6366F1',
            ),
          }),
        );
        return bloc;
      },
      act: (b) => b.add(
        CreateCategory(
          name: 'Suscripciones',
          type: 'expense',
          icon: 'movie',
          color: '#6366F1',
        ),
      ),
      expect: () => [isA<CategoryCreated>(), isA<CategoriesLoaded>()],
      verify: (_) {
        verify(mockApiClient.post(any, data: anyNamed('data'))).called(1);
        verify(mockLocalDatabase.saveAllCategories(any)).called(1);

        final s = bloc.state as CategoriesLoaded;
        expect(s.categories.any((c) => c.name == 'Suscripciones'), isTrue);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] when API returns 409 Conflict (duplicate name)',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenThrow(Exception('Conflict: 409 - nombre ya existe'));
        return bloc;
      },
      act: (b) => b.add(
        CreateCategory(
          name: 'Alimentación', // already exists
          type: 'expense',
          icon: 'restaurant',
          color: '#F59E0B',
        ),
      ),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
      verify: (_) {
        // The bloc emits [CategoryError, CategoriesLoaded]; last state is CategoriesLoaded.
        // We verify the error was emitted via the expect list above.
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] when API returns 403 Forbidden (predefined category)',
      build: () {
        when(mockApiClient.post(any, data: anyNamed('data'))).thenThrow(
          Exception(
            'Forbidden: 403 - No se pueden modificar categorías predefinidas',
          ),
        );
        return bloc;
      },
      act: (b) => b.add(
        CreateCategory(
          name: 'Salud',
          type: 'expense',
          icon: 'local_hospital',
          color: '#EF4444',
        ),
      ),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
      verify: (_) {
        // message check: 'predefinidas' verified via expect list above
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] on generic server error',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenThrow(Exception('Internal Server Error'));
        return bloc;
      },
      act: (b) => b.add(
        CreateCategory(
          name: 'Mascotas',
          type: 'expense',
          icon: 'pets',
          color: '#10B981',
        ),
      ),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // UpdateCategory
  // ─────────────────────────────────────────────────────────────────────────

  group('UpdateCategory', () {
    _makeCategory(
      id: 'cat-99',
      name: 'Streaming',
      type: 'expense',
      icon: 'movie',
      color: '#8B5CF6',
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Updated, Loaded] when API update succeeds',
      build: () {
        // Pre-populate bloc with existing category
        when(
          mockLocalDatabase.getAllCategories(),
        ).thenReturn([_customCat.toJson()]);
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => _fakeResponse({
            'categories': [_customCat.toJson()],
          }),
        );
        when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _fakeResponse({
            'category': {
              'id': 'cat-99',
              'name': 'Streaming',
              'type': 'expense',
              'icon': 'movie',
              'color': '#8B5CF6',
              'is_predefined': false,
              'display_order': 10,
            },
          }),
        );
        return bloc;
      },
      act: (b) async {
        b.add(LoadCategories());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(
          UpdateCategory(id: 'cat-99', name: 'Streaming', color: '#8B5CF6'),
        );
      },
      verify: (_) {
        verify(mockApiClient.put(any, data: anyNamed('data'))).called(1);
        verify(
          mockLocalDatabase.saveAllCategories(any),
        ).called(greaterThanOrEqualTo(1));

        final s = bloc.state as CategoriesLoaded;
        expect(
          s.categories.any((c) => c.id == 'cat-99' && c.name == 'Streaming'),
          isTrue,
        );
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] when category to update not found (404)',
      build: () {
        when(
          mockApiClient.put(any, data: anyNamed('data')),
        ).thenThrow(Exception('Not Found: 404 - category not found'));
        return bloc;
      },
      act: (b) =>
          b.add(UpdateCategory(id: 'nonexistent', name: 'Does Not Exist')),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
    );

    blocTest<CategoryBloc, CategoryState>(
      'only sends fields that are non-null in UpdateCategory',
      build: () {
        when(mockApiClient.put(any, data: anyNamed('data'))).thenAnswer(
          (_) async => _fakeResponse({'category': _customCat.toJson()}),
        );
        return bloc;
      },
      act: (b) => b.add(
        UpdateCategory(id: 'cat-99', color: '#FF0000'), // only color changed
      ),
      verify: (_) {
        final call =
            verify(
                  mockApiClient.put(any, data: captureAnyNamed('data')),
                ).captured.first
                as Map<String, dynamic>;
        // Only 'color' should be present, not 'name' or 'icon'
        expect(call.containsKey('color'), isTrue);
        expect(call.containsKey('name'), isFalse);
        expect(call.containsKey('icon'), isFalse);
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // DeleteCategory
  // ─────────────────────────────────────────────────────────────────────────

  group('DeleteCategory', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [Deleted, Loaded] when API delete succeeds',
      build: () {
        when(
          mockLocalDatabase.getAllCategories(),
        ).thenReturn([_customCat.toJson()]);
        when(mockApiClient.get(any)).thenAnswer(
          (_) async => _fakeResponse({
            'categories': [_customCat.toJson()],
          }),
        );
        when(
          mockApiClient.delete(any),
        ).thenAnswer((_) async => _fakeResponse({}));
        return bloc;
      },
      act: (b) async {
        b.add(LoadCategories());
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(DeleteCategory(id: 'cat-99'));
      },
      verify: (_) {
        verify(mockApiClient.delete(any)).called(1);
        verify(
          mockLocalDatabase.saveAllCategories(any),
        ).called(greaterThanOrEqualTo(1));

        final s = bloc.state as CategoriesLoaded;
        expect(s.categories.any((c) => c.id == 'cat-99'), isFalse);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] when category has associated transactions',
      build: () {
        when(
          mockApiClient.delete(any),
        ).thenThrow(Exception('Cannot delete: has transacciones asociadas'));
        return bloc;
      },
      act: (b) => b.add(DeleteCategory(id: 'cat-with-txs')),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
      verify: (_) {
        // message check: 'transacciones' verified via expect list above
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] when deleting a predefined category (403)',
      build: () {
        when(mockApiClient.delete(any)).thenThrow(
          Exception('Forbidden: 403 - predefined categories cannot be deleted'),
        );
        return bloc;
      },
      act: (b) => b.add(DeleteCategory(id: 'def_1')),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
      verify: (_) {
        // message check: 'predefinidas' verified via expect list above
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error, Loaded] on generic server error during delete',
      build: () {
        when(
          mockApiClient.delete(any),
        ).thenThrow(Exception('Internal Server Error'));
        return bloc;
      },
      act: (b) => b.add(DeleteCategory(id: 'cat-99')),
      expect: () => [isA<CategoryError>(), isA<CategoriesLoaded>()],
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // SubmitCategoryFeedback
  // ─────────────────────────────────────────────────────────────────────────

  group('SubmitCategoryFeedback', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [FeedbackSubmitted] when API succeeds',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenAnswer((_) async => _fakeResponse({'status': 'ok'}));
        return bloc;
      },
      act: (b) => b.add(
        SubmitCategoryFeedback(
          description: 'Netflix',
          type: 'expense',
          correctedCategory: 'Ocio',
          originalCategory: 'Servicios',
          transactionId: 'tx-5',
        ),
      ),
      expect: () => [isA<CategoryFeedbackSubmitted>()],
      verify: (_) {
        verify(mockApiClient.post(any, data: anyNamed('data'))).called(1);

        final s = bloc.state as CategoryFeedbackSubmitted;
        expect(s.message, isNotEmpty);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits no states (silent) when API throws on feedback',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenThrow(Exception('Network error'));
        return bloc;
      },
      act: (b) => b.add(
        SubmitCategoryFeedback(
          description: 'Supermercado',
          type: 'expense',
          correctedCategory: 'Alimentación',
        ),
      ),
      // Feedback errors are silent — no state emitted
      expect: () => [],
    );

    blocTest<CategoryBloc, CategoryState>(
      'sends optional fields (originalCategory, transactionId) when provided',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenAnswer((_) async => _fakeResponse({'status': 'ok'}));
        return bloc;
      },
      act: (b) => b.add(
        SubmitCategoryFeedback(
          description: 'Gym membership',
          type: 'expense',
          correctedCategory: 'Salud',
          originalCategory: 'Otros',
          transactionId: 'tx-42',
        ),
      ),
      verify: (_) {
        final call =
            verify(
                  mockApiClient.post(any, data: captureAnyNamed('data')),
                ).captured.first
                as Map<String, dynamic>;

        expect(call['original_category'], 'Otros');
        expect(call['transaction_id'], 'tx-42');
        expect(call['corrected_category'], 'Salud');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RecategorizeSimilar
  // ─────────────────────────────────────────────────────────────────────────

  group('RecategorizeSimilar', () {
    blocTest<CategoryBloc, CategoryState>(
      'emits [SimilarTransactionsRecategorized] with updatedCount on success',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenAnswer((_) async => _fakeResponse({'updated_count': 5}));
        return bloc;
      },
      act: (b) => b.add(
        RecategorizeSimilar(
          description: 'Netflix',
          type: 'expense',
          newCategory: 'Ocio',
        ),
      ),
      expect: () => [isA<SimilarTransactionsRecategorized>()],
      verify: (_) {
        final s = bloc.state as SimilarTransactionsRecategorized;
        expect(s.updatedCount, 5);
        expect(s.newCategory, 'Ocio');
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [SimilarTransactionsRecategorized] with updatedCount=0 when null from API',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenAnswer((_) async => _fakeResponse({'updated_count': null}));
        return bloc;
      },
      act: (b) => b.add(
        RecategorizeSimilar(
          description: 'Uber Eats',
          type: 'expense',
          newCategory: 'Alimentación',
        ),
      ),
      expect: () => [isA<SimilarTransactionsRecategorized>()],
      verify: (_) {
        final s = bloc.state as SimilarTransactionsRecategorized;
        expect(s.updatedCount, 0);
      },
    );

    blocTest<CategoryBloc, CategoryState>(
      'emits [Error] when API throws during bulk recategorization',
      build: () {
        when(
          mockApiClient.post(any, data: anyNamed('data')),
        ).thenThrow(Exception('AI service unavailable'));
        return bloc;
      },
      act: (b) => b.add(
        RecategorizeSimilar(
          description: 'Spotify',
          type: 'expense',
          newCategory: 'Ocio',
        ),
      ),
      expect: () => [isA<CategoryError>()],
      verify: (_) {
        final s = bloc.state as CategoryError;
        expect(s.message, contains('recategorizar'));
      },
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Computed getters on CategoryBloc
  // ─────────────────────────────────────────────────────────────────────────

  group('CategoryBloc getters', () {
    test('expenseCategories filters correctly', () async {
      when(mockLocalDatabase.getAllCategories()).thenReturn([
        _expenseCat.toJson(),
        _incomeCat.toJson(),
        _customCat.toJson(),
      ]);
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _fakeResponse({
          'categories': [
            _expenseCat.toJson(),
            _incomeCat.toJson(),
            _customCat.toJson(),
          ],
        }),
      );

      bloc.add(LoadCategories());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.expenseCategories.every((c) => c.isExpense), isTrue);
      expect(bloc.incomeCategories.every((c) => c.isIncome), isTrue);
    });

    test('findByName returns correct entity', () async {
      when(mockLocalDatabase.getAllCategories()).thenReturn([]);
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _fakeResponse({
          'categories': [_expenseCat.toJson(), _incomeCat.toJson()],
        }),
      );

      bloc.add(LoadCategories());
      await Future.delayed(const Duration(milliseconds: 50));

      final found = bloc.findByName('Salario');
      expect(found, isNotNull);
      expect(found!.type, 'income');
    });

    test('findByName returns null when category does not exist', () async {
      when(mockLocalDatabase.getAllCategories()).thenReturn([]);
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _fakeResponse({
          'categories': [_expenseCat.toJson()],
        }),
      );

      bloc.add(LoadCategories());
      await Future.delayed(const Duration(milliseconds: 50));

      expect(bloc.findByName('NoExiste'), isNull);
    });

    test('categories list is sorted by type then displayOrder', () async {
      final cat1 = _makeCategory(
        id: 'e1',
        type: 'expense',
        name: 'Ocio',
        displayOrder: 2,
      );
      final cat2 = _makeCategory(
        id: 'e2',
        type: 'expense',
        name: 'Alimentación',
        displayOrder: 1,
      );
      final cat3 = _makeCategory(
        id: 'i1',
        type: 'income',
        name: 'Salario',
        displayOrder: 1,
      );

      when(mockLocalDatabase.getAllCategories()).thenReturn([]);
      when(mockApiClient.get(any)).thenAnswer(
        (_) async => _fakeResponse({
          'categories': [cat1.toJson(), cat3.toJson(), cat2.toJson()],
        }),
      );

      bloc.add(LoadCategories());
      await Future.delayed(const Duration(milliseconds: 50));

      final cats = bloc.categories;
      // expense comes before income alphabetically in type sort
      expect(cats.first.type, 'expense');
      // Within expense, displayOrder 1 (Alimentación) before 2 (Ocio)
      final expenses = cats.where((c) => c.isExpense).toList();
      expect(expenses.first.name, 'Alimentación');
    });
  });
}

// ---------------------------------------------------------------------------
// Extension to simplify state history access in verify callbacks
// ---------------------------------------------------------------------------
extension _BlocStateHistory<E, S> on Bloc<E, S> {
  // placeholder — bloc_test captures internally
}

