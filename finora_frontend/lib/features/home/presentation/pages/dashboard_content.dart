import 'dart:convert';
import 'dart:math' as math;
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:finora_frontend/features/banks/presentation/widgets/notification_bell.dart';
import 'package:finora_frontend/features/goals/domain/entities/savings_goal_entity.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_bloc.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_event.dart';
import 'package:finora_frontend/features/goals/presentation/bloc/goal_state.dart';
import 'package:finora_frontend/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:finora_frontend/features/goals/presentation/pages/goals_page.dart';
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
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'predictions_page.dart'; // RF-22/HU-09 + RF-21/HU-08
import 'assistant_page.dart'; // RF-25/HU-12/CU-04 + RF-26/HU-13 + RF-27/HU-14
import 'stats_page.dart';
import 'transactions_page.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/services/profile_photo_service.dart';

/// Contenido del Dashboard principal
class DashboardContent extends StatefulWidget {
  /// Callback para navegar a la pestaña de Transacciones desde el dashboard
  final VoidCallback? onNavigateToTransactions;

  const DashboardContent({super.key, this.onNavigateToTransactions});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent>
    with SingleTickerProviderStateMixin {
  bool _balanceVisible = true;

  // ─── Shimmer animation (Skeleton loading – Nota Técnica) ─────────────────
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmerAnim;

  // ─── RF-28: Resumen mensual server-side (evita problema de paginación) ────
  List<({int monthNumber, double income, double expense})>? _monthlySummary;

  Future<void> _fetchMonthlySummary() async {
    try {
      final client = di.sl<ApiClient>();
      final resp = await client.get(
        ApiEndpoints.monthlySummary,
        queryParameters: {'months': 6},
      );
      final rows = (resp.data['summary'] as List?) ?? [];
      // Asegurar que existen los últimos 6 meses aunque no haya datos
      final now = DateTime.now();
      final result = List.generate(6, (i) {
        int m = now.month - 5 + i;
        int y = now.year;
        while (m <= 0) {
          m += 12;
          y--;
        }
        final key = '$y-${m.toString().padLeft(2, '0')}';
        final row = rows.firstWhere(
          (r) => r['month'] == key,
          orElse: () => {'month': key, 'income': 0.0, 'expenses': 0.0},
        );
        return (
          monthNumber: m,
          income: (row['income'] as num?)?.toDouble() ?? 0.0,
          expense: (row['expenses'] as num?)?.toDouble() ?? 0.0,
        );
      });
      if (mounted) setState(() => _monthlySummary = result);
    } catch (_) {
      // Silencioso — el chart usará datos locales como fallback
    }
  }

  String _formatCurrency(double amount) {
    final currency = AppSettingsService().currentCurrency;
    final converted = CurrencyService().convert(amount);
    final isNegative = converted < 0;
    final absAmount = converted.abs();
    final parts = absAmount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write('.');
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}${buffer.toString()},$decPart ${currency.symbol}';
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

  String _getUserFirstName(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final s = AppLocalizations.of(context);
    if (authState is Authenticated) {
      final name = authState.user.name;
      return name.split(' ').first;
    }
    return s.user;
  }

  String _getUserInitials(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      final parts = authState.user.name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'U';
  }

  @override
  void initState() {
    super.initState();
    ProfilePhotoService().loadIfNeeded(di.sl<ApiClient>());
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _shimmerAnim = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));
    _fetchMonthlySummary();
    AppSettingsService().currencyNotifier.addListener(_onCurrencyChanged);
  }

  void _onCurrencyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AppSettingsService().currencyNotifier.removeListener(_onCurrencyChanged);
    _shimmerCtrl.dispose();
    super.dispose();
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
    final s = AppLocalizations.of(context);

    return BlocListener<TransactionBloc, TransactionState>(
      listenWhen: (_, s) =>
          s is TransactionAdded ||
          s is TransactionUpdated ||
          s is TransactionDeleted,
      listener: (_, __) {
        setState(() => _monthlySummary = null);
        _fetchMonthlySummary();
      },
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<TransactionBloc>().add(LoadTransactions());
            setState(() => _monthlySummary = null);
            await _fetchMonthlySummary();
          },
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              // Balance total (destacado)
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: hp),
                  child: _buildBalanceCard(context),
                ),
              ),
              // Acciones rápidas
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hp, 24, hp, 0),
                  child: _buildQuickActions(context),
                ),
              ),
              // Secciones principales: skeleton mientras carga, real cuando listo (Nota Técnica)
              SliverToBoxAdapter(
                child: BlocBuilder<TransactionBloc, TransactionState>(
                  builder: (ctx, state) {
                    final isLoading =
                        state is TransactionInitial ||
                        state is TransactionLoading;
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: isLoading
                          ? Column(
                              key: const ValueKey('dashboard_skeleton'),
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 24, hp, 0),
                                  child: _buildSkeletonSectionCard(height: 160),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildSkeletonSectionCard(height: 230),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildSkeletonSectionCard(height: 220),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildSkeletonSectionCard(height: 180),
                                ),
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildSkeletonSectionCard(height: 100),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('dashboard_loaded'),
                              children: [
                                // Resumen del mes actual con comparativa (RF-28)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 24, hp, 0),
                                  child: _buildMonthlyOverview(context),
                                ),
                                // Gráfico barras ingresos vs gastos últimos 6 meses (RF-28)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildIncomeExpenseChart(context),
                                ),
                                // Top 5 categorías del mes actual (RF-28)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildSpendingChart(context),
                                ),
                                // Progreso de objetivos (RF-28)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildGoalsSection(context),
                                ),
                                // Próximos gastos recurrentes (RF-28)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildRecurringExpenses(context),
                                ),
                                // RF-22/HU-09 + RF-21/HU-08: Tarjeta de Predicciones IA
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 16, hp, 0),
                                  child: _buildAiPredictionsCard(context),
                                ),
                                // RF-25/HU-12/CU-04 + RF-26/HU-13 + RF-27/HU-14: Asistente IA
                                Padding(
                                  padding: EdgeInsets.fromLTRB(hp, 12, hp, 0),
                                  child: _buildAssistantCard(context),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
              // Últimas transacciones
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(hp, 24, hp, 12),
                  child: _buildSectionHeader(
                    s.lastTransactions,
                    onTap: widget.onNavigateToTransactions,
                    s,
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hp),
                sliver: _buildTransactionsList(context),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final hp = responsive.horizontalPadding;
    final isLargeTablet = responsive.screenWidth >= 1024;
    final columnGap = isLargeTablet ? 32.0 : 24.0;
    final leftColumnSpacing = isLargeTablet ? 20.0 : 16.0;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverPadding(
            padding: EdgeInsets.all(hp),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            _buildBalanceCard(context),
                            SizedBox(height: leftColumnSpacing + 4),
                            _buildQuickActions(context),
                            SizedBox(height: leftColumnSpacing + 4),
                            _buildMonthlyOverview(context),
                            SizedBox(height: leftColumnSpacing),
                            _buildIncomeExpenseChart(context),
                            SizedBox(height: leftColumnSpacing),
                            _buildSpendingChart(context),
                            SizedBox(height: leftColumnSpacing),
                            _buildGoalsSection(context),
                          ],
                        ),
                      ),
                      SizedBox(width: columnGap),
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildRecurringExpenses(context),
                            const SizedBox(height: 16),
                            // RF-22/HU-09 + RF-21/HU-08: Tarjeta Predicciones IA (tablet)
                            _buildAiPredictionsCard(context),
                            const SizedBox(height: 12),
                            // RF-25/HU-12/CU-04: Asistente IA (tablet)
                            _buildAssistantCard(context),
                            const SizedBox(height: 16),
                            if (isLargeTablet) ...[
                              // Extra widget visible on large tablets (iPad Pro)
                              _buildMonthlyOverview(context),
                              const SizedBox(height: 16),
                            ],
                            _buildSectionHeader(
                              s.lastTransactions,
                              onTap: widget.onNavigateToTransactions,
                              s,
                            ),
                            const SizedBox(height: 12),
                            _buildTransactionsColumn(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        16,
        responsive.horizontalPadding,
        16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡${s.hi}, ${_getUserFirstName(context)}!',
                  style: AppTypography.headlineSmall(),
                ),
                const SizedBox(height: 2),
                Text(
                  _getGreetingMessage(s),
                  style: AppTypography.bodyMedium(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: 10),
          ValueListenableBuilder<String?>(
            valueListenable: ProfilePhotoService().photoNotifier,
            builder: (_, photo, __) {
              if (photo != null && photo.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(photo),
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsAvatar44(context),
                  ),
                );
              }
              return _initialsAvatar44(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar44(BuildContext context) {
    return Container(
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
    );
  }

  String _getGreetingMessage(AppLocalizations s) {
    final hour = DateTime.now().hour;
    if (hour < 12) return s.goodMorning;
    if (hour < 20) return s.goodAfternoon;
    return s.goodNight;
  }

  // ============================================
  // SKELETON LOADING (Nota Técnica HU-15)
  // Muestra placeholders animados mientras carga la primera vez.
  // ============================================

  /// Caja gris pulsante: base de todos los widgets skeleton
  Widget _shimmerBox({
    double width = double.infinity,
    double height = 16,
    double radius = 8,
  }) {
    return AnimatedBuilder(
      animation: _shimmerAnim,
      builder: (_, __) => Opacity(
        opacity: _shimmerAnim.value,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.gray200,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  /// Skeleton de la tarjeta de balance (copia visual de _buildBalanceCard)
  Widget _buildSkeletonBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
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
              _shimmerBox(width: 90, height: 14, radius: 6),
              _shimmerBox(width: 32, height: 26, radius: 13),
            ],
          ),
          const SizedBox(height: 10),
          _shimmerBox(width: 180, height: 36, radius: 10),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(child: _shimmerBox(height: 36, radius: 8)),
                const SizedBox(width: 12),
                Expanded(child: _shimmerBox(height: 36, radius: 8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Skeleton genérico de card de sección
  Widget _buildSkeletonSectionCard({double height = 120}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmerBox(width: 120, height: 14, radius: 6),
          const SizedBox(height: 12),
          _shimmerBox(height: 12, radius: 6),
          const SizedBox(height: 8),
          _shimmerBox(width: 200, height: 12, radius: 6),
        ],
      ),
    );
  }

  /// Skeleton de un ítem de transacción
  Widget _buildSkeletonTransactionTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          _shimmerBox(width: 44, height: 44, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _shimmerBox(width: 140, height: 13, radius: 6),
                const SizedBox(height: 6),
                _shimmerBox(width: 90, height: 11, radius: 5),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _shimmerBox(width: 64, height: 13, radius: 6),
              const SizedBox(height: 6),
              _shimmerBox(width: 40, height: 11, radius: 5),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // MONTHLY DATA HELPERS (RF-28)
  // ============================================

  List<TransactionEntity> _thisMonthTxs(List<TransactionEntity> all) {
    final now = DateTime.now();
    return all
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
  }

  List<TransactionEntity> _lastMonthTxs(List<TransactionEntity> all) {
    final now = DateTime.now();
    int y = now.year, m = now.month - 1;
    if (m <= 0) {
      m = 12;
      y--;
    }
    return all.where((t) => t.date.year == y && t.date.month == m).toList();
  }

  /// Últimos 6 meses: monthNumber, ingresos y gastos de cada mes
  List<({int monthNumber, double income, double expense})> _last6MonthsData(
    List<TransactionEntity> all,
  ) {
    final now = DateTime.now();
    return List.generate(6, (i) {
      int m = now.month - 5 + i;
      int y = now.year;
      while (m <= 0) {
        m += 12;
        y--;
      }
      final txs = all
          .where((t) => t.date.year == y && t.date.month == m)
          .toList();
      return (
        monthNumber: m,
        income: txs.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount),
        expense: txs
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount),
      );
    });
  }

  /// Returns the localized month abbreviation for the given month number (1-12)
  String _getMonthAbbr(AppLocalizations s, int month) {
    switch (month) {
      case 1:
        return s.jan;
      case 2:
        return s.feb;
      case 3:
        return s.mar;
      case 4:
        return s.apr;
      case 5:
        return s.mayy;
      case 6:
        return s.jun;
      case 7:
        return s.jul;
      case 8:
        return s.aug;
      case 9:
        return s.sep;
      case 10:
        return s.oct;
      case 11:
        return s.nov;
      case 12:
        return s.dec;
      default:
        return '';
    }
  }

  /// Detecta gastos recurrentes (≥ 2 meses distintos) y filtra los
  /// que vencen en los próximos 7 días
  List<Map<String, dynamic>> _detectRecurring(List<TransactionEntity> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    final groups = <String, List<TransactionEntity>>{};
    for (final t in all) {
      if (!t.isExpense) continue;
      final key = t.description?.trim().isNotEmpty == true
          ? t.description!.trim()
          : t.category;
      groups.putIfAbsent(key, () => []).add(t);
    }

    final recurring = <Map<String, dynamic>>[];
    for (final entry in groups.entries) {
      final txs = entry.value;
      if (txs.length < 2) continue;
      final months = txs.map((t) => '${t.date.year}-${t.date.month}').toSet();
      if (months.length < 2) continue;
      txs.sort((a, b) => b.date.compareTo(a.date));
      final latest = txs.first;
      int nm = latest.date.month + 1, ny = latest.date.year;
      if (nm > 12) {
        nm = 1;
        ny++;
      }
      final daysInNM = DateTime(ny, nm + 1, 0).day;
      final nextDate = DateTime(ny, nm, latest.date.day.clamp(1, daysInNM));
      if (!nextDate.isBefore(today) && nextDate.isBefore(nextWeek)) {
        recurring.add({
          'name': entry.key,
          'amount': latest.amount,
          'category': latest.category,
          'nextDate': nextDate,
          'daysUntil': nextDate.difference(today).inDays,
        });
      }
    }
    recurring.sort(
      (a, b) =>
          (a['nextDate'] as DateTime).compareTo(b['nextDate'] as DateTime),
    );
    return recurring;
  }

  // ============================================
  // BALANCE CARD
  // ============================================
  Widget _buildBalanceCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        // Skeleton loading: muestra placeholder animado mientras carga (Nota Técnica)
        if (state is TransactionInitial || state is TransactionLoading) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: _buildSkeletonBalanceCard(),
          );
        }

        final double income = state is TransactionsLoaded
            ? state.totalIncome
            : 0;
        final double expenses = state is TransactionsLoaded
            ? state.totalExpenses
            : 0;
        final double balance = income - expenses;

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          child: Container(
            key: const ValueKey('balance_loaded'),
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
                      s.totalBalance,
                      style: AppTypography.labelMedium(
                        color: AppColors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _balanceVisible = !_balanceVisible),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      s.firstTransaction,
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
                        label: s.income,
                        amount: _balanceVisible
                            ? _formatCurrency(income)
                            : '••••',
                        color: AppColors.successLight,
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: AppColors.white.withValues(alpha: 0.15),
                      ),
                      _buildBalanceIndicator(
                        icon: Icons.north_east_rounded,
                        label: s.expenses,
                        amount: _balanceVisible
                            ? _formatCurrency(expenses)
                            : '••••',
                        color: AppColors.errorLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ), // cierra Container (tarjeta de balance)
        ); // cierra AnimatedSwitcher
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
    final s = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          icon: Icons.add_rounded,
          label: s.add,
          color: AppColors.primary,
          onTap: () => Navigator.pushNamed(context, '/add-transaction'),
        ),
        _buildActionButton(
          icon: Icons.list_alt_rounded,
          label: s.history,
          color: AppColors.secondary,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: TransactionsPage()),
            ),
          ),
        ),
        _buildActionButton(
          icon: Icons.bar_chart_rounded,
          label: s.statistics,
          color: AppColors.accent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: StatsPage()),
            ),
          ),
        ),
        // RF-22/HU-09: Acceso rápido a Predicciones IA desde acciones rápidas
        _buildActionButton(
          icon: Icons.auto_awesome_rounded,
          label: 'Pred.',
          color: const Color(0xFF6C63FF),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PredictionsPage()),
          ),
        ),
        // RF-25/HU-12/CU-04: Acceso rápido al Asistente IA conversacional
        _buildActionButton(
          icon: Icons.smart_toy_rounded,
          label: 'Finn',
          color: const Color(0xFF3B82F6),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AssistantPage()),
          ),
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
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$label: Próximamente'),
                backgroundColor: AppColors.gray700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                Icon(
                  icon,
                  color: available ? color : color.withValues(alpha: 0.4),
                  size: 26,
                ),
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
                      child: const Icon(
                        Icons.lock_outline,
                        size: 8,
                        color: AppColors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.labelSmall(
              color: available
                  ? AppColors.textSecondaryLight
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // SECTION HEADER
  // ============================================
  Widget _buildSectionHeader(
    String title,
    AppLocalizations s, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.titleMedium()),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              s.seeAll,
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
        // Skeleton loading: 3 tiles pulsantes mientras carga (Nota Técnica)
        if (state is TransactionInitial || state is TransactionLoading) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, __) => _buildSkeletonTransactionTile(),
              childCount: 3,
            ),
          );
        }
        if (state is TransactionsLoaded && state.transactions.isNotEmpty) {
          final items = state.transactions.take(5).toList();
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTransactionTile(items[index]),
              childCount: items.length,
            ),
          );
        }
        return SliverToBoxAdapter(child: _buildEmptyTransactions(context));
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
        return _buildEmptyTransactions(context);
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
            color: t.isPendingSync
                ? AppColors.warning.withValues(alpha: 0.4)
                : AppColors.gray100,
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
                          border: Border.all(
                            color: AppColors.white,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          size: 7,
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
                  Text(
                    t.description?.isNotEmpty == true
                        ? t.description!
                        : t.category,
                    style: AppTypography.titleSmall(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${t.category} · ${t.paymentMethod.label}',
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
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
                  _formatRelativeDate(t.date, context),
                  style: AppTypography.bodySmall(
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

  Widget _buildEmptyTransactions(BuildContext context) {
    final s = AppLocalizations.of(context);
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
            child: Icon(
              Icons.receipt_long_outlined,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(s.noTransactions, style: AppTypography.titleSmall()),
          const SizedBox(height: 4),
          Text(
            s.registerFirst,
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // SPENDING CHART (RF-28: top 5 categorías del mes actual)
  // ============================================
  Widget _buildSpendingChart(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final all = state is TransactionsLoaded
            ? state.transactions
            : <TransactionEntity>[];
        final thisMonth = _thisMonthTxs(all);

        // Construir mapa de categorías con gastos del mes actual
        final catMap = <String, double>{};
        for (final t in thisMonth) {
          if (t.isExpense) {
            catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
          }
        }
        // Top 5 categorías ordenadas por importe
        final sorted = catMap.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top5 = Map.fromEntries(sorted.take(5));
        final totalExpenses = top5.values.fold(0.0, (s, v) => s + v);

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
                  Text(
                    s.topMonthlyExpenses,
                    style: AppTypography.titleMedium(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Top 5',
                      style: AppTypography.badge(color: AppColors.error),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (top5.isEmpty)
                _buildEmptyChart(s)
              else ...[
                Center(
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        RepaintBoundary(
                          child: CustomPaint(
                            size: const Size(160, 160),
                            painter: _DonutChartPainter(
                              categories: top5,
                              total: totalExpenses,
                              colorMap: {
                                for (final key in top5.keys)
                                  key: _getCategoryColor(key),
                              },
                            ),
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
                              s.thisMonth,
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
                const SizedBox(height: 20),
                ...top5.entries.map((cat) {
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
                            color: _getCategoryColor(cat.key),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getTranslatedCategory(context, cat.key),
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

  Widget _buildEmptyChart(AppLocalizations s) {
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
              s.emptyTopExpenses,
              style: AppTypography.bodySmall(
                color: AppColors.textTertiaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // GRÁFICO INGRESOS VS GASTOS — últimos 6 meses (RF-28)
  // ============================================
  Widget _buildIncomeExpenseChart(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        // Usar datos del servidor (todos los meses) si están disponibles;
        // si no, fallback a los 100 txs cargados (podrían estar incompletos).
        final data =
            _monthlySummary ??
            _last6MonthsData(
              state is TransactionsLoaded ? state.transactions : [],
            );
        // Refrescar datos del servidor cuando cambia el estado de transacciones
        if (state is TransactionsLoaded && _monthlySummary == null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fetchMonthlySummary(),
          );
        }
        final maxVal = data.fold(
          0.0,
          (m, d) => math.max(m, math.max(d.income, d.expense)),
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
                  Text(
                    '${s.incomes} vs ${s.expense}',
                    style: AppTypography.titleMedium(),
                  ),
                  Row(
                    children: [
                      _buildLegendDot(AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        s.incomes,
                        style: AppTypography.badge(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildLegendDot(AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        s.expenses,
                        style: AppTypography.badge(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (maxVal == 0)
                Container(
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 32,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.registerTransactions,
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                RepaintBoundary(
                  child: SizedBox(
                    height: 140,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: data.map((d) {
                        const maxBarH = 110.0;
                        final incomeH = maxVal > 0
                            ? (d.income / maxVal * maxBarH).clamp(2.0, maxBarH)
                            : 0.0;
                        final expenseH = maxVal > 0
                            ? (d.expense / maxVal * maxBarH).clamp(2.0, maxBarH)
                            : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: incomeH,
                                        decoration: BoxDecoration(
                                          color: AppColors.success.withValues(
                                            alpha: 0.80,
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(3),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    Expanded(
                                      child: Container(
                                        height: expenseH,
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: 0.80,
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(3),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _getMonthAbbr(s, d.monthNumber),
                                  style: AppTypography.badge(
                                    color: AppColors.textTertiaryLight,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================
  // OBJETIVOS FINANCIEROS (RF-28)
  // ============================================
  // ============================================
  // RF-18 / RF-19 / HU-07: Objetivos de ahorro reales con GoalBloc
  // ============================================
  Widget _buildGoalsSection(BuildContext context) {
    return BlocProvider<GoalBloc>(
      create: (_) => di.sl<GoalBloc>()..add(const LoadGoals()),
      child: const _GoalsSectionContent(),
    );
  }

  // ============================================
  // GASTOS RECURRENTES — próximos 7 días (RF-28)
  // ============================================
  Widget _buildRecurringExpenses(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final all = state is TransactionsLoaded
            ? state.transactions
            : <TransactionEntity>[];
        final recurring = _detectRecurring(all);

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
                children: [
                  Text(s.nextExpenses, style: AppTypography.titleMedium()),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '7 ${s.days}',
                      style: AppTypography.badge(color: AppColors.warningDark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (recurring.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 32,
                        color: AppColors.gray300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.withoutRecurringExpenses,
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.recurringTimeLeft,
                        textAlign: TextAlign.center,
                        style: AppTypography.badge(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...recurring.map((r) => _buildRecurringTile(r, context)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecurringTile(Map<String, dynamic> r, BuildContext context) {
    final s = AppLocalizations.of(context);
    final daysUntil = r['daysUntil'] as int;
    final label = daysUntil == 0
        ? s.today
        : daysUntil == 1
        ? s.tomorrow
        : '${s.inDays} $daysUntil ${s.days}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(r['category'] as String),
              size: 18,
              color: _getCategoryColor(r['category'] as String),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['name'] as String,
                  style: AppTypography.labelMedium(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: AppTypography.bodySmall(color: AppColors.warningDark),
                ),
              ],
            ),
          ),
          Text(
            '-${_formatCurrency(r['amount'] as double)}',
            style: AppTypography.titleSmall(color: AppColors.error),
          ),
        ],
      ),
    );
  }

  // ============================================
  // RF-22/HU-09 + RF-21/HU-08: TARJETA PREDICCIONES IA
  // Acceso rápido a predicciones de gastos ML y recomendaciones de ahorro
  // ============================================

  Widget _buildAiPredictionsCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PredictionsPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.predictionsAI,
                    style: AppTypography.titleSmall(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.subtitleAI,
                    style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // RF-25/HU-12/CU-04 + RF-26/HU-13 + RF-27/HU-14: TARJETA ASISTENTE IA
  // Acceso rápido al chat con el asistente Finn
  // ============================================

  Widget _buildAssistantCard(BuildContext context) {
    final s = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AssistantPage()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.30),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.finnAsisstant,
                    style: AppTypography.titleSmall(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.subtitleFinn,
                    style: AppTypography.bodySmall(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // MONTHLY OVERVIEW (RF-28: mes actual + comparativa)
  // ============================================
  Widget _buildMonthlyOverview(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<TransactionBloc, TransactionState>(
      builder: (context, state) {
        final all = state is TransactionsLoaded
            ? state.transactions
            : <TransactionEntity>[];
        final thisMonth = _thisMonthTxs(all);
        final lastMonth = _lastMonthTxs(all);

        final income = thisMonth
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final expenses = thisMonth
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);
        final savings = income - expenses;

        final prevIncome = lastMonth
            .where((t) => t.isIncome)
            .fold(0.0, (s, t) => s + t.amount);
        final prevExpenses = lastMonth
            .where((t) => t.isExpense)
            .fold(0.0, (s, t) => s + t.amount);

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
                  Text(s.monthlySummary, style: AppTypography.titleMedium()),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentMonthLabel(s),
                      style: AppTypography.labelSmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.south_west_rounded,
                      label: s.incomes,
                      value: _formatCurrency(income),
                      color: AppColors.success,
                      badgeWidget: _buildComparisonBadge(
                        income,
                        prevIncome,
                        false,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.north_east_rounded,
                      label: s.expenses,
                      value: _formatCurrency(expenses),
                      color: AppColors.error,
                      badgeWidget: _buildComparisonBadge(
                        expenses,
                        prevExpenses,
                        true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryTile(
                      icon: Icons.savings_outlined,
                      label: s.saving,
                      value: _formatCurrency(savings),
                      color: savings >= 0
                          ? AppColors.accent
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
              if (income > 0) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s.expenseProgress, style: AppTypography.bodySmall()),
                    Text(
                      '${(expenses / income * 100).clamp(0, 999).toStringAsFixed(0)}% ${s.ofIncome}',
                      style: AppTypography.badge(
                        color: (expenses / income) > 0.9
                            ? AppColors.error
                            : AppColors.textTertiaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (expenses / income).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      (expenses / income) > 0.9
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Badge ↑↓ con % comparado con el mes anterior (RF-28)
  Widget _buildComparisonBadge(
    double current,
    double previous,
    bool isExpense,
  ) {
    if (previous == 0) return const SizedBox.shrink();
    final diff = ((current - previous) / previous) * 100;
    final isIncrease = diff > 0;
    final isGood = isExpense ? !isIncrease : isIncrease;
    final color = isGood ? AppColors.success : AppColors.error;
    final icon = isIncrease
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 2),
        Text(
          '${diff.abs().toStringAsFixed(0)}%',
          style: AppTypography.badge(color: color),
        ),
      ],
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    Widget? badgeWidget,
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
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              if (badgeWidget != null) badgeWidget,
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.labelSmall(color: AppColors.textTertiaryLight),
          ),
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

  String _currentMonthLabel(AppLocalizations s) {
    final months = [
      s.january,
      s.february,
      s.march,
      s.april,
      s.may,
      s.june,
      s.july,
      s.august,
      s.september,
      s.october,
      s.november,
      s.december,
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  // ============================================
  // UTILS
  // ============================================
  String _formatRelativeDate(DateTime date, BuildContext context) {
    final s = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return s.today;
    if (d == yesterday) return s.yesterday;
    const m = [
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

// ============================================
// RF-18 / RF-19 / HU-07: Sección Objetivos de ahorro (reales, desde GoalBloc)
// ============================================

/// Widget separado para usar GoalBloc provisto por BlocProvider en _buildGoalsSection
class _GoalsSectionContent extends StatelessWidget {
  const _GoalsSectionContent();

  String _formatCurrency(double amount) {
    return CurrencyService().formatCompact(amount);
  }

  Color _progressColor(String hexColor) {
    try {
      final c = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$c', radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Color _barColor(String progressColor) {
    switch (progressColor) {
      case 'green':
        return AppColors.success;
      case 'yellow':
        return AppColors.warning;
      case 'red':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocBuilder<GoalBloc, GoalState>(
      builder: (context, state) {
        if (state is GoalLoading || state is GoalInitial) {
          return _buildCard(
            context,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (state is GoalError) {
          return _buildCard(
            context,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  s.objectiveLoadFailure,
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          );
        }

        final goals = state is GoalsLoaded
            ? state.goals.where((g) => g.isActive).toList()
            : <SavingsGoalEntity>[];

        return _buildCard(
          context,
          child: goals.isEmpty
              ? _buildEmptyState(context)
              : Column(
                  children: goals
                      .take(3) // máximo 3 en el dashboard
                      .map((g) => _buildGoalRow(context, g))
                      .toList(),
                ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final s = AppLocalizations.of(context);
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
              Text(s.savingsGoals, style: AppTypography.titleMedium()),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GoalsPage()),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  s.seeAll,
                  style: AppTypography.labelSmall(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final s = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoalsPage()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.20)),
        ),
        child: Column(
          children: [
            Icon(Icons.savings_outlined, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              s.createFirstGoal,
              style: AppTypography.labelMedium(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalRow(BuildContext context, SavingsGoalEntity goal) {
    final s = AppLocalizations.of(context);
    final barColor = _barColor(goal.progressColor);
    final iconColor = _progressColor(goal.color);
    final progress = goal.percentageDecimal.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        // Reutilizar el mismo GoalBloc del dashboard para que ContributionAdded
        // y LoadGoals actualicen también el dashboard en tiempo real.
        final bloc = context.read<GoalBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: GoalDetailPage(goal: goal),
            ),
          ),
        ).then((_) {
          // Al volver del detalle, recargar objetivos para reflejar el progreso.
          if (!bloc.isClosed) bloc.add(const LoadGoals());
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(goal.icon, style: const TextStyle(fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: AppTypography.labelMedium(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${goal.percentage}%',
                            style: AppTypography.labelSmall(color: barColor),
                          ),
                        ],
                      ),
                      Text(
                        '${_formatCurrency(goal.currentAmount)} ${s.ofText} ${_formatCurrency(goal.targetAmount)}',
                        style: AppTypography.bodySmall(
                          color: AppColors.textTertiaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.gray400,
                ),
              ],
            ),
            const SizedBox(height: 6),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOut,
              builder: (_, value, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: AppColors.gray100,
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
