import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/category_entity.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC para gestión de categorías (RF-15, RF-16, RF-17)
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  List<CategoryEntity> _categories = [];

  CategoryBloc({
    required ApiClient apiClient,
    required LocalDatabase localDatabase,
  }) : _apiClient = apiClient,
       _localDatabase = localDatabase,
       super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<CreateCategory>(_onCreateCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<SubmitCategoryFeedback>(_onSubmitFeedback);
    on<RecategorizeSimilar>(_onRecategorizeSimilar);
  }

  List<CategoryEntity> get categories => _categories;

  List<CategoryEntity> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  List<CategoryEntity> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  CategoryEntity? findByName(String name) {
    try {
      return _categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());

    final localCategories = _localDatabase.getAllCategories();
    if (localCategories.isNotEmpty) {
      _categories = localCategories
          .map((json) => CategoryEntity.fromJson(json))
          .toList();
      _sortCategories();
      emit(CategoriesLoaded(categories: _categories));
    }

    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      final data = response.data;

      if (data['categories'] != null &&
          (data['categories'] as List).isNotEmpty) {
        _categories = (data['categories'] as List)
            .map(
              (json) => CategoryEntity.fromJson(json as Map<String, dynamic>),
            )
            .toList();
        _sortCategories();

        await _localDatabase.saveAllCategories(
          (data['categories'] as List)
              .map((json) => Map<String, dynamic>.from(json as Map))
              .toList(),
        );
      } else if (_categories.isEmpty) {
        _categories = CategoryEntity.allDefaults;
      }

      emit(CategoriesLoaded(categories: _categories));
    } catch (e) {
      debugPrint('CategoryBloc: Error cargando de API: $e');
      if (_categories.isEmpty) {
        _categories = CategoryEntity.allDefaults;
      }
      emit(CategoriesLoaded(categories: _categories));
    }
  }

  /// RF-16: Crear categoría personalizada
  Future<void> _onCreateCategory(
    CreateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.categories,
        data: {
          'name': event.name,
          'type': event.type,
          'icon': event.icon,
          'color': event.color,
        },
      );

      final newCategory = CategoryEntity.fromJson(
        response.data['category'] as Map<String, dynamic>,
      );
      _categories.add(newCategory);
      _sortCategories();

      // Actualizar cache local
      await _localDatabase.saveAllCategories(
        _categories.map((c) => c.toJson()).toList(),
      );

      emit(CategoryCreated(category: newCategory));
      emit(CategoriesLoaded(categories: _categories));
    } catch (e) {
      debugPrint('CategoryBloc: Error creando categoría: $e');
      final errorMsg = _extractErrorMessage(e);
      emit(CategoryError(message: errorMsg));
      emit(CategoriesLoaded(categories: _categories));
    }
  }

  /// RF-16: Editar categoría personalizada
  Future<void> _onUpdateCategory(
    UpdateCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final data = <String, dynamic>{};
      if (event.name != null) data['name'] = event.name;
      if (event.icon != null) data['icon'] = event.icon;
      if (event.color != null) data['color'] = event.color;

      final response = await _apiClient.put(
        ApiEndpoints.categoryById(event.id),
        data: data,
      );

      final updated = CategoryEntity.fromJson(
        response.data['category'] as Map<String, dynamic>,
      );

      final idx = _categories.indexWhere((c) => c.id == event.id);
      if (idx != -1) _categories[idx] = updated;
      _sortCategories();

      await _localDatabase.saveAllCategories(
        _categories.map((c) => c.toJson()).toList(),
      );

      emit(CategoryUpdated(category: updated));
      emit(CategoriesLoaded(categories: _categories));
    } catch (e) {
      debugPrint('CategoryBloc: Error actualizando categoría: $e');
      emit(CategoryError(message: _extractErrorMessage(e)));
      emit(CategoriesLoaded(categories: _categories));
    }
  }

  /// RF-16: Eliminar categoría personalizada
  Future<void> _onDeleteCategory(
    DeleteCategory event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _apiClient.delete(ApiEndpoints.categoryById(event.id));

      _categories.removeWhere((c) => c.id == event.id);

      await _localDatabase.saveAllCategories(
        _categories.map((c) => c.toJson()).toList(),
      );

      emit(CategoryDeleted(categoryId: event.id));
      emit(CategoriesLoaded(categories: _categories));
    } catch (e) {
      debugPrint('CategoryBloc: Error eliminando categoría: $e');
      emit(CategoryError(message: _extractErrorMessage(e)));
      emit(CategoriesLoaded(categories: _categories));
    }
  }

  /// RF-17: Registrar feedback de corrección para mejorar la IA
  Future<void> _onSubmitFeedback(
    SubmitCategoryFeedback event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _apiClient.post(
        ApiEndpoints.recategorize,
        data: {
          'description': event.description,
          'type': event.type,
          'corrected_category': event.correctedCategory,
          if (event.originalCategory != null)
            'original_category': event.originalCategory,
          if (event.transactionId != null)
            'transaction_id': event.transactionId,
        },
      );
      emit(
        CategoryFeedbackSubmitted(
          message: 'Categorización registrada para mejorar las predicciones',
        ),
      );
    } catch (e) {
      debugPrint('CategoryBloc: Error enviando feedback: $e');
      // No es crítico — continuar silenciosamente
    }
  }

  /// RF-17: Recategorizar transacciones similares en bloque
  Future<void> _onRecategorizeSimilar(
    RecategorizeSimilar event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.recategorize,
        data: {
          'description': event.description,
          'type': event.type,
          'new_category': event.newCategory,
        },
      );
      final updatedCount = response.data['updated_count'] as int? ?? 0;
      emit(
        SimilarTransactionsRecategorized(
          updatedCount: updatedCount,
          newCategory: event.newCategory,
        ),
      );
    } catch (e) {
      debugPrint('CategoryBloc: Error en recategorización masiva: $e');
      emit(
        CategoryError(
          message: 'Error al recategorizar transacciones similares',
        ),
      );
    }
  }

  void _sortCategories() {
    _categories.sort((a, b) {
      final typeCompare = a.type.compareTo(b.type);
      if (typeCompare != 0) return typeCompare;
      return a.displayOrder.compareTo(b.displayOrder);
    });
  }

  String _extractErrorMessage(dynamic error) {
    final s = error.toString();
    if (s.contains('Conflict') || s.contains('409')) {
      if (s.contains('nombre')) return 'Ya existe una categoría con ese nombre';
      return 'Ya existe una categoría con ese nombre';
    }
    if (s.contains('Forbidden') || s.contains('403')) {
      return 'No se pueden modificar categorías predefinidas';
    }
    if (s.contains('transacciones') || s.contains('transaction')) {
      return 'No se puede eliminar: tiene transacciones asociadas';
    }
    return 'Error al gestionar la categoría. Inténtalo de nuevo.';
  }
}
