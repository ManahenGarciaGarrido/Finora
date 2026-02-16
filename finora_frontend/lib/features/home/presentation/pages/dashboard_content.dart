import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import '../../../transactions/presentation/bloc/transaction_state.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/pages/edit_transaction_page.dart';
import '../../../categories/domain/entities/category_entity.dart';

/// Contenido del Dashboard principal
class DashboardContent extends StatefulWidget {
  /// Callback para navegar a la pestaña de Transacciones desde el dashboard
  final VoidCallback? onNavigateToTransactions;

  const DashboardContent({super.key, this.onNavigateToTransactions});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  bool _balanceVisible = true;

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

  String _getUserFirstName(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      final name = authState.user.name;
      return name.split(' ').first;
    }
    return 'Usuario';
  }

  String _getUserInitials(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      final parts = authState.user.name.split(' ');
      if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (context) => _buildMobileLayout(context),
      tablet: (context) => _buildTabletLayout(context),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final hp = responsive.horizontalPadding;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<TransactionBloc>().add(
            LoadTransactions(),
          );
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hp),
                child: _buildBalanceCard(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hp, 24, hp, 0),
                child: _buildQuickActions(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hp, 28, hp, 12),
                child: _buildSectionHeader('Últimas transacciones', onTap: widget.onNavigateToTransactions),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: hp),
              sliver: _buildTransactionsList(context),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hp, 28, hp, 0),
                child: _buildSpendingChart(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(hp, 20, hp, 0),
                child: _buildMonthlyOverview(context),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final hp = responsive.horizontalPadding;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: EdgeInsets.all(hp),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        _buildBalanceCard(context),
                        const SizedBox(height: 24),
                        _buildQuickActions(context),
                        const SizedBox(height: 24),
                        _buildSpendingChart(context),
                        const SizedBox(height: 24),
                        _buildMonthlyOverview(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildSectionHeader('Últimas transacciones', onTap: widget.onNavigateToTransactions),
                        const SizedBox(height: 12),
                        _buildTransactionsColumn(context),
                      ],
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

  // ============================================
  // HEADER
  // ============================================
  Widget _buildHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding, 16, responsive.horizontalPadding, 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Hola, ${_getUserFirstName(context)}!',
                  style: AppTypography.headlineSmall(),
                ),
                const SizedBox(height: 2),
                Text(
                  _getGreetingMessage(),
                  style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: IconButton(
              icon: const Badge(
                smallSize: 8,
                backgroundColor: AppColors.error,
                child: Icon(Icons.notifications_none_rounded, size: 22),
              ),
              onPressed: () {},
              color: AppColors.textPrimaryLight,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _getUserInitials(context),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 20) return 'Buenas tardes';
    return 'Buenas noches';
  }

  // ============================================
  // BALANCE CARD
  // ============================================
  Widget _buildBalanceCard(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final double income = state is TransactionsLoaded ? state.totalIncome : 0;
        final double expenses = state is TransactionsLoaded ? state.totalExpenses : 0;
        final double balance = income - expenses;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Balance total',
                    style: AppTypography.labelMedium(
                      color: AppColors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _balanceVisible = !_balanceVisible),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _balanceVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AppColors.white.withValues(alpha: 0.8),
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _balanceVisible ? _formatCurrency(balance) : '••••••',
                  key: ValueKey(_balanceVisible ? 'v' : 'h'),
                  style: AppTypography.moneyLarge(color: AppColors.white),
                ),
              ),
              if (income == 0 && expenses == 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Registra tu primera transacción para ver tu balance',
                    style: AppTypography.labelSmall(color: AppColors.white),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildBalanceIndicator(
                      icon: Icons.south_west_rounded,
                      label: 'Ingresos',
                      amount: _balanceVisible ? _formatCurrency(income) : '••••',
                      color: AppColors.successLight,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.white.withValues(alpha: 0.15),
                    ),
                    _buildBalanceIndicator(
                      icon: Icons.north_east_rounded,
                      label: 'Gastos',
                      amount: _balanceVisible ? _formatCurrency(expenses) : '••••',
                      color: AppColors.errorLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBalanceIndicator({
    required IconData icon,
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  amount,
                  style: AppTypography.titleSmall(color: AppColors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // QUICK ACTIONS
  // ============================================
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Icons.add_rounded,
          label: 'Añadir',
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/add-transaction'),
        ),
        _buildActionButton(
          icon: Icons.swap_horiz_rounded,
          label: 'Transferir',
          color: AppColors.secondary,
        ),
        _buildActionButton(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Escanear',
          color: AppColors.accent,
        ),
        _buildActionButton(
          icon: Icons.more_horiz_rounded,
          label: 'Más',
          color: AppColors.gray500,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final available = onTap != null;
    return GestureDetector(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label: Próximamente'),
            backgroundColor: AppColors.gray700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: available ? 0.08 : 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withValues(alpha: available ? 0.15 : 0.08),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: available ? color : color.withValues(alpha: 0.4), size: 26),
                if (!available)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.gray300,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.lock_outline, size: 8, color: AppColors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: available ? AppColors.textSecondaryLight : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECTION HEADER
  // ============================================
  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.titleMedium()),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Ver todo',
              style: AppTypography.labelMedium(color: AppColors.primary),
            ),
          ),
      ],
    );
  }

  // ============================================
  // TRANSACTIONS LIST
  // ============================================

  /// Abre la página de edición de la transacción desde el dashboard (RF-06)
  Future<void> _openEditPage(TransactionEntity t) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: t),
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionsLoaded && state.transactions.isNotEmpty) {
          final items = state.transactions.take(5).toList();
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTransactionTile(items[index]),
              childCount: items.length,
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildEmptyTransactions());
      },
    );
  }

  Widget _buildTransactionsColumn(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        if (state is TransactionsLoaded && state.transactions.isNotEmpty) {
          final items = state.transactions.take(6).toList();
          return Column(
            children: items.map((t) => _buildTransactionTile(t)).toList(),
          );
        }
        return _buildEmptyTransactions();
      },
    );
  }

  Widget _buildTransactionTile(TransactionEntity t) {
    return GestureDetector(
      onTap: () => _openEditPage(t),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: t.isPendingSync ? AppColors.warning.withValues(alpha: 0.4) : AppColors.gray100,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getCategoryColor(t.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  _getCategoryIcon(t.category),
                  color: _getCategoryColor(t.category),
                  size: 20,
                ),
                // Indicador de pendiente de sincronización (RNF-15)
                if (t.isPendingSync)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.cloud_upload_outlined, size: 7, color: AppColors.white),
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
                Text(
                  t.description?.isNotEmpty == true ? t.description! : t.category,
                  style: AppTypography.titleSmall(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.category} · ${t.paymentMethod.label}',
                  style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
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
                _formatRelativeDate(t.date),
                style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Sin transacciones', style: AppTypography.titleSmall()),
          const SizedBox(height: 4),
          Text(
            'Pulsa + para registrar tu primera transacción',
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // SPENDING CHART
  // ============================================
  Widget _buildSpendingChart(BuildContext context) {
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
              Text('Gastos por categoría', style: AppTypography.titleMedium()),
              const SizedBox(height: 20),
              if (categories.isEmpty)
                _buildEmptyChart()
              else ...[
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // RepaintBoundary para aislar el repintado del gráfico (RNF-06)
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(160, 160),
                            painter: _DonutChartPainter(
                              categories: categories,
                              total: totalExpenses,
                              colorMap: {
                                for (final key in categories.keys)
                                  key: _getCategoryColor(key),
                              },
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_formatCurrency(totalExpenses), style: AppTypography.titleMedium()),
                            Text('total', style: AppTypography.bodySmall(color: AppColors.textTertiaryLight)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...categories.entries.map((cat) {
                  final pct = totalExpenses > 0 ? (cat.value / totalExpenses * 100) : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getCategoryColor(cat.key),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(cat.key, style: AppTypography.bodySmall())),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                        ),
                        const SizedBox(width: 8),
                        Text(_formatCurrency(cat.value), style: AppTypography.titleSmall()),
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

  Widget _buildEmptyChart() {
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
            Icon(Icons.donut_large_rounded, size: 32, color: AppColors.gray300),
            const SizedBox(height: 8),
            Text(
              'Registra gastos para ver el desglose',
              style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MONTHLY OVERVIEW
  // ============================================
  Widget _buildMonthlyOverview(BuildContext context) {
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final income = state is TransactionsLoaded ? state.totalIncome : 0.0;
        final expenses = state is TransactionsLoaded ? state.totalExpenses : 0.0;
        final savings = income - expenses;

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
                  Text('Resumen del mes', style: AppTypography.titleMedium()),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentMonthLabel(),
                      style: AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.south_west_rounded,
                      label: 'Ingresos',
                      value: _formatCurrency(income),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.north_east_rounded,
                      label: 'Gastos',
                      value: _formatCurrency(expenses),
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.savings_outlined,
                      label: 'Ahorro',
                      value: _formatCurrency(savings),
                      color: savings >= 0 ? AppColors.accent : AppColors.warning,
                    ),
                  ),
                ],
              ),
              if (income > 0 && expenses > 0) ...[
                const SizedBox(height: 20),
                Text('Progreso de gasto', style: AppTypography.bodySmall()),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: income > 0 ? (expenses / income).clamp(0.0, 1.0) : 0,
                    minHeight: 8,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (expenses / income) > 0.9 ? AppColors.error : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  income > 0
                      ? 'Has gastado el ${(expenses / income * 100).toStringAsFixed(0)}% de tus ingresos'
                      : '',
                  style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(label, style: AppTypography.labelSmall(color: AppColors.textTertiaryLight)),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleSmall(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _currentMonthLabel() {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  // ============================================
  // UTILS
  // ============================================
  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Hoy';
    if (d == yesterday) return 'Ayer';
    const m = ['Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
    return '${date.day} ${m[date.month - 1]}';
  }

  IconData _getCategoryIcon(String category) {
    return CategoryEntity.getIconForName(category);
  }

  Color _getCategoryColor(String category) {
    return CategoryEntity.getColorForName(category);
  }
}

/// Painter para el gráfico de dona con datos reales
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
    const strokeWidth = 22.0;
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
