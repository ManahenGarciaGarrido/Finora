/// Página de Estadísticas — RF-29 + RF-30 + RNF-11
///
/// RF-29: Visualización de gastos por categoría
///  - Gráfico circular (pie chart) con porcentajes y tap para detalles
///  - Gráfico de barras comparativo por mes
///  - Colores consistentes con categorías
///  - Filtro por período (mes actual, 3 meses, 6 meses, año)
///  - Animaciones fluidas al cargar/cambiar
///
/// RF-30: Gráfico de evolución temporal
///  - Líneas múltiples: ingresos, gastos, balance
///  - Selector de período (3/6/12 meses, todo)
///  - Tooltips con valores exactos al pulsar
///  - Zoom interactivo (pellizco para ampliar, botón de reset)
///  - Identificación de tendencias (media móvil)
///  - Leyenda clara y colores distintivos
///
/// RNF-11: Accesibilidad WCAG 2.1 AA
///  - Semantics en todos los gráficos y elementos interactivos
///  - Labels descriptivos para lectores de pantalla
///  - Tamaños mínimos de tap targets (44x44 pts)
library;

import 'dart:math' as math;
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../../core/services/currency_service.dart';

// ─── Período de filtro ────────────────────────────────────────────────────────

enum StatsPeriod {
  currentMonth,
  threeMonths,
  sixMonths,
  year,
  all;

  String getLabel(AppLocalizations s) {
    switch (this) {
      case StatsPeriod.currentMonth:
        return s.thisMonth;
      case StatsPeriod.threeMonths:
        return s.threeMonths;
      case StatsPeriod.sixMonths:
        return s.sixMonths;
      case StatsPeriod.year:
        return s.yearPeriod;
      case StatsPeriod.all:
        return s.all;
    }
  }
}

// ─── Helpers de formato ───────────────────────────────────────────────────────

String _fmtCurrency(double amount) => CurrencyService().format(amount);

String _fmtCompact(double amount) => CurrencyService().formatCompact(amount);

