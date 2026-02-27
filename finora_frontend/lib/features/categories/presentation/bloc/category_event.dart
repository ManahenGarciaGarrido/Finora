/// Eventos del BLoC de categorías
abstract class CategoryEvent {}

/// Cargar todas las categorías desde el backend
class LoadCategories extends CategoryEvent {}

/// RF-16: Crear categoría personalizada
class CreateCategory extends CategoryEvent {
  final String name;
  final String type; // 'income' | 'expense'
  final String icon;
  final String color;

  CreateCategory({
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
  });
}

/// RF-16: Editar categoría personalizada
class UpdateCategory extends CategoryEvent {
  final String id;
  final String? name;
  final String? icon;
  final String? color;

  UpdateCategory({required this.id, this.name, this.icon, this.color});
}

/// RF-16: Eliminar categoría personalizada
class DeleteCategory extends CategoryEvent {
  final String id;
  DeleteCategory({required this.id});
}

/// RF-17: Registrar corrección de categoría (aprendizaje IA)
class SubmitCategoryFeedback extends CategoryEvent {
  final String description;
  final String type;
  final String correctedCategory;
  final String? originalCategory;
  final String? transactionId;

  SubmitCategoryFeedback({
    required this.description,
    required this.type,
    required this.correctedCategory,
    this.originalCategory,
    this.transactionId,
  });
}

/// RF-17: Recategorizar todas las transacciones similares
class RecategorizeSimilar extends CategoryEvent {
  final String description;
  final String type;
  final String newCategory;

  RecategorizeSimilar({
    required this.description,
    required this.type,
    required this.newCategory,
  });
}
