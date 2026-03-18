import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/health_score_entity.dart';

class HealthScoreGauge extends StatelessWidget {
  final HealthScoreEntity score;
  const HealthScoreGauge({super.key, required this.score});

  Color get _gradeColor {
    if (score.score >= 80) return AppColors.success;
    if (score.score >= 60) return AppColors.primary;
    if (score.score >= 40) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Text(s.healthScore, style: AppTypography.titleSmall()),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: score.score / 100,
                  strokeWidth: 12,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(_gradeColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.score}',
                    style: AppTypography.displaySmall(color: _gradeColor),
                  ),
                  Text(
                    score.grade,
                    style: AppTypography.titleSmall(color: _gradeColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(s.healthScoreBreakdown, style: AppTypography.titleSmall()),
          const SizedBox(height: 12),
          _bar(context, s.budgetComplianceComponent, score.budgetAdherence),
          const SizedBox(height: 8),
          _bar(context, s.savingsRateComponent, score.savingsRate),
          const SizedBox(height: 8),
          _bar(context, s.goalsProgressComponent, score.goalProgress),
          const SizedBox(height: 8),
          _bar(context, s.streakLabel, score.streakBonus),
        ],
      ),
    );
  }

  Widget _bar(BuildContext context, String label, int value) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTypography.bodySmall(color: AppColors.gray600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 8,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$value', style: AppTypography.bodySmall()),
      ],
    );
  }
}
