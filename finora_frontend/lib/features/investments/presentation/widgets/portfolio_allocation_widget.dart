import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';

class PortfolioAllocationWidget extends StatelessWidget {
  final PortfolioSuggestionEntity suggestion;

  const PortfolioAllocationWidget({super.key, required this.suggestion});

  static const _categoryColors = {
    'bonds': Color(0xFF0284C7),
    'global_equity': Color(0xFF059669),
    'emerging_markets': Color(0xFFD97706),
    'money_market': Color(0xFF64748B),
    'sector': Color(0xFF7C3AED),
  };

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.suggestedPortfolio, style: AppTypography.titleSmall()),
              const SizedBox(height: 4),
              Text(
                s.portfolioRationale,
                style: AppTypography.bodySmall(color: AppColors.gray600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Visual allocation bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 24,
            child: Row(
              children: suggestion.portfolio.map((p) {
                final color = _categoryColors[p.category] ?? AppColors.primary;
                return Expanded(
                  flex: p.allocation,
                  child: Container(color: color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...suggestion.portfolio.map((p) {
          final color = _categoryColors[p.category] ?? AppColors.primary;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gray200),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.etf, style: AppTypography.bodyMedium()),
                      Text(
                        p.ticker,
                        style: AppTypography.labelSmall(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${p.allocation}%',
                    style: AppTypography.labelSmall(color: color),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
