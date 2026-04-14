import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/currency_service.dart';

class StrategyComparisonWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const StrategyComparisonWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;
    final snowball = data['snowball'] as Map<String, dynamic>?;
    final avalanche = data['avalanche'] as Map<String, dynamic>?;

    if (snowball == null && avalanche == null) {
      return Center(
        child: Text(
          s.noDebts,
          style: AppTypography.bodyMedium(color: AppColors.gray500),
        ),
      );
    }

    final snowballInterest = snowball != null
        ? (snowball['total_interest'] as num).toDouble()
        : 0.0;
    final avalancheInterest = avalanche != null
        ? (avalanche['total_interest'] as num).toDouble()
        : 0.0;
    final savings = (snowballInterest - avalancheInterest).abs();
    final avalancheBetter = avalancheInterest <= snowballInterest;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (savings > 0)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  color: AppColors.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.recommendedStrategy,
                        style: AppTypography.labelSmall(
                          color: AppColors.successDark,
                        ),
                      ),
                      Text(
                        avalancheBetter
                            ? s.avalancheStrategy
                            : s.snowballStrategy,
                        style: AppTypography.titleSmall(
                          color: AppColors.successDark,
                        ),
                      ),
                      Text(
                        '${s.interestSavings}: ${fmt(savings)}',
                        style: AppTypography.bodySmall(
                          color: AppColors.successDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        _buildStrategyCard(
          context,
          s.snowballStrategy,
          s.snowballDesc,
          snowball,
          Icons.savings_rounded,
          AppColors.info,
          avalancheBetter ? false : true,
        ),
        const SizedBox(height: 12),
        _buildStrategyCard(
          context,
          s.avalancheStrategy,
          s.avalancheDesc,
          avalanche,
          Icons.ac_unit_rounded,
          AppColors.warning,
          avalancheBetter ? true : false,
        ),
      ],
    );
  }

  Widget _buildStrategyCard(
    BuildContext context,
    String title,
    String desc,
    Map<String, dynamic>? strategy,
    IconData icon,
    Color color,
    bool recommended,
  ) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommended ? color.withValues(alpha: 0.5) : AppColors.gray200,
          width: recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTypography.titleSmall(color: color), overflow: TextOverflow.ellipsis)),
              if (recommended) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    s.recommendedStrategy,
                    style: AppTypography.labelSmall(color: color),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: AppTypography.bodySmall(color: AppColors.gray500)),
          if (strategy != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _stat(
                  context,
                  s.totalInterest,
                  fmt((strategy['total_interest'] as num).toDouble()),
                ),
                const SizedBox(width: 16),
                _stat(
                  context,
                  s.monthsToPayoff,
                  '${strategy['months_to_payoff']}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              s.paymentOrder,
              style: AppTypography.labelSmall(color: AppColors.gray500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (int i = 0; i < (strategy['order'] as List).length; i++)
                  Chip(
                    label: Text(
                      '${i + 1}. ${strategy['order'][i]}',
                      style: AppTypography.labelSmall(),
                    ),
                    backgroundColor: AppColors.gray100,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelSmall(color: AppColors.gray500)),
        Text(value, style: AppTypography.titleSmall()),
      ],
    );
  }
}
