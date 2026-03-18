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

/// RF-16: Categoría creada exitosamente
class CategoryCreated extends CategoryState {
  final CategoryEntity category;
  CategoryCreated({required this.category});
}

/// RF-16: Categoría actualizada exitosamente
class CategoryUpdated extends CategoryState {
  final CategoryEntity category;
  CategoryUpdated({required this.category});
}

/// RF-16: Categoría eliminada exitosamente
class CategoryDeleted extends CategoryState {
  final String categoryId;
  CategoryDeleted({required this.categoryId});
}

/// RF-17: Feedback de recategorización registrado
class CategoryFeedbackSubmitted extends CategoryState {
  final String message;
  CategoryFeedbackSubmitted({required this.message});
}

/// RF-17: Transacciones similares recategorizadas
class SimilarTransactionsRecategorized extends CategoryState {
  final int updatedCount;
  final String newCategory;
  SimilarTransactionsRecategorized({
    required this.updatedCount,
    required this.newCategory,
  });
}

/// Error al operar con categorías
class CategoryError extends CategoryState {
  final String message;
  CategoryError({required this.message});
}
