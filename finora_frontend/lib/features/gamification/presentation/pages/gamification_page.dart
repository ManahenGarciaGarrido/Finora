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
import '../widgets/badge_grid.dart';
import '../../domain/entities/streak_entity.dart';
import '../../domain/entities/challenge_entity.dart';

class GamificationPage extends StatefulWidget {
  const GamificationPage({super.key});

  @override
  State<GamificationPage> createState() => _GamificationPageState();
}

class _GamificationPageState extends State<GamificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
      create: (ctx) =>
          di.sl<GamificationBloc>()..add(const LoadGamificationData()),
      child: BlocConsumer<GamificationBloc, GamificationState>(
        listener: (ctx, state) {
          if (state is BadgesAwarded && state.awarded.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${s.badgesTitle}: ${state.awarded.join(', ')}'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is ChallengeJoined) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.challengeComplete),
                backgroundColor: AppColors.success,
              ),
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
                      BadgeGrid(badges: state.badges),
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
          OutlinedButton.icon(
            onPressed: () =>
                ctx.read<GamificationBloc>().add(const CheckBadges()),
            icon: const Icon(Icons.emoji_events_rounded),
            label: Text(s.badgesTitle),
          ),
        ],
      ),
    );
  }

  Widget _buildStreaksTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    if (state.streaks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.gray400,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                s.noStreakYet,
                style: AppTypography.bodyMedium(color: AppColors.gray500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => ctx.read<GamificationBloc>().add(
                  const RecordStreak('daily_login'),
                ),
                child: Text(s.streakLabel),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.streaks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _streakCard(ctx, state.streaks[i], s),
    );
  }

  Widget _streakCard(BuildContext ctx, StreakEntity streak, dynamic s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
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
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  streak.streakType.replaceAll('_', ' ').toUpperCase(),
                  style: AppTypography.bodySmall(color: AppColors.gray500),
                ),
                Text(
                  '${streak.currentCount} ${s.streakWeeks}',
                  style: AppTypography.titleSmall(),
                ),
                Text(
                  '${s.longestStreak}: ${streak.longestCount}',
                  style: AppTypography.bodySmall(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => ctx.read<GamificationBloc>().add(
              RecordStreak(streak.streakType),
            ),
            child: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab(
    BuildContext ctx,
    GamificationLoaded state,
    dynamic s,
  ) {
    if (state.challenges.isEmpty) {
      return Center(
        child: Text(
          s.noData,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.challenges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _challengeCard(ctx, state.challenges[i], s),
    );
  }

  Widget _challengeCard(
    BuildContext ctx,
    ChallengeEntity challenge,
    dynamic s,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(challenge.title, style: AppTypography.titleSmall()),
              ),
              if (challenge.isCompleted)
                Icon(Icons.check_circle_rounded, color: AppColors.success)
              else if (!challenge.isJoined)
                TextButton(
                  onPressed: () => ctx.read<GamificationBloc>().add(
                    JoinChallenge(challenge.id),
                  ),
                  child: Text(s.joinChallenge),
                ),
            ],
          ),
          if (challenge.description != null) ...[
            const SizedBox(height: 4),
            Text(
              challenge.description!,
              style: AppTypography.bodySmall(color: AppColors.gray500),
            ),
          ],
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: challenge.progressPercent,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.progress.toStringAsFixed(0)} / ${challenge.targetValue.toStringAsFixed(0)}',
                style: AppTypography.bodySmall(color: AppColors.gray500),
              ),
              Text(
                '${challenge.rewardPoints} pts',
                style: AppTypography.bodySmall(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
