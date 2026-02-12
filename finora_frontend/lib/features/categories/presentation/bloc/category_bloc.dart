import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/database/local_database.dart';
import '../../domain/entities/category_entity.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC para gestión de categorías (RF-15, RNF-06, RNF-15)
///
/// Estrategia offline-first:
/// 1. Cargar categorías de Hive (instantáneo)
/// 2. Actualizar desde API si hay conexión
/// 3. Fallback a categorías predefinidas si no hay datos
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiClient _apiClient;
  final LocalDatabase _localDatabase;
  List<CategoryEntity> _categories = [];

  CategoryBloc({
    required ApiClient apiClient,
    required LocalDatabase localDatabase,
  })  : _apiClient = apiClient,
        _localDatabase = localDatabase,
        super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
  }

  List<CategoryEntity> get categories => _categories;

  List<CategoryEntity> get expenseCategories =>
      _categories.where((c) => c.isExpense).toList();

  List<CategoryEntity> get incomeCategories =>
      _categories.where((c) => c.isIncome).toList();

  /// Busca una categoría por nombre
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

    // Paso 1: Cargar de Hive (instantáneo, < 5ms)
    final localCategories = _localDatabase.getAllCategories();
    if (localCategories.isNotEmpty) {
      _categories = localCategories
          .map((json) => CategoryEntity.fromJson(json))
          .toList();
      _sortCategories();
      emit(CategoriesLoaded(categories: _categories));
    }

    // Paso 2: Intentar cargar de API
    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      final data = response.data;

      if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
        _categories = (data['categories'] as List)
            .map((json) => CategoryEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        _sortCategories();

        // Guardar en Hive para offline
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
      // Fallback a categorías predefinidas locales si no hay nada
      if (_categories.isEmpty) {
        _categories = CategoryEntity.allDefaults;
      }
      emit(CategoriesLoaded(categories: _categories));
    }
  }

  void _sortCategories() {
    _categories.sort((a, b) {
      final typeCompare = a.type.compareTo(b.type);
      if (typeCompare != 0) return typeCompare;
      return a.displayOrder.compareTo(b.displayOrder);
    });
  }
}
