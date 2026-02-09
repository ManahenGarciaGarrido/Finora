import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Página de Estadísticas
///
/// Muestra estadísticas reales calculadas desde TransactionBloc.
/// Las funciones avanzadas (gráficos de evolución, predicciones)
/// están marcadas como "En desarrollo".
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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

  String _currentMonthLabel() {
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
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<TransactionBloc>().add(LoadTransactions());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estadísticas', style: AppTypography.headlineSmall()),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentMonthLabel(),
                            style: AppTypography.labelSmall(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Resumen con datos reales
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  20,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildRealSummaryCards(context),
              ),
            ),

            // Balance neto
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  16,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildNetBalanceCard(context),
              ),
            ),

            // Distribución por categorías con datos reales
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  20,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildCategoryBreakdown(context),
              ),
            ),

            // Top categorías de gasto (datos reales)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  20,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildTopCategories(context),
              ),
            ),

            // Gráfico evolución mensual (en desarrollo)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  20,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildDevelopmentPlaceholder(
                  title: 'Evolución mensual',
                  subtitle:
                      'Gráfico de tendencia de ingresos y gastos a lo largo del tiempo',
                  icon: Icons.show_chart_rounded,
                  height: 180,
                ),
              ),
            ),

            // Predicciones (en desarrollo)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.horizontalPadding,
                  20,
                  responsive.horizontalPadding,
                  0,
                ),
                child: _buildDevelopmentPlaceholder(
                  title: 'Predicciones de gasto',
                  subtitle:
                      'Estimación de gastos futuros basada en tu historial',
                  icon: Icons.auto_graph_rounded,
                  height: 140,
                ),
              ),
            ),

            SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
          ],
        ),
      ),
    );
  }

  Widget _buildRealSummaryCards(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded
            ? state.totalExpenses
            : 0.0;

        return Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Ingresos',
                amount: _formatCurrency(income),
                icon: Icons.south_west_rounded,
                color: AppColors.success,
                count: state is TransactionsLoaded
                    ? state.transactions.where((t) => t.isIncome).length
                    : 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Gastos',
                amount: _formatCurrency(expenses),
                icon: Icons.north_east_rounded,
                color: AppColors.error,
                count: state is TransactionsLoaded
                    ? state.transactions.where((t) => t.isExpense).length
                    : 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: AppTypography.titleMedium(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNetBalanceCard(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded
            ? state.totalExpenses
            : 0.0;
        final balance = income - expenses;
        final isPositive = balance >= 0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: isPositive ? AppColors.successGradient : null,
            color: isPositive ? null : AppColors.error,
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
                  isPositive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
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
                      'Balance neto',
                      style: AppTypography.labelMedium(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(balance),
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
                    income > 0
                        ? 'Ahorras ${(((income - expenses) / income) * 100).clamp(0, 100).toStringAsFixed(0)}%'
                        : '0%',
                    style: AppTypography.labelSmall(color: AppColors.white),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final bloc = context.read<TransactionBloc>();
        final categories = bloc.expensesByCategory;
        final totalExpenses = bloc.totalExpenses;

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
              Text(
                'Distribución de gastos',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                _buildEmptyChartMessage()
              else
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(180, 180),
                          painter: _DonutChartPainter(
                            categories: categories,
                            total: totalExpenses,
                            colorMap: {
                              for (final key in categories.keys)
                                key: CategoryEntity.getColorForName(key),
                            },
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatCurrency(totalExpenses),
                              style: AppTypography.titleMedium(),
                            ),
                            Text(
                              'total gastos',
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
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...categories.entries.map((cat) {
                  final pct = totalExpenses > 0
                      ? (cat.value / totalExpenses * 100)
                      : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: CategoryEntity.getColorForName(cat.key),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.key,
                            style: AppTypography.bodySmall(),
                          ),
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: AppTypography.bodySmall(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatCurrency(cat.value),
                          style: AppTypography.titleSmall(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyChartMessage() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.donut_large_rounded,
              size: 32,
              color: AppColors.gray300,
            ),
            const SizedBox(height: 8),
            Text(
              'Registra gastos para ver la distribución',
              style: AppTypography.bodySmall(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final bloc = context.read<TransactionBloc>();
        final categories = bloc.expensesByCategory;
        final totalExpenses = bloc.totalExpenses;

        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        // Sort by amount descending
        final sorted = categories.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = sorted.take(5).toList();

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
              Text(
                'Top categorías de gasto',
                style: AppTypography.titleMedium(),
              ),
              const SizedBox(height: 16),
              ...top.asMap().entries.map((entry) {
                final i = entry.key;
                final cat = entry.value;
                final progress = totalExpenses > 0
                    ? cat.value / totalExpenses
                    : 0.0;
                final color = CategoryEntity.getColorForName(cat.key);

                return Padding(
                  padding: EdgeInsets.only(bottom: i < top.length - 1 ? 14 : 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    cat.key,
                                    style: AppTypography.bodySmall(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: AppTypography.bodySmall(
                                  color: AppColors.textTertiaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatCurrency(cat.value),
                                style: AppTypography.titleSmall(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: color.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDevelopmentPlaceholder({
    required String title,
    required String subtitle,
    required IconData icon,
    required double height,
  }) {
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
              Text(title, style: AppTypography.titleMedium()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.construction_rounded,
                      size: 10,
                      color: AppColors.warningDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'En desarrollo',
                      style: AppTypography.badge(color: AppColors.warningDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: AppColors.gray300),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disponible próximamente',
                    style: AppTypography.labelSmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter para gráfico de dona
class _DonutChartPainter extends CustomPainter {
  final Map<String, double> categories;
  final Map<String, Color> colorMap;
  final double total;

  _DonutChartPainter({
    required this.categories,
    required this.total,
    required this.colorMap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 24.0;
    const gap = 0.04;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    var startAngle = -math.pi / 2;

    for (final entry in categories.entries) {
      final sweepAngle = (entry.value / total) * 2 * math.pi;
      paint.color = colorMap[entry.key] ?? const Color(0xFF6B7280);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - gap,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.categories != categories;
  }
}
