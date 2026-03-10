import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/entities/goal_contribution_entity.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'goals_page.dart' show goalIconsMap;

/// RF-19 / RF-20 / HU-07: Detalle del objetivo con progreso, aportaciones y IA
class GoalDetailPage extends StatefulWidget {
  final SavingsGoalEntity goal;
  const GoalDetailPage({super.key, required this.goal});

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> {
  late SavingsGoalEntity _goal;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    context.read<GoalBloc>().add(LoadContributions(_goal.id));
  }

  /// HU-07: Convierte el string de color de progreso ('red'/'yellow'/'green') a Color
  Color _resolveProgressColor(String progressColor) {
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
    final goalColor = Color(
      int.parse(_goal.color.replaceAll('#', 'FF'), radix: 16),
    );
    final progressColor = _resolveProgressColor(_goal.progressColor);

    return BlocConsumer<GoalBloc, GoalState>(
      listener: (context, state) {
        if (state is ContributionAdded) {
          // RF-19: Actualización en tiempo real
          setState(() {
            final p = state.updatedProgress;
            _goal = _rebuildGoalFromProgress(_goal, p);
            if (state.goalCompleted && !_showConfetti) {
              _showConfetti = true; // HU-07: celebración visual
              _showCompletionDialog(context);
            }
          });
          context.read<GoalBloc>().add(LoadContributions(_goal.id));
          // Refrescar lista de objetivos para actualizar dashboard en tiempo real
          context.read<GoalBloc>().add(const LoadGoals());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Aportación añadida correctamente'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (state is ContributionDeleted) {
          context.read<GoalBloc>().add(LoadContributions(_goal.id));
        } else if (state is GoalError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final contributions = state is ContributionsLoaded
            ? state.contributions
            : <GoalContributionEntity>[];
        final isLoading = state is GoalLoading;

        return Scaffold(
          backgroundColor: AppColors.gray50,
          body: CustomScrollView(
            slivers: [
              // ── Header con gradiente y progreso (HU-07) ───────────────────
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: goalColor,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [goalColor, goalColor.withValues(alpha: 0.75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    goalIconsMap[_goal.icon] ??
                                        Icons.savings_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _goal.name,
                                        style: AppTypography.titleMedium(
                                          color: Colors.white,
                                        ),
                                      ),
                                      if (_goal.category != null)
                                        Text(
                                          _goal.category!,
                                          style: AppTypography.bodySmall(
                                            color: Colors.white.withValues(
                                              alpha: 0.80,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${_goal.percentage}%',
                                  style: AppTypography.headlineLarge(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Barra de progreso animada (HU-07)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(
                                  begin: 0,
                                  end: _goal.percentageDecimal,
                                ),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutCubic,
                                builder: (_, v, __) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 12,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.25,
                                  ),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_fmt(_goal.currentAmount)} €',
                                  style: AppTypography.labelMedium(
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Meta: ${_fmt(_goal.targetAmount)} €',
                                  style: AppTypography.bodySmall(
                                    color: Colors.white.withValues(alpha: 0.80),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'delete') _confirmDelete(context);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text('Cancelar objetivo'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ── Contenido ────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // RF-19: Métricas de progreso
                    _ProgressMetrics(goal: _goal, progressColor: progressColor),
                    const SizedBox(height: 12),

                    // RF-21: Análisis IA
                    if (_goal.aiFeasibility != null)
                      _AiAnalysisCard(goal: _goal),

                    if (_goal.aiFeasibility != null) const SizedBox(height: 12),

                    // RF-20: Botón añadir aportación
                    if (_goal.isActive)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddContributionSheet(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goalColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            'Añadir aportación',
                            style: AppTypography.labelMedium(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    if (_goal.isActive) const SizedBox(height: 12),

                    // RF-20: Historial de aportaciones
                    _ContributionsList(
                      contributions: contributions,
                      isLoading: isLoading && contributions.isEmpty,
                      goalId: _goal.id,
                    ),
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddContributionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<GoalBloc>(),
        child: _AddContributionSheet(goalId: _goal.id, goalName: _goal.name),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar objetivo?'),
        content: Text(
          'Se cancelará el objetivo "${_goal.name}". El historial de aportaciones se conservará.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<GoalBloc>().add(DeleteGoal(_goal.id));
              Navigator.pop(context);
            },
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// HU-07: Celebración visual al alcanzar el 100%
  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '🎉 ¡Objetivo completado!',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡Enhorabuena! Has alcanzado tu objetivo de ahorro.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '${_goal.name}: ${_fmt(_goal.targetAmount)} €',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall(color: AppColors.success),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('¡Perfecto!'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static double _pd(dynamic v, double fallback) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static int _pi(dynamic v, int fallback) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().split('.').first) ?? fallback;
  }

  SavingsGoalEntity _rebuildGoalFromProgress(
    SavingsGoalEntity goal,
    Map<String, dynamic> p,
  ) {
    final pct = _pi(p['percentage'], goal.percentage);
    final pctD = _pd(p['percentage_decimal'], goal.percentageDecimal);
    final current = _pd(p['current_amount'], goal.currentAmount);
    final remaining = _pd(p['remaining_amount'], goal.remainingAmount);
    final color = p['progress_color'] as String? ?? goal.progressColor;
    final completed = p['is_completed'] as bool? ?? goal.isCompleted;

    // Devolver una entidad actualizada con los nuevos valores de progreso
    return SavingsGoalEntity(
      id: goal.id,
      userId: goal.userId,
      name: goal.name,
      icon: goal.icon,
      color: goal.color,
      targetAmount: goal.targetAmount,
      currentAmount: current,
      deadline: goal.deadline,
      category: goal.category,
      notes: goal.notes,
      status: completed ? 'completed' : goal.status,
      percentage: pct,
      percentageDecimal: pctD,
      remainingAmount: remaining,
      progressColor: color,
      isCompleted: completed,
      projectedCompletionDate:
          p['projected_completion_date'] as String? ??
          goal.projectedCompletionDate,
      monthlyTarget: goal.monthlyTarget,
      aiFeasibility: goal.aiFeasibility,
      aiExplanation: goal.aiExplanation,
      completedAt: goal.completedAt,
      createdAt: goal.createdAt,
      updatedAt: goal.updatedAt,
    );
  }

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
}

// ─── Métricas de progreso (RF-19) ─────────────────────────────────────────────

class _ProgressMetrics extends StatelessWidget {
  final SavingsGoalEntity goal;
  final Color progressColor;

  const _ProgressMetrics({required this.goal, required this.progressColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Metric(
                label: 'Ahorrado',
                value: '${_fmt(goal.currentAmount)} €',
                color: progressColor,
              ),
              _Metric(
                label: 'Restante',
                value: '${_fmt(goal.remainingAmount)} €',
                color: AppColors.textSecondaryLight,
              ),
              _Metric(
                label: 'Objetivo',
                value: '${_fmt(goal.targetAmount)} €',
                color: AppColors.textPrimaryLight,
              ),
            ],
          ),
          if (goal.deadline != null || goal.projectedCompletionDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (goal.deadline != null)
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.flag_rounded,
                        label: 'Fecha límite',
                        value: _fmtDate(goal.deadline!),
                      ),
                    ),
                  if (goal.projectedCompletionDate != null)
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.trending_up_rounded,
                        label: 'Proyección',
                        value: goal.projectedCompletionDate!,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) => v
      .toStringAsFixed(2)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.titleSmall(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.badge(color: AppColors.textTertiaryLight),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.gray400),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.badge(color: AppColors.textTertiaryLight),
            ),
            Text(value, style: AppTypography.labelMedium()),
          ],
        ),
      ],
    );
  }
}

// ─── Análisis IA (RF-21) ──────────────────────────────────────────────────────

class _AiAnalysisCard extends StatelessWidget {
  final SavingsGoalEntity goal;
  const _AiAnalysisCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (goal.aiFeasibility) {
      case 'viable':
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
        break;
      case 'difficult':
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppColors.error;
        icon = Icons.error_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                'Análisis IA',
                style: AppTypography.labelMedium(color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      goal.feasibilityLabel ?? '',
                      style: AppTypography.badge(color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (goal.aiExplanation != null) ...[
            const SizedBox(height: 6),
            Text(
              goal.aiExplanation!,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (goal.monthlyTarget != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.savings_outlined, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  'Aportación mensual sugerida: ${goal.monthlyTarget!.toStringAsFixed(2)} €',
                  style: AppTypography.labelMedium(color: color),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Historial de aportaciones (RF-20) ────────────────────────────────────────

class _ContributionsList extends StatelessWidget {
  final List<GoalContributionEntity> contributions;
  final bool isLoading;
  final String goalId;

  const _ContributionsList({
    required this.contributions,
    required this.isLoading,
    required this.goalId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aportaciones', style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (contributions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Todavía no hay aportaciones.\nToca "Añadir aportación" para empezar.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            )
          else
            ...contributions.map(
              (c) => _ContributionTile(contribution: c, goalId: goalId),
            ),
        ],
      ),
    );
  }
}

class _ContributionTile extends StatelessWidget {
  final GoalContributionEntity contribution;
  final String goalId;

  const _ContributionTile({required this.contribution, required this.goalId});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(contribution.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.error.withValues(alpha: 0.10),
        child: Icon(Icons.delete_rounded, color: AppColors.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('¿Eliminar aportación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        context.read<GoalBloc>().add(
          DeleteContribution(goalId, contribution.id),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: AppColors.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contribution.note?.isNotEmpty == true
                        ? contribution.note!
                        : 'Aportación',
                    style: AppTypography.labelMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _fmtDate(contribution.date),
                    style: AppTypography.badge(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '+${contribution.amount.toStringAsFixed(2)} €',
              style: AppTypography.labelMedium(color: AppColors.success),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

// ─── Bottom Sheet: Añadir aportación con selección de cuenta y consejo IA ─────

/// Modelo sencillo para representar una cuenta origen de la aportación.
class _SourceAccount {
  final String? id; // null = efectivo
  final String name;
  final String subtitle;
  final IconData icon;

  const _SourceAccount({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.icon,
  });
}

class _AddContributionSheet extends StatefulWidget {
  final String goalId;
  final String goalName;

  const _AddContributionSheet({required this.goalId, required this.goalName});

  @override
  State<_AddContributionSheet> createState() => _AddContributionSheetState();
}

class _AddContributionSheetState extends State<_AddContributionSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  final _formKey = GlobalKey<FormState>();

  // Cuentas disponibles
  List<_SourceAccount> _accounts = [];
  bool _loadingAccounts = true;
  _SourceAccount? _selectedAccount;

  // Consejo IA
  bool _loadingAdvice = false;
  Map<String, dynamic>? _advice;
  bool _adviceFetched = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    try {
      final client = di.sl<ApiClient>();
      final resp = await client.get(ApiEndpoints.bankAccounts);
      final list = (resp.data['accounts'] as List?) ?? [];
      final accounts = <_SourceAccount>[
        const _SourceAccount(
          id: null,
          name: 'Efectivo',
          subtitle: 'Sin cuenta bancaria',
          icon: Icons.wallet_rounded,
        ),
      ];
      for (final a in list) {
        final name = a['account_name'] as String? ?? 'Cuenta';
        final institution = a['institution_name'] as String? ?? '';
        final balanceCents = (a['balance_cents'] as num?)?.toInt() ?? 0;
        final balance = (balanceCents / 100.0).toStringAsFixed(2);
        accounts.add(
          _SourceAccount(
            id: a['id'] as String?,
            name: name,
            subtitle:
                '${institution.isNotEmpty ? '$institution · ' : ''}$balance €',
            icon: Icons.account_balance_rounded,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _selectedAccount = accounts.first;
          _loadingAccounts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _accounts = [
            const _SourceAccount(
              id: null,
              name: 'Efectivo',
              subtitle: 'Sin cuenta bancaria',
              icon: Icons.wallet_rounded,
            ),
          ];
          _selectedAccount = _accounts.first;
          _loadingAccounts = false;
        });
      }
    }
  }

  Future<void> _fetchAdvice() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
    setState(() {
      _loadingAdvice = true;
      _advice = null;
      _adviceFetched = false;
    });
    try {
      final client = di.sl<ApiClient>();
      final resp = await client.post(
        ApiEndpoints.goalContributionAdvice(widget.goalId),
        data: {'proposed_amount': amount},
      );
      if (mounted) {
        setState(() {
          _advice = resp.data as Map<String, dynamic>;
          _adviceFetched = true;
          _loadingAdvice = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _advice = null;
          _adviceFetched = true;
          _loadingAdvice = false;
        });
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) return;
    final amount = double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
    context.read<GoalBloc>().add(
      AddContribution(
        goalId: widget.goalId,
        amount: amount,
        date: _date,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        bankAccountId: _selectedAccount!.id,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.gray200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Añadir aportación', style: AppTypography.titleMedium()),
              const SizedBox(height: 16),

              // ── Cantidad ────────────────────────────────────────────────────
              TextFormField(
                controller: _amountCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  suffixText: '€',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d,\.]')),
                ],
                onChanged: (_) {
                  // Al cambiar el importe, el consejo queda obsoleto
                  if (_adviceFetched) {
                    setState(() {
                      _advice = null;
                      _adviceFetched = false;
                    });
                  }
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introduce una cantidad';
                  final n = double.tryParse(v.replaceAll(',', '.'));
                  if (n == null || n <= 0) {
                    return 'Introduce una cantidad positiva';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // ── Fecha ───────────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                        style: AppTypography.bodyMedium(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Nota ────────────────────────────────────────────────────────
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: 'Nota (opcional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // ── Cuenta de origen ────────────────────────────────────────────
              Text('Cuenta de origen', style: AppTypography.labelMedium()),
              const SizedBox(height: 8),
              if (_loadingAccounts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                _buildAccountSelector(),

              const SizedBox(height: 16),

              // ── Botón Analizar con IA ────────────────────────────────────────
              if (!_adviceFetched)
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _loadingAdvice ? null : _fetchAdvice,
                    icon: _loadingAdvice
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _loadingAdvice ? 'Analizando...' : 'Analizar con IA',
                      style: AppTypography.labelMedium(
                        color: AppColors.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

              // ── Tarjeta de consejo IA ────────────────────────────────────────
              if (_adviceFetched) _buildAdviceCard(),

              const SizedBox(height: 16),

              // ── Confirmar ───────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Confirmar aportación',
                    style: AppTypography.labelMedium(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _accounts.asMap().entries.map((entry) {
          final idx = entry.key;
          final acc = entry.value;
          final isSelected = _selectedAccount?.id == acc.id;
          final isLast = idx == _accounts.length - 1;
          return InkWell(
            onTap: () => setState(() => _selectedAccount = acc),
            borderRadius: BorderRadius.vertical(
              top: idx == 0 ? const Radius.circular(12) : Radius.zero,
              bottom: isLast ? const Radius.circular(12) : Radius.zero,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                border: isLast
                    ? null
                    : Border(bottom: BorderSide(color: AppColors.gray100)),
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(12) : Radius.zero,
                  bottom: isLast ? const Radius.circular(12) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.gray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      acc.icon,
                      size: 18,
                      color: isSelected ? AppColors.primary : AppColors.gray400,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(acc.name, style: AppTypography.labelMedium()),
                        Text(
                          acc.subtitle,
                          style: AppTypography.badge(
                            color: AppColors.textTertiaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdviceCard() {
    if (_advice == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.gray400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudo obtener el análisis IA. Puedes continuar igualmente.',
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final suggestion = _advice!['suggestion'] as String? ?? 'correct';
    final adviceText = _advice!['advice'] as String? ?? '';
    final needed = (_advice!['ahorro_necesario'] as num?)?.toDouble();

    Color color;
    IconData icon;
    switch (suggestion) {
      case 'increase':
        color = AppColors.error;
        icon = Icons.trending_up_rounded;
        break;
      case 'decrease':
        color = AppColors.warning;
        icon = Icons.trending_down_rounded;
        break;
      default:
        color = AppColors.success;
        icon = Icons.check_circle_outline_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  'Análisis IA',
                  style: AppTypography.labelMedium(color: color),
                ),
                const Spacer(),
                Icon(icon, size: 16, color: color),
              ],
            ),
            if (adviceText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                adviceText,
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
            if (needed != null && needed > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Necesario para cumplir el plazo: ${needed.toStringAsFixed(2)} €/mes',
                style: AppTypography.badge(color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
