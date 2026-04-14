import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';
import 'package:finora_frontend/shared/widgets/skeleton_loader.dart';

/// Página de gestión de categorías (RF-15, RF-16)
///
/// Muestra las categorías del usuario agrupadas por tipo (gastos e ingresos).
/// Permite crear, editar y eliminar categorías personalizadas (RF-16).
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<CategoryBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategoryCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).categoryCreatedMsg(state.category.name),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is CategoryUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                ).categoryUpdatedMsg(state.category.name),
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is CategoryDeleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).categoryDeleted),
              backgroundColor: AppColors.gray600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppLocalizations.of(context).categoriesTitle,
              style: AppTypography.headlineSmall(),
            ),
            centerTitle: false,
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textTertiaryLight,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTypography.labelLarge(),
              unselectedLabelStyle: AppTypography.labelLarge(),
              tabs: [
                Tab(text: AppLocalizations.of(context).expense),
                Tab(text: AppLocalizations.of(context).income),
              ],
            ),
          ),
          // RF-16: FAB para crear nueva categoría personalizada
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCategoryForm(context, null),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(AppLocalizations.of(context).newCategory),
          ),
          body: Builder(
            builder: (_) {
              if (state is CategoryLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: SkeletonListLoader(count: 6, cardHeight: 60),
                );
              }

              final categories = state is CategoriesLoaded
                  ? state.categories
                  : context.read<CategoryBloc>().categories;

              final expenseCats = categories.where((c) => c.isExpense).toList();
              final incomeCats = categories.where((c) => c.isIncome).toList();

              if (state is CategoryError && categories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).errorLoadingCategories,
                        style: AppTypography.titleMedium(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          context.read<CategoryBloc>().add(LoadCategories());
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(AppLocalizations.of(context).retry),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(
                    context,
                    expenseCats,
                    responsive,
                    isExpense: true,
                  ),
                  _buildCategoryList(
                    context,
                    incomeCats,
                    responsive,
                    isExpense: false,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<CategoryEntity> categories,
    ResponsiveUtils responsive, {
    required bool isExpense,
  }) {
    if (categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpense
                  ? Icons.receipt_long_outlined
                  : Icons.account_balance_wallet_outlined,
              size: 48,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 16),
            Text(
              isExpense
                  ? AppLocalizations.of(context).noCategoriesExpense
                  : AppLocalizations.of(context).noCategoriesIncome,
              style: AppTypography.titleMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _showCategoryForm(
                context,
                null,
                defaultType: isExpense ? 'expense' : 'income',
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.of(context).createFirstCategory),
            ),
          ],
        ),
      );
    }

    if (responsive.isTablet) {
      return GridView.builder(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          16,
          responsive.horizontalPadding,
          100, // Espacio para el FAB
        ),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 8,
          childAspectRatio: 3.0,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _buildCategoryCard(context, category);
        },
      );
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        16,
        responsive.horizontalPadding,
        100, // Espacio para el FAB
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, CategoryEntity category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          // Icono con color de categoría
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: category.colorValue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category.iconData,
              size: 22,
              color: category.colorValue,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, style: AppTypography.titleSmall()),
                const SizedBox(height: 2),
                Text(
                  category.isExpense
                      ? AppLocalizations.of(context).expense
                      : AppLocalizations.of(context).income,
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          // Badge para predefinidas; botones para personalizadas
          if (category.isPredefined)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                AppLocalizations.of(context).predefined,
                style: AppTypography.badge(color: AppColors.textTertiaryLight),
              ),
            )
          else ...[
            // RF-16: Editar categoría personalizada
            IconButton(
              icon: Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              onPressed: () => _showCategoryForm(context, category),
              tooltip: AppLocalizations.of(context).edit,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            // RF-16: Eliminar categoría personalizada
            IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: AppColors.error,
              ),
              onPressed: () => _confirmDelete(context, category),
              tooltip: AppLocalizations.of(context).delete,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
    );
  }

  // ── RF-16: Formulario de creación/edición ──────────────────────────────

  /// Los iconos disponibles para categorías personalizadas (RF-16)
  static const List<Map<String, dynamic>> _availableIcons = [
    {'icon': 'restaurant', 'label': 'Comida'},
    {'icon': 'directions_car', 'label': 'Coche'},
    {'icon': 'sports_esports', 'label': 'Ocio'},
    {'icon': 'local_hospital', 'label': 'Salud'},
    {'icon': 'home', 'label': 'Hogar'},
    {'icon': 'phone_android', 'label': 'Móvil'},
    {'icon': 'school', 'label': 'Estudio'},
    {'icon': 'checkroom', 'label': 'Ropa'},
    {'icon': 'more_horiz', 'label': 'Otros'},
    {'icon': 'work', 'label': 'Trabajo'},
    {'icon': 'computer', 'label': 'Tech'},
    {'icon': 'account_balance_wallet', 'label': 'Wallet'},
    {'icon': 'fitness_center', 'label': 'Gym'},
    {'icon': 'flight', 'label': 'Viaje'},
    {'icon': 'pets', 'label': 'Mascotas'},
    {'icon': 'shopping_cart', 'label': 'Compras'},
    {'icon': 'local_cafe', 'label': 'Café'},
    {'icon': 'movie', 'label': 'Cine'},
    {'icon': 'music_note', 'label': 'Música'},
    {'icon': 'celebration', 'label': 'Fiesta'},
  ];

  /// Paleta de colores para categorías personalizadas (RF-16)
  static const List<String> _availableColors = [
    '#F59E0B',
    '#EF4444',
    '#3B82F6',
    '#22C55E',
    '#8B5CF6',
    '#EC4899',
    '#06B6D4',
    '#F97316',
    '#6366F1',
    '#14B8A6',
    '#84CC16',
    '#E11D48',
    '#0EA5E9',
    '#7C3AED',
    '#10B981',
    '#F43F5E',
    '#6B7280',
    '#92400E',
    '#1D4ED8',
    '#047857',
  ];

  Future<void> _showCategoryForm(
    BuildContext context,
    CategoryEntity? existing, {
    String defaultType = 'expense',
  }) async {
    final isEditing = existing != null;
    String selectedType = existing?.type ?? defaultType;
    String selectedIcon = existing?.icon ?? 'more_horiz';
    String selectedColor = existing?.color ?? '#6B7280';
    final nameController = TextEditingController(text: existing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final s = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? s.editCategory : s.newCategory,
                          style: AppTypography.titleLarge(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                        color: AppColors.textSecondaryLight,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Body — Flexible prevents unbounded height overflow in Column(mainAxisSize: min)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Preview
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Color(
                                  int.parse(
                                    selectedColor.replaceFirst('#', '0xFF'),
                                  ),
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Color(
                                    int.parse(
                                      selectedColor.replaceFirst('#', '0xFF'),
                                    ),
                                  ).withValues(alpha: 0.4),
                                ),
                              ),
                              child: Icon(
                                CategoryEntity(
                                  id: '',
                                  name: '',
                                  type: selectedType,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                ).iconData,
                                size: 32,
                                color: Color(
                                  int.parse(
                                    selectedColor.replaceFirst('#', '0xFF'),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Nombre
                          Text(s.name, style: AppTypography.labelMedium()),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              fillColor: AppColors.cardLight,
                              hintText: 'Ej: Mascotas, Fitness...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: AppColors.cardLight,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.gray200,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return s.fieldRequired;
                              }
                              if (v.trim().length > 100) {
                                return s.nameTooLong;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Tipo (solo al crear)
                          if (!isEditing) ...[
                            Text(s.type, style: AppTypography.labelMedium()),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setSheetState(
                                      () => selectedType = 'expense',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedType == 'expense'
                                            ? AppColors.expense.withValues(
                                                alpha: 0.1,
                                              )
                                            : AppColors.cardLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selectedType == 'expense'
                                              ? AppColors.expense
                                              : AppColors.gray200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.north_east_rounded,
                                            size: 16,
                                            color: selectedType == 'expense'
                                                ? AppColors.expense
                                                : AppColors.textTertiaryLight,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.expense,
                                            style: AppTypography.labelMedium(
                                              color: selectedType == 'expense'
                                                  ? AppColors.expense
                                                  : AppColors.textTertiaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setSheetState(
                                      () => selectedType = 'income',
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: selectedType == 'income'
                                            ? AppColors.income.withValues(
                                                alpha: 0.1,
                                              )
                                            : AppColors.cardLight,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: selectedType == 'income'
                                              ? AppColors.income
                                              : AppColors.gray200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.south_west_rounded,
                                            size: 16,
                                            color: selectedType == 'income'
                                                ? AppColors.income
                                                : AppColors.textTertiaryLight,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            s.income,
                                            style: AppTypography.labelMedium(
                                              color: selectedType == 'income'
                                                  ? AppColors.income
                                                  : AppColors.textTertiaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Selector de icono (RF-16)
                          Text(s.icon, style: AppTypography.labelMedium()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableIcons.map((iconData) {
                              final iconName = iconData['icon'] as String;
                              final isSelected = selectedIcon == iconName;
                              final color = Color(
                                int.parse(
                                  selectedColor.replaceFirst('#', '0xFF'),
                                ),
                              );
                              return GestureDetector(
                                onTap: () => setSheetState(
                                  () => selectedIcon = iconName,
                                ),
                                child: Tooltip(
                                  message: iconData['label'] as String,
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.15)
                                          : AppColors.cardLight,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? color
                                            : AppColors.gray200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Icon(
                                      CategoryEntity(
                                        id: '',
                                        name: '',
                                        type: 'expense',
                                        icon: iconName,
                                        color: selectedColor,
                                      ).iconData,
                                      size: 20,
                                      color: isSelected
                                          ? color
                                          : AppColors.gray400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          // Selector de color (RF-16)
                          Text(s.color, style: AppTypography.labelMedium()),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableColors.map((hex) {
                              final isSelected = selectedColor == hex;
                              final color = Color(
                                int.parse(hex.replaceFirst('#', '0xFF')),
                              );
                              return GestureDetector(
                                onTap: () =>
                                    setSheetState(() => selectedColor = hex),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.textPrimaryLight
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color.withValues(
                                                alpha: 0.5,
                                              ),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                          // Botón guardar
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) return;
                                Navigator.pop(ctx);
                                if (isEditing) {
                                  context.read<CategoryBloc>().add(
                                    UpdateCategory(
                                      id: existing.id,
                                      name: nameController.text.trim(),
                                      icon: selectedIcon,
                                      color: selectedColor,
                                    ),
                                  );
                                } else {
                                  context.read<CategoryBloc>().add(
                                    CreateCategory(
                                      name: nameController.text.trim(),
                                      type: selectedType,
                                      icon: selectedIcon,
                                      color: selectedColor,
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: Text(
                                isEditing ? s.saveChanges : s.createCategory,
                                style: AppTypography.labelLarge(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ), // closes Flexible
              ],
            ),
          ),
        ),
      ),
    );
  }

  // RF-16: Confirmar eliminación de categoría personalizada
  Future<void> _confirmDelete(
    BuildContext context,
    CategoryEntity category,
  ) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(s.deleteCategory, style: AppTypography.titleMedium()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.deleteCategoryConfirm(category.name),
              style: AppTypography.bodyMedium(),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.warningDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.deleteCategoryWarning,
                      style: AppTypography.bodySmall(
                        color: AppColors.warningDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              s.cancel,
              style: const TextStyle(color: AppColors.textSecondaryLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CategoryBloc>().add(DeleteCategory(id: category.id));
    }
  }
}
