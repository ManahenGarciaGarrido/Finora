import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../domain/entities/debt_entity.dart';
import '../bloc/debt_bloc.dart';
import '../bloc/debt_event.dart';
import '../bloc/debt_state.dart';
import '../widgets/debt_card.dart';
import '../widgets/strategy_comparison_widget.dart';
import 'add_edit_debt_page.dart';
import 'loan_calculator_page.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<DebtEntity> _debts = [];
  Map<String, dynamic>? _strategies;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider(
      create: (ctx) => di.sl<DebtBloc>()..add(const LoadDebts()),
      child: BlocConsumer<DebtBloc, DebtState>(
        listener: (ctx, state) {
          if (state is DebtsLoaded) {
            setState(() {
              _debts = state.debts;
              _loading = false;
              _error = null;
            });
          } else if (state is DebtLoading) {
            setState(() => _loading = true);
          } else if (state is DebtError) {
            setState(() {
              _loading = false;
              _error = state.message;
            });
          } else if (state is StrategiesLoaded) {
            setState(() {
              _strategies = state.data;
              _loading = false;
            });
          } else if (state is DebtDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.debtDeleted),
                backgroundColor: AppColors.success,
              ),
            );
            ctx.read<DebtBloc>().add(const LoadDebts());
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(s.debtsTitle, style: AppTypography.titleMedium()),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: s.ownDebtsTab),
                  Tab(text: s.owedToMeTab),
                  Tab(text: s.strategiesTab),
                ],
                onTap: (i) {
                  if (i == 2 && _strategies == null) {
                    ctx.read<DebtBloc>().add(const LoadStrategies());
                  }
                },
              ),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'loan') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoanCalculatorPage(),
                        ),
                      );
                    } else if (v == 'mortgage') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoanCalculatorPage(isMortgage: true),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'loan', child: Text(s.loanCalculator)),
                    PopupMenuItem(
                      value: 'mortgage',
                      child: Text(s.mortgageCalculator),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.calculate_outlined),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ctx.read<DebtBloc>().add(const LoadDebts()),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEditDebtPage()),
                );
                if (result == true && ctx.mounted) {
                  ctx.read<DebtBloc>().add(const LoadDebts());
                }
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(s.addDebt),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            body: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: SkeletonListLoader(count: 4, cardHeight: 100),
                  )
                : _error != null
                ? _buildError(ctx, s)
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _buildDebtList(ctx, s, 'own'),
                      _buildDebtList(ctx, s, 'owed'),
                      _buildStrategies(ctx, s),
                    ],
                  ),
          );
        },
      ),
    );
  }

  Widget _buildError(BuildContext ctx, dynamic s) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error!, style: AppTypography.bodyMedium()),
          TextButton(
            onPressed: () => ctx.read<DebtBloc>().add(const LoadDebts()),
            child: Text(s.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtList(BuildContext ctx, dynamic s, String type) {
    final filtered = _debts.where((d) => d.type == type).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'own'
                  ? Icons.credit_card_off_rounded
                  : Icons.monetization_on_outlined,
              color: AppColors.gray400,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              s.noDebts,
              style: AppTypography.bodyMedium(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ctx.read<DebtBloc>().add(const LoadDebts()),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final debt = filtered[i];
          return DebtCard(
            debt: debt,
            onEdit: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => AddEditDebtPage(debt: debt)),
              );
              if (result == true && ctx.mounted) {
                ctx.read<DebtBloc>().add(const LoadDebts());
              }
            },
            onDelete: () => _confirmDelete(ctx, s, debt.id),
          );
        },
      ),
    );
  }

  Widget _buildStrategies(BuildContext ctx, dynamic s) {
    if (_strategies == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              s.loading,
              style: AppTypography.bodyMedium(color: AppColors.gray500),
            ),
          ],
        ),
      );
    }
    return StrategyComparisonWidget(data: _strategies!);
  }

  Future<void> _confirmDelete(BuildContext ctx, dynamic s, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deleteDebt),
        content: Text(s.deleteDebtConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<DebtBloc>().add(DeleteDebt(id));
    }
  }
}
