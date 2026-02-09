import 'package:flutter/material.dart';

/// Entidad de Categoría (RF-15)
///
/// Cada categoría tiene un nombre, tipo (ingreso/gasto),
/// icono representativo y color distintivo.
/// Las categorías predefinidas no pueden eliminarse.
class CategoryEntity {
  final String id;
  final String name;
  final String type; // 'income' o 'expense'
  final String icon; // Nombre del icono Material
  final String color; // Color hexadecimal #RRGGBB
  final bool isPredefined;
  final int displayOrder;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    required this.color,
    this.isPredefined = false,
    this.displayOrder = 0,
  });

  bool get isExpense => type == 'expense';
  bool get isIncome => type == 'income';

  /// Obtiene el IconData correspondiente al nombre del icono
  IconData get iconData => _iconMap[icon] ?? Icons.category_outlined;

  /// Parsea el color hexadecimal a Color de Flutter
  Color get colorValue {
    try {
      return Color(int.parse(color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6B7280);
    }
  }

  // Mapeo de nombres de icono a IconData
  static const Map<String, IconData> _iconMap = {
    'restaurant': Icons.restaurant_outlined,
    'directions_car': Icons.directions_car_outlined,
    'sports_esports': Icons.sports_esports_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'home': Icons.home_outlined,
    'phone_android': Icons.phone_android_outlined,
    'school': Icons.school_outlined,
    'checkroom': Icons.checkroom_outlined,
    'more_horiz': Icons.more_horiz_rounded,
    'work': Icons.work_outline_rounded,
    'computer': Icons.computer_outlined,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
  };

  factory CategoryEntity.fromJson(Map<String, dynamic> json) {
    return CategoryEntity(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'] ?? 'more_horiz',
      color: json['color'] ?? '#6B7280',
      isPredefined: json['is_predefined'] ?? false,
      displayOrder: json['display_order'] ?? 0,
    );
  }

  // ============================================
  // CATEGORÍAS PREDEFINIDAS (RF-15) - Fallback
  // ============================================

  /// Categorías de gastos predefinidas según RF-15
  static const List<CategoryEntity> defaultExpenseCategories = [
    CategoryEntity(id: 'def_1', name: 'Alimentación', type: 'expense', icon: 'restaurant', color: '#F59E0B', isPredefined: true, displayOrder: 1),
    CategoryEntity(id: 'def_2', name: 'Transporte', type: 'expense', icon: 'directions_car', color: '#3B82F6', isPredefined: true, displayOrder: 2),
    CategoryEntity(id: 'def_3', name: 'Ocio', type: 'expense', icon: 'sports_esports', color: '#8B5CF6', isPredefined: true, displayOrder: 3),
    CategoryEntity(id: 'def_4', name: 'Salud', type: 'expense', icon: 'local_hospital', color: '#EF4444', isPredefined: true, displayOrder: 4),
    CategoryEntity(id: 'def_5', name: 'Vivienda', type: 'expense', icon: 'home', color: '#06B6D4', isPredefined: true, displayOrder: 5),
    CategoryEntity(id: 'def_6', name: 'Servicios', type: 'expense', icon: 'phone_android', color: '#6366F1', isPredefined: true, displayOrder: 6),
    CategoryEntity(id: 'def_7', name: 'Educación', type: 'expense', icon: 'school', color: '#F97316', isPredefined: true, displayOrder: 7),
    CategoryEntity(id: 'def_8', name: 'Ropa', type: 'expense', icon: 'checkroom', color: '#EC4899', isPredefined: true, displayOrder: 8),
    CategoryEntity(id: 'def_9', name: 'Otros', type: 'expense', icon: 'more_horiz', color: '#6B7280', isPredefined: true, displayOrder: 9),
  ];

  /// Categorías de ingresos predefinidas según RF-15
  static const List<CategoryEntity> defaultIncomeCategories = [
    CategoryEntity(id: 'def_10', name: 'Salario', type: 'income', icon: 'work', color: '#22C55E', isPredefined: true, displayOrder: 1),
    CategoryEntity(id: 'def_11', name: 'Freelance', type: 'income', icon: 'computer', color: '#14B8A6', isPredefined: true, displayOrder: 2),
    CategoryEntity(id: 'def_12', name: 'Otros ingresos', type: 'income', icon: 'account_balance_wallet', color: '#64748B', isPredefined: true, displayOrder: 3),
  ];

  /// Todas las categorías predefinidas
  static List<CategoryEntity> get allDefaults => [
    ...defaultExpenseCategories,
    ...defaultIncomeCategories,
  ];

  // ============================================
  // HELPERS ESTÁTICOS - Buscar icono/color por nombre
  // ============================================

  /// Busca el icono de una categoría por nombre
  static IconData getIconForName(String categoryName) {
    final cat = allDefaults.cast<CategoryEntity?>().firstWhere(
      (c) => c!.name == categoryName,
      orElse: () => null,
    );
    return cat?.iconData ?? Icons.category_outlined;
  }

  /// Busca el color de una categoría por nombre
  static Color getColorForName(String categoryName) {
    final cat = allDefaults.cast<CategoryEntity?>().firstWhere(
      (c) => c!.name == categoryName,
      orElse: () => null,
    );
    return cat?.colorValue ?? const Color(0xFF6B7280);
  }
}
