import '../../domain/entities/category_entity.dart';

/// Estados del BLoC de categorías
abstract class CategoryState {}

/// Estado inicial
class CategoryInitial extends CategoryState {}

/// Cargando categorías
class CategoryLoading extends CategoryState {}

/// Categorías cargadas exitosamente
class CategoriesLoaded extends CategoryState {
  final List<CategoryEntity> categories;

  CategoriesLoaded({required this.categories});

  List<CategoryEntity> get expenseCategories =>
      categories.where((c) => c.isExpense).toList();

  List<CategoryEntity> get incomeCategories =>
      categories.where((c) => c.isIncome).toList();
}

/// Error al cargar categorías
class CategoryError extends CategoryState {
  final String message;

  CategoryError({required this.message});
}
