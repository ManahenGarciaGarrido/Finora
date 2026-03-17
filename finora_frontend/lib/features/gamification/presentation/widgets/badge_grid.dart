import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/badge_entity.dart';

class BadgeGrid extends StatelessWidget {
  final List<BadgeEntity> badges;
  const BadgeGrid({super.key, required this.badges});

  IconData _iconData(String? iconName) {
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

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) {
        final b = badges[i];
        final color = b.isEarned ? AppColors.primary : AppColors.gray400;
        return Container(
          decoration: BoxDecoration(
            color: b.isEarned ? AppColors.primarySoft : AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: b.isEarned ? AppColors.primary : AppColors.gray200,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconData(b.icon), color: color, size: 36),
              const SizedBox(height: 8),
              Text(
                b.name,
                style: AppTypography.bodySmall(color: color),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
