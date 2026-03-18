import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../shared/widgets/skeleton_loader.dart';
import '../bloc/gamification_bloc.dart';
import '../bloc/gamification_event.dart';
import '../bloc/gamification_state.dart';
import '../widgets/health_score_gauge.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../../domain/entities/challenge_entity.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabs;

  /// Bloc gestionado aquí para poder accederlo desde el observer de ciclo de vida
  late GamificationBloc _bloc;

  /// Timer que refresca los retos periódicamente (cada 24 horas)
  Timer? _refreshTimer;

  /// Registra los retos ya completados para detectar nuevas completaciones
  final Set<String> _previouslyCompleted = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _bloc = di.sl<GamificationBloc>()..add(const LoadGamificationData());
    WidgetsBinding.instance.addObserver(this);
    // Refrescar retos cada 24 horas para mostrar nuevos retos periódicos
    _refreshTimer = Timer.periodic(const Duration(hours: 24), (_) {
      if (mounted) _bloc.add(const LoadGamificationData());
    });
  }

  /// Auto-refresh cuando el usuario vuelve a la app (desde background)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _bloc.add(const LoadGamificationData());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _tabs.dispose();
    _bloc.close();
    super.dispose();
  }

  /// Muestra un diálogo cuando se consigue un logro o se completa un reto
  void _showAchievementDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.titleMedium(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium(color: AppColors.gray500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('¡Genial!'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (ctx, state) {
          if (state is BadgesAwarded && state.awarded.isNotEmpty) {
            // Mostrar diálogo en lugar de SnackBar verde
            _showAchievementDialog(
              context,
              '¡${s.badgesTitle} desbloqueados!',
              state.awarded.join(', '),
            );
          } else if (state is ChallengeJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '¡Te has unido al reto! Complétalo para ganar puntos.',
                ),
                backgroundColor: AppColors.primary,
              ),
            );
          } else if (state is GamificationLoaded) {
            // Detectar retos recién completados
            for (final ch in state.challenges) {
              if (ch.isCompleted && !_previouslyCompleted.contains(ch.id)) {
                _previouslyCompleted.add(ch.id);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _showAchievementDialog(
                      context,
                      s.challengeComplete,
                      '${ch.title}\n+${ch.rewardPoints} puntos',
                    );
                  }
                });
              }
            }
            // Actualizar el registro de completados anteriores
            _previouslyCompleted
              ..clear()
              ..addAll(
                state.challenges.where((c) => c.isCompleted).map((c) => c.id),
              );
          } else if (state is GamificationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (ctx, state) {
          return Scaffold(
            backgroundColor: AppColors.backgroundLight,
            appBar: AppBar(
              backgroundColor: AppColors.surfaceLight,
              elevation: 0,
              title: Text(
                s.gamificationTitle,
                style: AppTypography.titleMedium(),
              ),
              leading: const BackButton(),
              bottom: TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: s.healthScore),
                  Tab(text: s.streakLabel),
                  Tab(text: s.badgesTitle),
                  Tab(text: s.challengesTitle),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ctx.read<GamificationBloc>().add(
                    const LoadGamificationData(),
                  ),
                ),
              ],
            ),
            body: state is GamificationLoading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: SkeletonListLoader(count: 4, cardHeight: 80),
                  )
                : state is GamificationLoaded
                ? TabBarView(
                    controller: _tabs,
                    children: [
                      _buildHealthTab(ctx, state, s),
                      _buildStreaksTab(ctx, state, s),
                      _buildBadgesTab(ctx, state, s),
                      _buildChallengesTab(ctx, state, s),
                    ],
                  )
                : Center(
                    child: Text(
                      state is GamificationError ? state.message : s.noData,
                      style: AppTypography.bodyMedium(color: AppColors.gray500),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildHealthTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    if (state.healthScore == null) {
      return Center(
        child: Text(
          s.noData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          HealthScoreGauge(score: state.healthScore!),
          const SizedBox(height: 16),
          // Botón para comprobar logros va a la pestaña de logros
          FilledButton.icon(
            onPressed: () {
              ctx.read<GamificationBloc>().add(const CheckBadges());
              _tabs.animateTo(2);
            },
            icon: const Icon(Icons.emoji_events_rounded),
            label: Text('Ver ${s.badgesTitle}'),
          ),
        ],
      ),
    );
  }

  // ── RACHAS ─────────────────────────────────────────────────────────────────

  Widget _buildStreaksTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta informativa sobre rachas
          _infoCard(
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF6B35),
            title: '¿Qué es una racha?',
            body:
                'Una racha mide tu constancia financiera. '
                'Cada vez que registras un período con ahorro positivo (gastos < ingresos) '
                'o cumples el hábito del tipo de racha, tu contador sube. '
                'Si lo rompes, vuelve a 0. ¡Sé constante!',
          ),
          const SizedBox(height: 16),
          if (state.streaks.isEmpty)
            _emptyStreakCard(ctx, s)
          else ...[
            Text('Tus rachas activas', style: AppTypography.titleSmall()),
            const SizedBox(height: 12),
            ...state.streaks.map(
              (streak) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _streakCard(ctx, streak, s),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Qué puedes conseguir
          _infoCard(
            icon: Icons.emoji_events_rounded,
            color: AppColors.primary,
            title: '¿Qué puedes conseguir?',
            body:
                '• 4 semanas seguidas → Logro "Constante"\n'
                '• 8 semanas seguidas → Logro "Disciplinado"\n'
                '• 12 semanas seguidas → Logro "Experto del ahorro"\n'
                'Cuanto más larga tu racha, más puntos y logros desbloqueas.',
          ),
        ],
      ),
    );
  }

  Widget _emptyStreakCard(BuildContext ctx, dynamic s) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.gray300,
            size: 56,
          ),
          const SizedBox(height: 12),
          Text(
            s.noStreakYet,
            style: AppTypography.titleSmall(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Registra un período con más ingresos que gastos para empezar tu racha.',
            style: AppTypography.bodySmall(color: AppColors.gray500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => ctx.read<GamificationBloc>().add(
              const RecordStreak('daily_login'),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Iniciar racha'),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(BuildContext ctx, StreakEntity streak, dynamic s) {
    final streakTypeLabel = _streakTypeLabel(streak.streakType);
    final streakTypeDesc = _streakTypeDescription(streak.streakType);
    final nextMilestone = _nextMilestone(streak.currentCount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(streakTypeLabel, style: AppTypography.titleSmall()),
                    Text(
                      streakTypeDesc,
                      style: AppTypography.bodySmall(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _statCell(
                icon: Icons.whatshot_rounded,
                label: 'Racha actual',
                value: '${streak.currentCount} sem.',
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              _statCell(
                icon: Icons.military_tech_rounded,
                label: s.longestStreak,
                value: '${streak.longestCount} sem.',
                color: const Color(0xFFFF8F00),
              ),
              if (streak.lastActivityDate != null) ...[
                const SizedBox(width: 12),
                _statCell(
                  icon: Icons.event_rounded,
                  label: 'Última actividad',
                  value: streak.lastActivityDate!.substring(0, 10),
                  color: AppColors.gray500,
                ),
              ],
            ],
          ),
          // Próximo hito
          if (nextMilestone != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Próximo hito: $nextMilestone semanas — '
                      'te faltan ${nextMilestone - streak.currentCount} sem.',
                      style: AppTypography.bodySmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () => ctx.read<GamificationBloc>().add(
              RecordStreak(streak.streakType),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Registrar semana'),
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleSmall(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: color.withValues(alpha: 0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _streakTypeLabel(String type) {
    switch (type) {
      case 'daily_login':
        return 'Acceso diario';
      case 'weekly_saving':
        return 'Ahorro semanal';
      case 'budget_compliance':
        return 'Cumplimiento de presupuesto';
      case 'no_impulse_buy':
        return 'Sin compras impulsivas';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _streakTypeDescription(String type) {
    switch (type) {
      case 'daily_login':
        return 'Abre la app cada día para mantener esta racha activa.';
      case 'weekly_saving':
        return 'Cada semana con más ingresos que gastos suma 1 a la racha.';
      case 'budget_compliance':
        return 'Cumple tu presupuesto mensual sin excederte.';
      case 'no_impulse_buy':
        return 'No registres compras no planificadas durante períodos consecutivos.';
      default:
        return 'Mantén el hábito financiero de forma constante.';
    }
  }

  int? _nextMilestone(int current) {
    const milestones = [4, 8, 12, 24, 52];
    for (final m in milestones) {
      if (current < m) return m;
    }
    return null;
  }

  // ── LOGROS (BADGES) ────────────────────────────────────────────────────────

  Widget _buildBadgesTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    final earned = state.badges.where((b) => b.isEarned).toList();
    final locked = state.badges.where((b) => !b.isEarned).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Resumen
        Row(
          children: [
            _badgeSummaryChip(
              label: '${earned.length} ${s.badgesEarned}',
              color: AppColors.primary,
              icon: Icons.check_circle_rounded,
            ),
            const SizedBox(width: 8),
            _badgeSummaryChip(
              label: '${locked.length} ${s.badgesLocked}',
              color: AppColors.gray400,
              icon: Icons.lock_rounded,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Botón comprobar logros
        OutlinedButton.icon(
          onPressed: () =>
              ctx.read<GamificationBloc>().add(const CheckBadges()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Comprobar nuevos logros'),
        ),
        const SizedBox(height: 20),
        if (earned.isNotEmpty) ...[
          Text(
            s.badgesEarned,
            style: AppTypography.titleSmall(color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          ...earned.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _badgeListTile(b, s, earned: true),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          s.badgesLocked,
          style: AppTypography.titleSmall(color: AppColors.gray500),
        ),
        const SizedBox(height: 4),
        Text(
          'Completa estos objetivos para desbloquear los logros.',
          style: AppTypography.bodySmall(color: AppColors.gray400),
        ),
        const SizedBox(height: 12),
        if (locked.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '¡Has conseguido todos los logros disponibles! 🏆',
                style: AppTypography.bodyMedium(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...locked.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _badgeListTile(b, s, earned: false),
            ),
          ),
      ],
    );
  }

  Widget _badgeSummaryChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.bodySmall(color: color)),
        ],
      ),
    );
  }

  Widget _badgeListTile(BadgeEntity badge, dynamic s, {required bool earned}) {
    final color = earned ? AppColors.primary : AppColors.gray400;
    final howToEarn = _badgeHowToEarn(badge.badgeKey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: earned ? AppColors.primarySoft : AppColors.gray100,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: earned
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: earned ? AppColors.primary : AppColors.gray300,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _badgeIconData(badge.icon),
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.name,
                        style: AppTypography.titleSmall(color: color),
                      ),
                    ),
                    if (earned)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                  ],
                ),
                if (badge.description != null &&
                    badge.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    badge.description!,
                    style: AppTypography.bodySmall(color: AppColors.gray600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (!earned && howToEarn != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: AppColors.gray500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Cómo conseguirlo: $howToEarn',
                          style: AppTypography.bodySmall(
                            color: AppColors.gray500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (earned && badge.earnedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Conseguido el ${badge.earnedAt!.substring(0, 10)}',
                    style: AppTypography.bodySmall(color: AppColors.gray500),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _badgeIconData(String? iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'military_tech':
        return Icons.military_tech_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'whatshot':
        return Icons.whatshot_rounded;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  String? _badgeHowToEarn(String key) {
    switch (key) {
      case 'first_transaction':
        return 'Registra tu primera transacción.';
      case 'streak_4':
      case 'streak_4_weeks':
        return 'Mantén una racha de ahorro positivo durante 4 semanas consecutivas.';
      case 'streak_8':
      case 'streak_8_weeks':
        return 'Mantén una racha de ahorro positivo durante 8 semanas consecutivas.';
      case 'streak_12':
      case 'streak_12_weeks':
        return 'Mantén una racha de ahorro positivo durante 12 semanas consecutivas.';
      case 'budget_master':
        return 'Cumple tu presupuesto durante 3 meses consecutivos.';
      case 'savings_goal':
        return 'Alcanza el 100% de un objetivo de ahorro.';
      case 'challenge_complete':
        return 'Completa cualquier reto financiero.';
      case 'no_debt':
        return 'Liquida todas tus deudas registradas.';
      case 'investor':
        return 'Conecta tu perfil de inversión y sigue una sugerencia de cartera.';
      default:
        return null;
    }
  }

  // ── HELPERS PARA RETOS PERIÓDICOS ─────────────────────────────────────────

  /// Devuelve "Semanal", "Mensual" o "Trimestral" según la duración del reto
  String _challengePeriodLabel(ChallengeEntity ch) {
    if (ch.startsAt == null || ch.endsAt == null) return '';
    final start = DateTime.tryParse(ch.startsAt!);
    final end = DateTime.tryParse(ch.endsAt!);
    if (start == null || end == null) return '';
    final days = end.difference(start).inDays;
    if (days <= 7) return 'Semanal';
    if (days <= 31) return 'Mensual';
    return 'Trimestral';
  }

  /// True si el reto comenzó hace menos de 7 días
  bool _isNewChallenge(ChallengeEntity ch) {
    if (ch.startsAt == null) return false;
    final start = DateTime.tryParse(ch.startsAt!);
    if (start == null) return false;
    return DateTime.now().difference(start).inDays <= 7;
  }

  /// True si el reto expira en las próximas 48 horas
  bool _expiresSoon(ChallengeEntity ch) {
    if (ch.endsAt == null) return false;
    final end = DateTime.tryParse(ch.endsAt!);
    if (end == null) return false;
    final remaining = end.difference(DateTime.now());
    return remaining.inHours >= 0 && remaining.inDays <= 2;
  }

  // ── RETOS (CHALLENGES) ────────────────────────────────────────────────────

  Widget _buildChallengesTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Banner informativo sobre cómo funcionan los retos
        _infoCard(
          icon: Icons.flag_rounded,
          color: const Color(0xFF00897B),
          title: '¿Cómo funcionan los retos?',
          body:
              '• Los retos son objetivos financieros temporales.\n'
              '• Únete a un reto activo pulsando "Unirse".\n'
              '• Completa el objetivo antes de que termine el plazo.\n'
              '• Al completarlo recibirás una notificación y puntos de recompensa.\n'
              '• Los puntos mejoran tu puntuación de salud financiera.',
        ),
        const SizedBox(height: 16),
        // Info de actualización periódica
        _infoCard(
          icon: Icons.update_rounded,
          color: AppColors.gray500,
          title: 'Actualización automática',
          body:
              'Los retos se actualizan automáticamente cada semana/mes. '
              'La app comprueba nuevos retos al abrirse y cada 24 horas en segundo plano.',
        ),
        const SizedBox(height: 16),
        if (state.challenges.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.gray300,
                    size: 56,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.noData,
                    style: AppTypography.bodyMedium(color: AppColors.gray500),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Los retos se añaden periódicamente. Vuelve pronto.',
                    style: AppTypography.bodySmall(color: AppColors.gray400),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => ctx.read<GamificationBloc>().add(
                      const LoadGamificationData(),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Buscar retos nuevos'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Retos activos (en curso o sin unirse)
          if (state.challenges.any((c) => c.isActive && !c.isCompleted)) ...[
            Text(
              'Retos activos',
              style: AppTypography.titleSmall(color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            ...state.challenges
                .where((c) => c.isActive && !c.isCompleted)
                .map(
                  (ch) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _challengeCard(ctx, ch, s),
                  ),
                ),
            const SizedBox(height: 8),
          ],
          // Retos completados
          if (state.challenges.any((c) => c.isCompleted)) ...[
            Text(
              'Completados',
              style: AppTypography.titleSmall(color: AppColors.success),
            ),
            const SizedBox(height: 8),
            ...state.challenges
                .where((c) => c.isCompleted)
                .map(
                  (ch) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _challengeCard(ctx, ch, s),
                  ),
                ),
          ],
        ],
      ],
    );
  }

  Widget _challengeCard(
    BuildContext ctx,
    ChallengeEntity challenge,
    dynamic s,
  ) {
    final challengeTypeLabel = _challengeTypeLabel(challenge.challengeType);
    final challengeTypeDesc = _challengeTypeDescription(
      challenge.challengeType,
      challenge.targetValue,
    );
    final periodLabel = _challengePeriodLabel(challenge);
    final isNew = _isNewChallenge(challenge);
    final expiresSoon = _expiresSoon(challenge);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: challenge.isCompleted
              ? AppColors.success.withValues(alpha: 0.5)
              : challenge.isJoined
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: challenge.isCompleted
                      ? AppColors.successSoft
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  challenge.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.flag_rounded,
                  color: challenge.isCompleted
                      ? AppColors.success
                      : AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: AppTypography.titleSmall()),
                    Text(
                      challengeTypeLabel,
                      style: AppTypography.labelSmall(color: AppColors.gray500),
                    ),
                  ],
                ),
              ),
              // Estado del reto
              if (challenge.isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Completado',
                    style: AppTypography.bodySmall(color: AppColors.success),
                  ),
                )
              else if (challenge.isJoined)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'En curso',
                    style: AppTypography.bodySmall(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          // Fila de badges: periodo + nuevo + expira pronto
          if (periodLabel.isNotEmpty || isNew || expiresSoon) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (periodLabel.isNotEmpty)
                  _challengeBadge(periodLabel, AppColors.primary),
                if (isNew && !challenge.isCompleted)
                  _challengeBadge('Nuevo', const Color(0xFF00897B)),
                if (expiresSoon && !challenge.isCompleted)
                  _challengeBadge('Expira pronto', AppColors.error),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Descripción del reto
          if (challenge.description != null &&
              challenge.description!.isNotEmpty)
            Text(
              challenge.description!,
              style: AppTypography.bodySmall(color: AppColors.gray600),
            ),
          const SizedBox(height: 6),
          // Explicación de cómo se consigue
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: AppColors.gray600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    challengeTypeDesc,
                    style: AppTypography.bodySmall(color: AppColors.gray600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Barra de progreso
          LinearProgressIndicator(
            value: challenge.progressPercent,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(
              challenge.isCompleted ? AppColors.success : AppColors.primary,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.progress.toStringAsFixed(0)} / ${challenge.targetValue.toStringAsFixed(0)}',
                style: AppTypography.bodySmall(color: AppColors.gray500),
              ),
              Row(
                children: [
                  Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.rewardPoints} puntos',
                    style: AppTypography.bodySmall(color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
          // Fechas
          if (challenge.startsAt != null || challenge.endsAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 4),
                Text(
                  _challengeDateRange(challenge),
                  style: AppTypography.bodySmall(color: AppColors.gray400),
                ),
              ],
            ),
          ],
          // Botón unirse
          if (!challenge.isJoined && !challenge.isCompleted) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  ctx.read<GamificationBloc>().add(JoinChallenge(challenge.id)),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(s.joinChallenge),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _challengeBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: AppTypography.bodySmall(color: color)),
    );
  }

  String _challengeTypeLabel(String type) {
    switch (type) {
      case 'savings':
        return 'Reto de ahorro';
      case 'budget':
        return 'Reto de presupuesto';
      case 'no_spending':
        return 'Reto sin gastos extra';
      case 'streak':
        return 'Reto de racha';
      case 'goal':
        return 'Reto de objetivo';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  String _challengeTypeDescription(String type, double target) {
    switch (type) {
      case 'savings':
        return 'Ahorra al menos ${target.toStringAsFixed(0)}€ durante el período del reto. '
            'Cada vez que registres un ingreso o reduzcas gastos, avanzas.';
      case 'budget':
        return 'Mantén tus gastos dentro del presupuesto establecido durante el período completo.';
      case 'no_spending':
        return 'Evita registrar gastos no esenciales durante ${target.toStringAsFixed(0)} días.';
      case 'streak':
        return 'Mantén una racha de ahorro positivo durante ${target.toStringAsFixed(0)} semanas consecutivas.';
      case 'goal':
        return 'Alcanza el ${target.toStringAsFixed(0)}% de progreso en uno de tus objetivos de ahorro.';
      default:
        return 'Completa el objetivo indicado antes de que finalice el reto para ganar los puntos.';
    }
  }

  String _challengeDateRange(ChallengeEntity challenge) {
    final start = challenge.startsAt?.substring(0, 10) ?? '';
    final end = challenge.endsAt?.substring(0, 10) ?? '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start → $end';
    if (end.isNotEmpty) return 'Hasta $end';
    if (start.isNotEmpty) return 'Desde $start';
    return '';
  }

  // ── TARJETA INFORMATIVA GENÉRICA ───────────────────────────────────────────

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleSmall(color: color)),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: AppTypography.bodySmall(color: AppColors.gray700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
