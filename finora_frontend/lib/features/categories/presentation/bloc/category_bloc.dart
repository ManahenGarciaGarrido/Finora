import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/category_entity.dart';
import 'category_event.dart';
import 'category_state.dart';

/// BLoC para gestión de categorías (RF-15)
///
/// Carga categorías predefinidas desde el backend.
/// Si la API no responde, usa las categorías por defecto definidas en CategoryEntity.
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final ApiClient _apiClient;
  List<CategoryEntity> _categories = [];

  CategoryBloc({required ApiClient apiClient})
      : _apiClient = apiClient,
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

    try {
      final response = await _apiClient.get(ApiEndpoints.categories);
      final data = response.data;

      if (data['categories'] != null && (data['categories'] as List).isNotEmpty) {
        _categories = (data['categories'] as List)
            .map((json) => CategoryEntity.fromJson(json as Map<String, dynamic>))
            .toList();
        _categories.sort((a, b) {
          final typeCompare = a.type.compareTo(b.type);
          if (typeCompare != 0) return typeCompare;
          return a.displayOrder.compareTo(b.displayOrder);
        });
      } else {
        _categories = CategoryEntity.allDefaults;
      }

      emit(CategoriesLoaded(categories: _categories));
    } catch (e) {
      // Fallback a categorías predefinidas locales
      _categories = CategoryEntity.allDefaults;
      emit(CategoriesLoaded(categories: _categories));
    }
  }
}