const _months = [
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

// ─── Cálculos de datos ────────────────────────────────────────────────────────

List<TransactionEntity> _filterByPeriod(
  List<TransactionEntity> txs,
  StatsPeriod period,
) {
  final now = DateTime.now();
  switch (period) {
    case StatsPeriod.currentMonth:
      final cut = DateTime(now.year, now.month, 1);
      return txs.where((t) => !t.date.isBefore(cut)).toList();
    case StatsPeriod.threeMonths:
      final cut = DateTime(now.year, now.month - 2, 1);
      return txs.where((t) => !t.date.isBefore(cut)).toList();
    case StatsPeriod.sixMonths:
      final cut = DateTime(now.year, now.month - 5, 1);
      return txs.where((t) => !t.date.isBefore(cut)).toList();
    case StatsPeriod.year:
      final cut = DateTime(now.year - 1, now.month, 1);
      return txs.where((t) => !t.date.isBefore(cut)).toList();
    case StatsPeriod.all:
      return txs;
  }
}

String _getTranslatedCategory(BuildContext context, String categoryKey) {
  final s = AppLocalizations.of(context);

  switch (categoryKey.toLowerCase()) {
    case 'alimentación':
      return s.nutrition;
    case 'transporte':
      return s.transport;
    case 'ocio':
      return s.leisure;
    case 'salud':
      return s.health;
    case 'vivienda':
      return s.housing;
    case 'servicios':
      return s.services;
    case 'educación':
      return s.education;
    case 'ropa':
      return s.clothing;
    case 'otros':
      return s.other;
    case 'ahorro':
      return s.saving;
    default:
      return categoryKey;
  }
}

Map<String, double> _expensesByCategory(List<TransactionEntity> txs) {
  final map = <String, double>{};
  for (final t in txs) {
    if (t.isExpense) map[t.category] = (map[t.category] ?? 0) + t.amount;
  }
  final sorted = map.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return Map.fromEntries(sorted);
}

class _MonthData {
  final DateTime month;
  final double income;
  final double expenses;

  const _MonthData({
    required this.month,
    required this.income,
    required this.expenses,
  });

  double get balance => income - expenses;

  _MonthData add({double? income, double? expenses}) => _MonthData(
    month: month,
    income: this.income + (income ?? 0),
    expenses: this.expenses + (expenses ?? 0),
  );
}

List<_MonthData> _buildMonthlyData(List<TransactionEntity> txs) {
  final map = <String, _MonthData>{};
  for (final t in txs) {
    final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
    final base =
        map[key] ??
        _MonthData(
          month: DateTime(t.date.year, t.date.month),
          income: 0,
          expenses: 0,
        );
    if (t.isIncome) {
      map[key] = base.add(income: t.amount);
    } else {
      map[key] = base.add(expenses: t.amount);
    }
  }
  final sorted = map.values.toList()
    ..sort((a, b) => a.month.compareTo(b.month));
  return sorted;
}

// ─── Página principal ─────────────────────────────────────────────────────────

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage>
    with SingleTickerProviderStateMixin {
  StatsPeriod _period = StatsPeriod.currentMonth;
  int? _touchedPieIndex;
  late AnimationController _animController;
  late Animation<double> _animValue;

  // RF-30: Zoom interactivo en gráfico de evolución temporal (HU-16)
  final TransformationController _lineZoomController =
      TransformationController();
  bool _lineZoomed = false;

  // ─── Datos de analytics del servidor (evita el límite de 100 txs paginadas) ─
  List<_MonthData>? _serverMonthly;
  Map<String, double>? _serverCategories;

  /// Devuelve los meses a pedir según el período seleccionado.
  /// 0 = sin límite (todo el historial).
  int _monthsForPeriod(StatsPeriod p) {
    switch (p) {
      case StatsPeriod.currentMonth:
        return 1;
      case StatsPeriod.threeMonths:
        return 3;
      case StatsPeriod.sixMonths:
        return 6;
      case StatsPeriod.year:
        return 12;
      case StatsPeriod.all:
        return 0;
    }
  }

  Future<void> _fetchAnalytics() async {
    final months = _monthsForPeriod(_period);
    try {
      final resp = await di.sl<ApiClient>().get(
        ApiEndpoints.transactionAnalytics,
        queryParameters: {'months': months},
      );
      final data = resp.data as Map<String, dynamic>;

      // Construir _MonthData desde la respuesta
      final rawMonthly = (data['monthly'] as List?) ?? [];
      final monthly = rawMonthly.map((r) {
        final parts = (r['month'] as String).split('-');
        return _MonthData(
          month: DateTime(int.parse(parts[0]), int.parse(parts[1])),
          income: (r['income'] as num?)?.toDouble() ?? 0.0,
          expenses: (r['expenses'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      // Construir mapa de categorías
      final rawCats = (data['categories'] as List?) ?? [];
      final cats = <String, double>{};
      for (final r in rawCats) {
        cats[r['category'] as String] = (r['total'] as num?)?.toDouble() ?? 0.0;
      }

      if (mounted) {
        setState(() {
          _serverMonthly = monthly;
          _serverCategories = cats;
        });
      }
    } catch (_) {
      // Silencioso — fallback a datos locales
    }
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _animValue = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
    _lineZoomController.addListener(() {
      final zoomed = _lineZoomController.value != Matrix4.identity();
      if (zoomed != _lineZoomed) setState(() => _lineZoomed = zoomed);
    });
    _fetchAnalytics();
  }

  @override
  void dispose() {
    _animController.dispose();
    _lineZoomController.dispose();
    super.dispose();
  }

  void _resetLineZoom() {
    _lineZoomController.value = Matrix4.identity();
  }

  void _onPeriodChanged(StatsPeriod p) {
    if (p == _period) return;
    setState(() {
      _period = p;
      _touchedPieIndex = null;
      _serverMonthly = null;
      _serverCategories = null;
    });
    _animController.reset();
    _animController.forward();
    _fetchAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<TransactionBloc>().add(LoadTransactions());
          setState(() {
            _serverMonthly = null;
            _serverCategories = null;
          });
          await _fetchAnalytics();
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  0,
                ),
                child: Text(s.statistics, style: AppTypography.headlineSmall()),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildPeriodFilter(s),
              ),
            ),
            SliverToBoxAdapter(
              child: BlocBuilder<TransactionBloc, TransactionState>(
                builder: (context, state) {
                  // Para el período actual (este mes) usamos txs locales;
                  // para el resto usamos datos del servidor que tienen el historial completo.
                  final allTxs = state is TransactionsLoaded
                      ? state.transactions
                      : context.read<TransactionBloc>().transactions;
                  final txs = _filterByPeriod(allTxs, _period);

                  // Datos mensuales: servidor si disponibles, local como fallback
                  final monthlyData = _serverMonthly ?? _buildMonthlyData(txs);

                  // Categorías: servidor si disponibles, local como fallback
                  final catExpenses =
                      _serverCategories ?? _expensesByCategory(txs);

                  // Totales: sumar desde datos del servidor cuando están disponibles
                  final totalIncome = _serverMonthly != null
                      ? _serverMonthly!.fold(0.0, (s, d) => s + d.income)
                      : txs
                            .where((t) => t.isIncome)
                            .fold(0.0, (s, t) => s + t.amount);
                  final totalExpenses = _serverCategories != null
                      ? _serverCategories!.values.fold(0.0, (s, v) => s + v)
                      : txs
                            .where((t) => t.isExpense)
                            .fold(0.0, (s, t) => s + t.amount);

                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          responsive.horizontalPadding,
                          16,
                          responsive.horizontalPadding,
                          0,
                        ),
                        child: _buildSummaryCards(
                          totalIncome,
                          totalExpenses,
                          txs.length,
                          s,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          responsive.horizontalPadding,
                          12,
                          responsive.horizontalPadding,
                          0,
                        ),
                        child: _buildNetBalanceCard(
                          totalIncome,
                          totalExpenses,
                          s,
                        ),
                      ),
                      if (catExpenses.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            responsive.horizontalPadding,
                            20,
                            responsive.horizontalPadding,
                            0,
                          ),
                          child: _buildPieChartCard(
                            catExpenses,
                            totalExpenses,
                            context,
                          ),
                        ),
                      if (monthlyData.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            responsive.horizontalPadding,
                            16,
                            responsive.horizontalPadding,
                            0,
                          ),
                          child: _buildBarChartCard(monthlyData, context),
                        ),
                      if (monthlyData.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            responsive.horizontalPadding,
                            16,
                            responsive.horizontalPadding,
                            0,
                          ),
                          child: _buildLineChartCard(monthlyData, context),
                        ),
                      if (txs.isEmpty)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            responsive.horizontalPadding,
                            20,
                            responsive.horizontalPadding,
                            0,
                          ),
                          child: _buildEmptyState(),
                        ),
                      SizedBox(height: responsive.hp(12)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filtro de período ───────────────────────────────────────────────────────

  Widget _buildPeriodFilter(AppLocalizations s) {
    return Semantics(
      label: 'Filtro de período para estadísticas',
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: StatsPeriod.values.map((p) {
            final isSel = p == _period;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Semantics(
                label: '${s.period} ${p.getLabel(s)}',
                selected: isSel,
                button: true,
                child: GestureDetector(
                  onTap: () => _onPeriodChanged(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.gray200,
                      ),
                    ),
                    child: Text(
                      p.getLabel(s),
                      style: AppTypography.labelSmall(
                        color: isSel
                            ? AppColors.white
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Resumen ─────────────────────────────────────────────────────────────────

  Widget _buildSummaryCards(
    double income,
    double expenses,
    int count,
    AppLocalizations s,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: s.income,
            amount: income,
            icon: Icons.south_west_rounded,
            color: AppColors.success,
            count: count,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: s.expenses,
            amount: expenses,
            icon: Icons.north_east_rounded,
            color: AppColors.error,
            count: count,
          ),
        ),
      ],
    );
  }

  Widget _buildNetBalanceCard(
    double income,
    double expenses,
    AppLocalizations s,
  ) {
    final balance = income - expenses;
    final isPos = balance >= 0;
    return Semantics(
      label: '${s.netBalance} ${_fmtCurrency(balance)}',
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: isPos ? AppColors.successGradient : null,
          color: isPos ? null : AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.netBalance,
                    style: AppTypography.labelMedium(
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmtCurrency(balance),
                    style: AppTypography.moneyMedium(color: AppColors.white),
                  ),
                ],
              ),
            ),
            if (income > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${s.saving} ${(((income - expenses) / income) * 100).clamp(0.0, 100.0).toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall(color: AppColors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── RF-29: Pie chart ────────────────────────────────────────────────────────

  Widget _buildPieChartCard(
    Map<String, double> catExpenses,
    double total,
    BuildContext context,
  ) {
    final s = AppLocalizations.of(context);
    final entries = catExpenses.entries.toList();
    final colors = entries
        .map((e) => CategoryEntity.getColorForName(e.key))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.spendingByCategory, style: AppTypography.titleMedium()),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _fmtCurrency(total),
                  style: AppTypography.titleSmall(color: AppColors.error),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Donut chart — centered, fixed height, no side legend
          Semantics(
            label:
                'Gráfico circular de distribución de gastos por categoría. '
                'Toca un segmento para ver el detalle.',
            child: AnimatedBuilder(
              animation: _animValue,
              builder: (_, __) => SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, resp) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  resp?.touchedSection == null) {
                                _touchedPieIndex = null;
                              } else {
                                _touchedPieIndex =
                                    resp!.touchedSection!.touchedSectionIndex;
                              }
                            });
                          },
                        ),
                        startDegreeOffset: -90,
                        sectionsSpace: 2,
                        centerSpaceRadius: 52,
                        sections: entries.asMap().entries.map((e) {
                          final idx = e.key;
                          final cat = e.value;
                          final isTouched = _touchedPieIndex == idx;
                          return PieChartSectionData(
                            value: cat.value * _animValue.value,
                            color: isTouched
                                ? colors[idx]
                                : colors[idx].withValues(alpha: 0.82),
                            radius: isTouched ? 70 : 58,
                            title: '',
                          );
                        }).toList(),
                      ),
                    ),
                    // Center label
                    if (_touchedPieIndex != null &&
                        _touchedPieIndex! >= 0 &&
                        _touchedPieIndex! < entries.length)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(entries[_touchedPieIndex!].value / total * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colors[_touchedPieIndex!],
                            ),
                          ),
                          Text(
                            _fmtCurrency(entries[_touchedPieIndex!].value),
                            style: AppTypography.labelSmall(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${entries.length}',
                            style: AppTypography.titleLarge(
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            s.category,
                            style: AppTypography.labelSmall(
                              color: AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend as Wrap — never overflows
          _buildPieLegend(entries, colors, total),
          if (_touchedPieIndex != null &&
              _touchedPieIndex! >= 0 &&
              _touchedPieIndex! < entries.length) ...[
            const SizedBox(height: 12),
            _buildDetailBadge(
              entries[_touchedPieIndex!],
              colors[_touchedPieIndex!],
              total,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPieLegend(
    List<MapEntry<String, double>> entries,
    List<Color> colors,
    double total,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.asMap().entries.map((e) {
        final idx = e.key;
        final cat = e.value;
        final pct = total > 0 ? (cat.value / total * 100) : 0.0;
        final isSel = _touchedPieIndex == idx;

        return GestureDetector(
          onTap: () => setState(() {
            _touchedPieIndex = _touchedPieIndex == idx ? null : idx;
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSel
                  ? colors[idx].withValues(alpha: 0.14)
                  : colors[idx].withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel
                    ? colors[idx].withValues(alpha: 0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors[idx],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _getTranslatedCategory(context, cat.key),
                  style: AppTypography.bodySmall(
                    color: isSel
                        ? AppColors.textPrimaryLight
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: AppTypography.labelSmall(
                    color: isSel ? colors[idx] : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailBadge(
    MapEntry<String, double> cat,
    Color color,
    double total,
  ) {
    final pct = total > 0 ? (cat.value / total * 100) : 0.0;
    return AnimatedOpacity(
      opacity: 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat.key,
                style: AppTypography.titleSmall(color: color),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _fmtCurrency(cat.value),
                  style: AppTypography.titleSmall(color: color),
                ),
                Text(
                  '${pct.toStringAsFixed(1)}% del total',
                  style: AppTypography.badge(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── RF-29: Bar chart comparativo mensual ────────────────────────────────────

  Widget _buildBarChartCard(List<_MonthData> months, BuildContext context) {
    final s = AppLocalizations.of(context);
    final maxVal = months.fold(
      0.0,
      (m, d) => math.max(m, math.max(d.income, d.expenses)),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.monthlyComparative, style: AppTypography.titleMedium()),
              Row(
                children: [
                  _dot(AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    s.inc,
                    style: AppTypography.badge(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _dot(AppColors.error),
                  const SizedBox(width: 4),
                  Text(
                    s.exp,
                    style: AppTypography.badge(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'Gráfico de barras comparativo de ingresos y gastos por mes',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartH = (constraints.maxWidth * 0.45).clamp(
                  140.0,
                  220.0,
                );
                final labelSize = constraints.maxWidth < 340 ? 38.0 : 48.0;
                final barW = constraints.maxWidth < 340 ? 7.0 : 9.0;
                return SizedBox(
                  height: chartH,
                  child: AnimatedBuilder(
                    animation: _animValue,
                    builder: (_, __) => BarChart(
                      BarChartData(
                        maxY: maxVal > 0 ? maxVal * 1.25 : 100,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          horizontalInterval: maxVal > 0 ? maxVal / 4 : 25,
                          getDrawingHorizontalLine: (_) =>
                              FlLine(color: AppColors.gray100, strokeWidth: 1),
                          drawVerticalLine: false,
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: labelSize,
                              getTitlesWidget: (val, _) => Text(
                                _fmtCompact(val),
                                style: AppTypography.badge(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt();
                                if (idx < 0 || idx >= months.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _months[months[idx].month.month - 1],
                                    style: AppTypography.badge(
                                      color: AppColors.textTertiaryLight,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => AppColors.textPrimaryLight
                                .withValues(alpha: 0.9),
                            tooltipRoundedRadius: 8,
                            getTooltipItem: (group, _, rod, rodIdx) {
                              final d = months[group.x.toInt()];
                              final label = rodIdx == 0
                                  ? s.incomes
                                  : s.expenses;
                              return BarTooltipItem(
                                '${_months[d.month.month - 1]} ${d.month.year}\n'
                                '$label: ${_fmtCurrency(rod.toY)}',
                                AppTypography.badge(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        barGroups: months.asMap().entries.map((e) {
                          final idx = e.key;
                          final d = e.value;
                          return BarChartGroupData(
                            x: idx,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: d.income * _animValue.value,
                                color: AppColors.success,
                                width: barW,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                              BarChartRodData(
                                toY: d.expenses * _animValue.value,
                                color: AppColors.error,
                                width: barW,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── RF-30: Gráfico de líneas de evolución temporal ───────────────────────────

  Widget _buildLineChartCard(List<_MonthData> months, BuildContext context) {
    final s = AppLocalizations.of(context);
    double minY = 0;
    double maxY = 0;
    for (final d in months) {
      maxY = math.max(maxY, math.max(d.income, d.expenses));
      minY = math.min(minY, d.balance);
    }
    final range = maxY - minY;
    maxY = maxY + range * 0.15;
    if (minY < 0) minY = minY - range * 0.05;

    // Media móvil de gastos (tendencia)
    double movingAvg(int i) {
      final window = months.sublist(math.max(0, i - 2), i + 1);
      return window.fold(0.0, (s, d) => s + d.expenses) / window.length;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.temporalEvolution, style: AppTypography.titleMedium()),
          const SizedBox(height: 8),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _legendLine(AppColors.success, s.incomes),
              _legendLine(AppColors.error, s.expenses),
              _legendLine(AppColors.primary, s.balance),
              if (months.length >= 2)
                _legendDash(AppColors.warning, s.spendingTrend),
            ],
          ),
          const SizedBox(height: 16),
          // RF-30 / HU-16: Indicador y botón de zoom interactivo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.pinch_rounded, color: AppColors.gray400, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    s.pinchToZoom,
                    style: AppTypography.labelSmall(color: AppColors.gray400),
                  ),
                ],
              ),
              if (_lineZoomed)
                Semantics(
                  button: true,
                  label: 'Restablecer zoom al estado original',
                  child: TextButton.icon(
                    onPressed: _resetLineZoom,
                    icon: const Icon(Icons.zoom_out_map_rounded, size: 16),
                    label: Text(s.reset),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: const Size(44, 36),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label:
                'Gráfico de líneas de evolución temporal. '
                'Usa pellizco para ampliar. '
                'Toca un punto para ver los valores exactos.',
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartH = (constraints.maxWidth * 0.55).clamp(
                  160.0,
                  260.0,
                );
                final labelSize = constraints.maxWidth < 340 ? 40.0 : 50.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: chartH,
                    child: InteractiveViewer(
                      transformationController: _lineZoomController,
                      minScale: 1.0,
                      maxScale: 4.0,
                      scaleEnabled: true,
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      child: AnimatedBuilder(
                        animation: _animValue,
                        builder: (_, __) => LineChart(
                          LineChartData(
                            minY: minY,
                            maxY: maxY > 0 ? maxY : 100,
                            clipData: const FlClipData.all(),
                            gridData: FlGridData(
                              show: true,
                              getDrawingHorizontalLine: (_) => FlLine(
                                color: AppColors.gray100,
                                strokeWidth: 1,
                              ),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: labelSize,
                                  interval: maxY > 0 ? (maxY - minY) / 4 : 25,
                                  getTitlesWidget: (val, _) => Text(
                                    _fmtCompact(val),
                                    style: AppTypography.badge(
                                      color: AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: math
                                      .max(1, months.length / 6)
                                      .floor()
                                      .toDouble(),
                                  getTitlesWidget: (val, _) {
                                    final idx = val.toInt();
                                    if (idx < 0 || idx >= months.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _months[months[idx].month.month - 1],
                                        style: AppTypography.badge(
                                          color: AppColors.textTertiaryLight,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) => AppColors
                                    .textPrimaryLight
                                    .withValues(alpha: 0.92),
                                tooltipRoundedRadius: 8,
                                getTooltipItems: (spots) {
                                  final labels = [
                                    'Ingresos',
                                    'Gastos',
                                    'Balance',
                                    'Tendencia',
                                  ];
                                  return spots.map((spot) {
                                    final lbl = spot.barIndex < labels.length
                                        ? labels[spot.barIndex]
                                        : '';
                                    return LineTooltipItem(
                                      '$lbl\n${_fmtCurrency(spot.y)}',
                                      AppTypography.badge(color: Colors.white),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            lineBarsData: [
                              _lineSeries(
                                months
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.income * _animValue.value,
                                      ),
                                    )
                                    .toList(),
                                AppColors.success,
                                isCurved: true,
                                showArea: true,
                              ),
                              _lineSeries(
                                months
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.expenses * _animValue.value,
                                      ),
                                    )
                                    .toList(),
                                AppColors.error,
                                isCurved: true,
                                showArea: true,
                              ),
                              _lineSeries(
                                months
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => FlSpot(
                                        e.key.toDouble(),
                                        e.value.balance * _animValue.value,
                                      ),
                                    )
                                    .toList(),
                                AppColors.primary,
                                isCurved: false,
                                showDots: true,
                              ),
                              if (months.length >= 2)
                                _lineSeries(
                                  months
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => FlSpot(
                                          e.key.toDouble(),
                                          movingAvg(e.key) * _animValue.value,
                                        ),
                                      )
                                      .toList(),
                                  AppColors.warning,
                                  isCurved: true,
                                  isDashed: true,
                                ),
                            ],
                          ),
                        ),
                      ), // closes AnimatedBuilder
                    ), // closes InteractiveViewer
                  ), // closes SizedBox(height:chartH)
                ); // closes ClipRRect — ends return statement
              },
            ), // closes LayoutBuilder
          ), // closes Semantics
        ],
      ),
    );
  }

  LineChartBarData _lineSeries(
    List<FlSpot> spots,
    Color color, {
    bool isCurved = true,
    bool isDashed = false,
    bool showArea = false,
    bool showDots = false,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dashArray: isDashed ? [6, 4] : null,
      dotData: FlDotData(
        show: showDots,
        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: showArea,
        color: color.withValues(alpha: 0.06),
      ),
    );
  }

  // ── Estado vacío ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.bar_chart_rounded,
            size: 48,
            color: AppColors.gray300,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin datos para este período',
            style: AppTypography.titleMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra transacciones o elige un período diferente.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
          ),
        ],
      ),
    );
  }

  // ── Helpers visuales ────────────────────────────────────────────────────────

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _legendLine(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.badge(color: AppColors.textTertiaryLight),
        ),
      ],
    );
  }

  Widget _legendDash(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(
          3,
          (_) => Container(
            width: 4,
            height: 2,
            margin: const EdgeInsets.only(right: 2),
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.badge(color: AppColors.textTertiaryLight),
        ),
      ],
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final int count;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title: ${_fmtCurrency(amount)}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gray100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$count mov.',
                    style: AppTypography.badge(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _fmtCurrency(amount),
              style: AppTypography.titleMedium(color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
