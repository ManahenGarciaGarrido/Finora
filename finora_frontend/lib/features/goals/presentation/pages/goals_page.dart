import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../bloc/goal_bloc.dart';
import '../bloc/goal_event.dart';
import '../bloc/goal_state.dart';
import 'create_goal_page.dart';
import 'goal_detail_page.dart';

/// RF-18 / RF-19 / HU-07: Lista de objetivos de ahorro con progreso visual
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<GoalBloc>()..add(const LoadGoals()),
      child: const _GoalsView(),
    );
  }
}

class _GoalsView extends StatelessWidget {
  const _GoalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text('Objetivos de ahorro', style: AppTypography.titleMedium()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Nuevo objetivo',
            onPressed: () => _openCreateGoal(context),
          ),
        ],
      ),
      body: BlocConsumer<GoalBloc, GoalState>(
        listener: (context, state) {
          if (state is GoalCreated) {
            context.read<GoalBloc>().add(const LoadGoals());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Objetivo "${state.goal.name}" creado'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is GoalDeleted) {
            context.read<GoalBloc>().add(const LoadGoals());
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
          if (state is GoalLoading || state is GoalInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is GoalsLoaded) {
            if (state.goals.isEmpty) {
              return _EmptyGoals(onTap: () => _openCreateGoal(context));
            }
            return _GoalsList(goals: state.goals);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGoal(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Nuevo objetivo',
          style: AppTypography.labelMedium(color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _openCreateGoal(BuildContext context) async {
    final bloc = context.read<GoalBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            BlocProvider.value(value: bloc, child: const CreateGoalPage()),
      ),
    );
  }
}

// ─── Lista de objetivos ────────────────────────────────────────────────────────

class _GoalsList extends StatelessWidget {
  final List<SavingsGoalEntity> goals;
  const _GoalsList({required this.goals});

  @override
  Widget build(BuildContext context) {
    final active = goals.where((g) => g.isActive).toList();
    final completed = goals.where((g) => g.isCompleted).toList();

    return RefreshIndicator(
      onRefresh: () async {
        context.read<GoalBloc>().add(const LoadGoals());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (active.isNotEmpty) ...[
            _SectionLabel('En progreso (${active.length})'),
            ...active.map((g) => _GoalCard(goal: g)),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 8),
            _SectionLabel('Completados (${completed.length})'),
            ...completed.map((g) => _GoalCard(goal: g)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
      ),
    );
  }
}

// ─── Tarjeta de objetivo (HU-07: colores dinámicos, icono, progreso) ───────────

class _GoalCard extends StatelessWidget {
  final SavingsGoalEntity goal;
  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context) {
    final progressColor = Color(
      int.parse(goal.progressColor.replaceAll('#', 'FF'), radix: 16),
    );
    final goalColor = Color(
      int.parse(goal.color.replaceAll('#', 'FF'), radix: 16),
    );

    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gray100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono del objetivo (HU-07: personalizable)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconData(goal.icon), color: goalColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.name,
                              style: AppTypography.titleSmall(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '✓ Completado',
                                style: AppTypography.badge(
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatCurrency(goal.currentAmount)} de ${_formatCurrency(goal.targetAmount)}',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                // Porcentaje
                Text(
                  '${goal.percentage}%',
                  style: AppTypography.titleSmall(color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Barra de progreso (HU-07: color dinámico)
            Semantics(
              label: 'Progreso del objetivo: ${goal.percentage}%',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.percentageDecimal),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor: AppColors.gray100,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
            ),
            // Fila inferior: fecha límite + cantidad restante
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (goal.deadline != null)
                  Text(
                    'Meta: ${_formatDate(goal.deadline!)}',
                    style: AppTypography.badge(
                      color: AppColors.textTertiaryLight,
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Text(
                  'Faltan ${_formatCurrency(goal.remainingAmount)}',
                  style: AppTypography.badge(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    final bloc = context.read<GoalBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: GoalDetailPage(goal: goal),
        ),
      ),
    );
    bloc.add(const LoadGoals());
  }

  static String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} €';
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static IconData _iconData(String icon) =>
      _goalIcons[icon] ?? Icons.savings_rounded;
}

// ─── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyGoals extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyGoals({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text('Sin objetivos todavía', style: AppTypography.titleMedium()),
            const SizedBox(height: 8),
            Text(
              'Crea tu primer objetivo de ahorro\ny la IA te ayudará a alcanzarlo.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Crear objetivo',
                style: AppTypography.labelMedium(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Iconos disponibles (HU-07: iconos personalizables) ──────────────────────

const Map<String, IconData> _goalIcons = {
  'house': Icons.home_rounded,
  'car': Icons.directions_car_rounded,
  'travel': Icons.flight_rounded,
  'education': Icons.school_rounded,
  'emergency': Icons.health_and_safety_rounded,
  'wedding': Icons.favorite_rounded,
  'tech': Icons.devices_rounded,
  'business': Icons.business_center_rounded,
  'health': Icons.local_hospital_rounded,
  'retirement': Icons.beach_access_rounded,
  'gift': Icons.card_giftcard_rounded,
  'other': Icons.savings_rounded,
};

/// Exportado para uso en CreateGoalPage y GoalDetailPage
const goalIconsMap = _goalIcons;
