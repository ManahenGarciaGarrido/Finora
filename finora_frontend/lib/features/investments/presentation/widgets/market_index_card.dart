import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/market_index_entity.dart';

class MarketIndexCard extends StatelessWidget {
  final MarketIndexEntity index;

  const MarketIndexCard({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = index.isPositive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(index.name, style: AppTypography.titleSmall()),
                Text(
                  index.ticker,
                  style: AppTypography.labelSmall(color: AppColors.gray500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                index.value >= 1000
                    ? index.value.toStringAsFixed(2)
                    : index.value.toStringAsFixed(4),
                style: AppTypography.titleSmall(),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    index.isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: color,
                    size: 12,
                  ),
                  Text(
                    '${index.change.abs().toStringAsFixed(2)}%',
                    style: AppTypography.labelSmall(color: color),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
