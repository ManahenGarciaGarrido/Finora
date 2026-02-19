import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/pages/edit_transaction_page.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Página de Historial de Transacciones (RF-08)
///
/// Muestra todas las transacciones del usuario con filtros avanzados:
/// - Filtro por tipo (ingreso/gasto)
/// - Filtro por rango de fechas
/// - Filtro por categoría (selección múltiple)
/// - Filtro por método de pago
/// - Indicador visual de filtros activos
/// - Opción de limpiar todos los filtros
/// - Scroll infinito para grandes cantidades
class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // ─── Filtro básico de tipo ───────────────────────────────────────────────
  String _selectedFilter = 'Todas';

  // ─── Búsqueda ────────────────────────────────────────────────────────────
  final _searchController = TextEditingController();
  /// Texto mostrado en el campo (actualización inmediata para clear button)
  String _searchText = '';
  /// Query debounced 300 ms — usado para filtrar (RF-09, Nota Técnica)
  String _searchQuery = '';
  Timer? _debounceTimer;

  // ─── Filtros avanzados (RF-08) ───────────────────────────────────────────
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  final Set<String> _filterCategories = {};
  final Set<PaymentMethod> _filterPaymentMethods = {};

  // ─── Scroll infinito (RF-08) ─────────────────────────────────────────────
  static const int _pageSize = 20;
  int _displayCount = _pageSize;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Detecta cuando el usuario llega al final de la lista y carga más elementos
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() => _displayCount += _pageSize);
    }
  }

  /// Retorna true si hay algún filtro avanzado activo
  bool get _hasAdvancedFilters =>
      _filterDateFrom != null ||
      _filterDateTo != null ||
      _filterCategories.isNotEmpty ||
      _filterPaymentMethods.isNotEmpty;

  /// Número de filtros avanzados activos (para el badge)
  int get _activeFilterCount {
    int count = 0;
    if (_filterDateFrom != null || _filterDateTo != null) count++;
    count += _filterCategories.length;
    count += _filterPaymentMethods.length;
    return count;
  }

  /// Limpia todos los filtros activos
  void _clearAllFilters() {
    _debounceTimer?.cancel();
    setState(() {
      _selectedFilter = 'Todas';
      _searchText = '';
      _searchQuery = '';
      _searchController.clear();
      _filterDateFrom = null;
      _filterDateTo = null;
      _filterCategories.clear();
      _filterPaymentMethods.clear();
      _displayCount = _pageSize;
    });
  }

  String _formatCurrency(double amount) {
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$decPart €';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return 'Hoy';
    if (dateOnly == yesterday) return 'Ayer';
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  String _formatDateShort(DateTime date) {
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    return CategoryEntity.getIconForName(category);
  }

  Color _getCategoryColor(String category) {
    return CategoryEntity.getColorForName(category);
  }

  // ─── Fuzzy search (Nota Técnica) ─────────────────────────────────────────

  /// Distancia de Levenshtein entre dos cadenas cortas
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    final matrix = List.generate(
      s.length + 1,
      (i) => List<int>.generate(t.length + 1, (j) => 0),
    );
    for (int i = 0; i <= s.length; i++) matrix[i][0] = i;
    for (int j = 0; j <= t.length; j++) matrix[0][j] = j;
    for (int i = 1; i <= s.length; i++) {
      for (int j = 1; j <= t.length; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return matrix[s.length][t.length];
  }

  /// Comprueba si [text] contiene [pattern] con tolerancia a 1–2 errores.
  /// Palabras ≤ 2 caracteres deben coincidir exactamente.
  bool _fuzzyContains(String text, String pattern) {
    if (pattern.isEmpty) return true;
    if (text.contains(pattern)) return true;
    if (pattern.length <= 2) return false;
    final maxErrors = pattern.length <= 5 ? 1 : 2;
    for (int i = 0; i <= text.length - pattern.length + maxErrors; i++) {
      final end = (i + pattern.length + maxErrors).clamp(0, text.length);
      if (end - i < pattern.length - maxErrors) continue;
      if (_levenshtein(text.substring(i, end), pattern) <= maxErrors) {
        return true;
      }
    }
    return false;
  }

  /// Verifica si la transacción coincide con la búsqueda (exacta o fuzzy)
  bool _matchesSearch(TransactionEntity t, String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    final desc = (t.description ?? '').toLowerCase();
    final cat = t.category.toLowerCase();
    // Soporte multi-palabra: todos los tokens deben aparecer
    for (final token in q.split(' ').where((w) => w.isNotEmpty)) {
      if (!_fuzzyContains(desc, token) && !_fuzzyContains(cat, token)) {
        return false;
      }
    }
    return true;
  }

  /// Puntúa la relevancia de una transacción para la búsqueda activa (RF-09).
  /// Mayor puntuación → más relevante.
  int _searchRelevanceScore(TransactionEntity t, String query) {
    final q = query.toLowerCase();
    final desc = (t.description ?? '').toLowerCase();
    final cat = t.category.toLowerCase();
    int score = 0;
    // Descripción / comercio (mayor peso)
    if (desc == q) {
      score += 100;
    } else if (desc.startsWith(q)) {
      score += 60;
    } else if (desc.contains(q)) {
      score += 30;
    } else if (_fuzzyContains(desc, q)) {
      score += 15; // Coincidencia fuzzy, menor peso
    }
    // Categoría
    if (cat == q) {
      score += 50;
    } else if (cat.startsWith(q)) {
      score += 30;
    } else if (cat.contains(q)) {
      score += 15;
    } else if (_fuzzyContains(cat, q)) {
      score += 8; // Coincidencia fuzzy, menor peso
    }
    return score;
  }

  /// Aplica todos los filtros activos a la lista de transacciones
  List<TransactionEntity> _applyFilters(List<TransactionEntity> transactions) {
    var filtered = transactions.where((t) {
      // Filtro por tipo (ingreso/gasto/ambos)
      if (_selectedFilter == 'Gastos' && !t.isExpense) return false;
      if (_selectedFilter == 'Ingresos' && !t.isIncome) return false;

      // Filtro por búsqueda de texto con fuzzy search (RF-09 + Nota Técnica)
      if (_searchQuery.isNotEmpty && !_matchesSearch(t, _searchQuery)) {
        return false;
      }

      // Filtro por rango de fechas (RF-08)
      if (_filterDateFrom != null) {
        final from = DateTime(
          _filterDateFrom!.year,
          _filterDateFrom!.month,
          _filterDateFrom!.day,
        );
        final txDate = DateTime(t.date.year, t.date.month, t.date.day);
        if (txDate.isBefore(from)) return false;
      }
      if (_filterDateTo != null) {
        final to = DateTime(
          _filterDateTo!.year,
          _filterDateTo!.month,
          _filterDateTo!.day,
        );
        final txDate = DateTime(t.date.year, t.date.month, t.date.day);
        if (txDate.isAfter(to)) return false;
      }

      // Filtro por categoría múltiple (RF-08)
      if (_filterCategories.isNotEmpty &&
          !_filterCategories.contains(t.category)) {
        return false;
      }

      // Filtro por método de pago (RF-08)
      if (_filterPaymentMethods.isNotEmpty &&
          !_filterPaymentMethods.contains(t.paymentMethod)) {
        return false;
      }

      return true;
    }).toList();

    // Ordenar por relevancia cuando hay búsqueda activa (RF-09)
    if (_searchQuery.isNotEmpty) {
      filtered.sort((a, b) {
        final scoreA = _searchRelevanceScore(a, _searchQuery);
        final scoreB = _searchRelevanceScore(b, _searchQuery);
        if (scoreB != scoreA) return scoreB.compareTo(scoreA);
        return b.date.compareTo(
          a.date,
        ); // Igual relevancia → más reciente primero
      });
    }

    return filtered;
  }

  Map<String, List<TransactionEntity>> _groupByDate(
    List<TransactionEntity> transactions,
  ) {
    final grouped = <String, List<TransactionEntity>>{};
    for (final t in transactions) {
      final key = _formatDateGroup(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  /// Abre el panel de filtros avanzados (RF-08)
  Future<void> _showAdvancedFilters(
    List<TransactionEntity> allTransactions,
  ) async {
    // Recoger todas las categorías disponibles en las transacciones actuales
    final availableCategories =
        allTransactions.map((t) => t.category).toSet().toList()..sort();

    // Estado local del bottom sheet (se confirma al pulsar Aplicar)
    DateTime? localDateFrom = _filterDateFrom;
    DateTime? localDateTo = _filterDateTo;
    final localCategories = Set<String>.from(_filterCategories);
    final localPaymentMethods = Set<PaymentMethod>.from(_filterPaymentMethods);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.95,
            minChildSize: 0.4,
            expand: false,
            builder: (ctx, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
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
                  // Header del bottom sheet
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filtros avanzados',
                          style: AppTypography.titleMedium(),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              localDateFrom = null;
                              localDateTo = null;
                              localCategories.clear();
                              localPaymentMethods.clear();
                            });
                          },
                          child: Text(
                            'Limpiar',
                            style: AppTypography.labelMedium(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Contenido scrollable
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      children: [
                        // ── Rango de fechas ──────────────────────────────
                        Text(
                          'Rango de fechas',
                          style: AppTypography.labelMedium(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDatePickerField(
                                label: 'Desde',
                                date: localDateFrom,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate:
                                        localDateFrom ?? DateTime.now(),
                                    firstDate: DateTime(2000),
                                    lastDate: localDateTo ?? DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => localDateFrom = picked);
                                  }
                                },
                                onClear: () =>
                                    setSheetState(() => localDateFrom = null),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDatePickerField(
                                label: 'Hasta',
                                date: localDateTo,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: localDateTo ?? DateTime.now(),
                                    firstDate: localDateFrom ?? DateTime(2000),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => localDateTo = picked);
                                  }
                                },
                                onClear: () =>
                                    setSheetState(() => localDateTo = null),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Método de pago ───────────────────────────────
                        Text(
                          'Método de pago',
                          style: AppTypography.labelMedium(),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: PaymentMethod.values.map((method) {
                            final selected = localPaymentMethods.contains(
                              method,
                            );
                            return FilterChip(
                              label: Text(method.label),
                              selected: selected,
                              onSelected: (val) {
                                setSheetState(() {
                                  if (val) {
                                    localPaymentMethods.add(method);
                                  } else {
                                    localPaymentMethods.remove(method);
                                  }
                                });
                              },
                              selectedColor: AppColors.primarySoft,
                              checkmarkColor: AppColors.primary,
                              labelStyle: AppTypography.labelMedium(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondaryLight,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.gray200,
                              ),
                              backgroundColor: AppColors.white,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // ── Categorías (selección múltiple) ──────────────
                        if (availableCategories.isNotEmpty) ...[
                          Text('Categoría', style: AppTypography.labelMedium()),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: availableCategories.map((cat) {
                              final selected = localCategories.contains(cat);
                              return FilterChip(
                                avatar: Icon(
                                  CategoryEntity.getIconForName(cat),
                                  size: 16,
                                  color: selected
                                      ? AppColors.primary
                                      : CategoryEntity.getColorForName(cat),
                                ),
                                label: Text(cat),
                                selected: selected,
                                onSelected: (val) {
                                  setSheetState(() {
                                    if (val) {
                                      localCategories.add(cat);
                                    } else {
                                      localCategories.remove(cat);
                                    }
                                  });
                                },
                                selectedColor: AppColors.primarySoft,
                                checkmarkColor: AppColors.primary,
                                labelStyle: AppTypography.labelMedium(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textSecondaryLight,
                                ),
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.gray200,
                                ),
                                backgroundColor: AppColors.white,
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],
                    ),
                  ),
                  // Botón Aplicar
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      MediaQuery.of(ctx).viewInsets.bottom + 20,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterDateFrom = localDateFrom;
                            _filterDateTo = localDateTo;
                            _filterCategories
                              ..clear()
                              ..addAll(localCategories);
                            _filterPaymentMethods
                              ..clear()
                              ..addAll(localPaymentMethods);
                            _displayCount = _pageSize;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Aplicar filtros',
                          style: AppTypography.button(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: date != null ? AppColors.primarySoft : AppColors.gray100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: date != null ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.badge(
                      color: date != null
                          ? AppColors.primary
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null ? _formatDateShort(date) : 'Seleccionar',
                    style: AppTypography.labelMedium(
                      color: date != null
                          ? AppColors.primary
                          : AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              )
            else
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.gray400,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          final List<TransactionEntity> allTransactions =
              state is TransactionsLoaded ? state.transactions : [];

          return RefreshIndicator(
            onRefresh: () async {
              context.read<TransactionBloc>().add(LoadTransactions());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColors.primary,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    responsive.horizontalPadding,
                    16,
                    responsive.horizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Transacciones',
                                style: AppTypography.headlineSmall(),
                              ),
                              // Indicador de transacciones pendientes de sincronizar (RNF-15)
                              if (state is TransactionsLoaded &&
                                  state.pendingSyncCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 12,
                                          color: AppColors.warningDark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${state.pendingSyncCount}',
                                          style: AppTypography.badge(
                                            color: AppColors.warningDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              // Botón de filtros avanzados con badge de filtros activos (RF-08)
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showAdvancedFilters(allTransactions),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _hasAdvancedFilters
                                            ? AppColors.primarySoft
                                            : AppColors.gray100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _hasAdvancedFilters
                                              ? AppColors.primary
                                              : AppColors.gray200,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: _hasAdvancedFilters
                                            ? AppColors.primary
                                            : AppColors.gray400,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  // Badge con número de filtros activos (RF-08)
                                  if (_activeFilterCount > 0)
                                    Positioned(
                                      top: -6,
                                      right: -6,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(
                                            9,
                                          ),
                                          border: Border.all(
                                            color: AppColors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$_activeFilterCount',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              // Botón de nueva transacción
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/add-transaction',
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: const Icon(
                                    Icons.add_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Summary bar con datos reales
                      _buildSummaryBar(state),
                      const SizedBox(height: 16),
                      // Barra de búsqueda
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.gray200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTypography.bodyMedium(),
                          onChanged: (value) {
                            // Actualización inmediata para mostrar/ocultar clear button
                            setState(() => _searchText = value);
                            // Debounce 300 ms para lanzar el filtro (Nota Técnica RF-09)
                            _debounceTimer?.cancel();
                            _debounceTimer = Timer(
                              const Duration(milliseconds: 300),
                              () => setState(() {
                                _searchQuery = value;
                                _displayCount = _pageSize;
                              }),
                            );
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Buscar por comercio, descripción o categoría...',
                            hintStyle: AppTypography.bodyMedium(
                              color: AppColors.textTertiaryLight,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: AppColors.gray400,
                              size: 20,
                            ),
                            suffixIcon: _searchText.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.gray400,
                                    ),
                                    onPressed: () {
                                      _debounceTimer?.cancel();
                                      _searchController.clear();
                                      setState(() {
                                        _searchText = '';
                                        _searchQuery = '';
                                        _displayCount = _pageSize;
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Chips de tipo + indicador visual de filtros activos (RF-08)
                      Row(
                        children: [
                          _buildFilterChip('Todas'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Gastos'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Ingresos'),
                          const Spacer(),
                          // Botón "Limpiar filtros" cuando hay filtros activos (RF-08)
                          if (_hasAdvancedFilters)
                            GestureDetector(
                              onTap: _clearAllFilters,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.errorSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.filter_list_off_rounded,
                                      size: 14,
                                      color: AppColors.error,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Limpiar',
                                      style: AppTypography.badge(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Indicador de filtros de fechas activos (RF-08)
                      if (_filterDateFrom != null || _filterDateTo != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.date_range_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _buildActiveDateRangeLabel(),
                                style: AppTypography.badge(
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Lista de transacciones
                Expanded(
                  child: _buildTransactionList(allTransactions, responsive),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construye la etiqueta del rango de fechas activo
  String _buildActiveDateRangeLabel() {
    if (_filterDateFrom != null && _filterDateTo != null) {
      return '${_formatDateShort(_filterDateFrom!)} – ${_formatDateShort(_filterDateTo!)}';
    } else if (_filterDateFrom != null) {
      return 'Desde ${_formatDateShort(_filterDateFrom!)}';
    } else if (_filterDateTo != null) {
      return 'Hasta ${_formatDateShort(_filterDateTo!)}';
    }
    return '';
  }

  Widget _buildTransactionList(
    List<TransactionEntity> allTransactions,
    ResponsiveUtils responsive,
  ) {
    if (allTransactions.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _applyFilters(allTransactions);

    if (filtered.isEmpty) {
      return _buildEmptyFilterState();
    }

    // Scroll infinito: mostrar solo _displayCount transacciones (RF-08)
    final displayed = filtered.take(_displayCount).toList();
    final hasMore = filtered.length > _displayCount;

    // Búsqueda activa → lista plana ordenada por relevancia (RF-09)
    // Sin búsqueda → lista agrupada por fecha
    final isSearching = _searchQuery.isNotEmpty;
    final grouped = isSearching ? null : _groupByDate(displayed);
    final groupKeys = grouped?.keys.toList() ?? [];
    final listLength = isSearching
        ? displayed.length + (hasMore ? 1 : 0)
        : groupKeys.length + (hasMore ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicador de número de resultados (RF-09)
        if (isSearching)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 6,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 13,
                  color: AppColors.textTertiaryLight,
                ),
                const SizedBox(width: 5),
                Text(
                  '${filtered.length} resultado${filtered.length == 1 ? '' : 's'}',
                  style: AppTypography.badge(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
            ),
            itemCount: listLength,
            itemBuilder: (context, index) {
              final isMoreIndicator = isSearching
                  ? index == displayed.length
                  : index == groupKeys.length;
              // Indicador de "cargando más" al final (scroll infinito)
              if (isMoreIndicator && hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '${filtered.length - _displayCount} más...',
                      style: AppTypography.bodySmall(
                        color: AppColors.textTertiaryLight,
                      ),
                    ),
                  ),
                );
              }
              if (isSearching) {
                // Lista plana ordenada por relevancia (RF-09)
                return _buildTransactionItem(displayed[index]);
              } else {
                // Lista agrupada por fecha (modo normal)
                final dateLabel = groupKeys[index];
                return _buildDateGroup(dateLabel, grouped![dateLabel]!);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(TransactionState state) {
    final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
    final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
    final count = state is TransactionsLoaded ? state.transactions.length : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMiniStat(
              icon: Icons.south_west_rounded,
              label: 'Ingresos',
              value: _formatCurrency(income),
              color: AppColors.success,
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.gray200),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.north_east_rounded,
              label: 'Gastos',
              value: _formatCurrency(expenses),
              color: AppColors.error,
            ),
          ),
          Container(width: 1, height: 32, color: AppColors.gray200),
          Expanded(
            child: _buildMiniStat(
              icon: Icons.receipt_long_rounded,
              label: 'Total',
              value: '$count',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.titleSmall(color: color),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: AppTypography.labelSmall()),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;

    return GestureDetector(
      onTap: () => setState(() {
        _selectedFilter = label;
        _displayCount = _pageSize;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium(
            color: isSelected ? AppColors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildDateGroup(String dateLabel, List<TransactionEntity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
          child: Text(
            dateLabel,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        ...items.map((t) => _buildTransactionItem(t)),
      ],
    );
  }

  /// Abre la página de edición de la transacción (RF-06)
  Future<void> _openEditPage(TransactionEntity t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: t),
      ),
    );
  }

  // ─── Highlight de términos coincidentes (RF-09 criterio 6) ───────────────

  /// Construye un widget de texto que resalta las partes que coinciden con [query].
  /// Si no hay coincidencia exacta (p.ej. match fue fuzzy), muestra texto normal.
  Widget _buildHighlightedText(
    String text,
    String query, {
    TextStyle? baseStyle,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow);
    }
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;
    int matchIndex = lowerText.indexOf(lowerQuery);
    if (matchIndex == -1) {
      // Sin coincidencia exacta → texto plano (la búsqueda fue fuzzy)
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: overflow);
    }
    while (matchIndex != -1) {
      if (matchIndex > start) {
        spans.add(TextSpan(text: text.substring(start, matchIndex), style: baseStyle));
      }
      spans.add(
        TextSpan(
          text: text.substring(matchIndex, matchIndex + lowerQuery.length),
          style: (baseStyle ?? const TextStyle()).copyWith(
            backgroundColor: const Color(0xFFFFE082), // Amarillo suave
            color: const Color(0xFF333333),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      start = matchIndex + lowerQuery.length;
      matchIndex = lowerText.indexOf(lowerQuery, start);
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: baseStyle));
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget _buildTransactionItem(TransactionEntity t) {
    return Dismissible(
      key: Key(t.id ?? t.hashCode.toString()),
      direction: DismissDirection.horizontal,
      // Fondo deslizando a la derecha → Editar (RF-06)
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_rounded, color: AppColors.white),
            SizedBox(width: 6),
            Text(
              'Editar',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      // Fondo deslizando a la izquierda → Eliminar
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Eliminar',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: AppColors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe derecha → abrir edición, no descartar
          await _openEditPage(t);
          return false;
        }
        // Swipe izquierda → confirmar eliminación
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text('Eliminar'),
              ],
            ),
            content: const Text(
              '¿Eliminar esta transacción? Esta acción no se puede deshacer.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: AppColors.textSecondaryLight),
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
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        if (t.id != null) {
          context.read<TransactionBloc>().add(
            DeleteTransaction(transactionId: t.id!),
          );
        }
      },
      child: GestureDetector(
        onTap: () => _openEditPage(t),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: t.isPendingSync
                  ? AppColors.warning.withValues(alpha: 0.4)
                  : AppColors.gray100,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _getCategoryColor(t.category).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      _getCategoryIcon(t.category),
                      color: _getCategoryColor(t.category),
                      size: 20,
                    ),
                    // Indicador de sincronización pendiente (RNF-15)
                    if (t.isPendingSync)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.warning,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 8,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    // Indicador de error de sincronización (RNF-15)
                    if (t.hasSyncError)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: AppColors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.cloud_off_rounded,
                            size: 8,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHighlightedText(
                      t.description?.isNotEmpty == true
                          ? t.description!
                          : t.category,
                      _searchQuery,
                      baseStyle: AppTypography.titleSmall(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: _buildHighlightedText(
                            t.category,
                            _searchQuery,
                            baseStyle: AppTypography.bodySmall(
                              color: AppColors.textTertiaryLight,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gray100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            t.paymentMethod.label,
                            style: AppTypography.badge(
                              color: AppColors.textTertiaryLight,
                            ),
                          ),
                        ),
                        // Badge de pendiente de sync (RNF-15)
                        if (t.isPendingSync) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warningSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Pendiente',
                              style: AppTypography.badge(
                                color: AppColors.warningDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${t.isExpense ? '-' : '+'}${_formatCurrency(t.amount)}',
                    style: AppTypography.titleSmall(
                      color: t.isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(t.date),
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Sin transacciones aún', style: AppTypography.titleMedium()),
            const SizedBox(height: 8),
            Text(
              'Registra tu primera transacción\npulsando el botón +',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add-transaction'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.shadowColor(AppColors.primary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text('Añadir transacción', style: AppTypography.button()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.filter_list_off_rounded,
                size: 32,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay resultados',
              style: AppTypography.titleMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron transacciones\nque coincidan con "$_searchQuery"'
                  : 'No se encontraron transacciones\ncon los filtros seleccionados',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textTertiaryLight,
              ),
            ),
            const SizedBox(height: 16),
            // Botón de limpiar filtros desde el estado vacío (RF-08)
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.filter_list_off_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Limpiar filtros',
                      style: AppTypography.labelMedium(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
