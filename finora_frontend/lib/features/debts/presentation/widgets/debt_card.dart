import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../domain/entities/debt_entity.dart';

class DebtCard extends StatelessWidget {
  final DebtEntity debt;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const DebtCard({super.key, required this.debt, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final fmt = CurrencyService().format;
    final pct = debt.progressPercent.clamp(0.0, 100.0);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: debt.isOwn
                      ? AppColors.errorSoft
                      : AppColors.successSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  debt.isOwn
                      ? Icons.credit_card_rounded
                      : Icons.account_balance_wallet_rounded,
                  color: debt.isOwn ? AppColors.error : AppColors.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(debt.name, style: AppTypography.titleSmall()),
                    if (debt.creditorName != null)
                      Text(
                        debt.creditorName!,
                        style: AppTypography.bodySmall(
                          color: AppColors.gray500,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt(debt.remainingAmount),
                    style: AppTypography.titleSmall(
                      color: debt.isOwn ? AppColors.error : AppColors.success,
                    ),
                  ),
                  Text(
                    s.remainingAmount,
                    style: AppTypography.labelSmall(color: AppColors.gray400),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.gray100,
              valueColor: AlwaysStoppedAnimation<Color>(
                debt.isOwn ? AppColors.error : AppColors.success,
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${pct.toStringAsFixed(0)}% ${s.completed}',
                style: AppTypography.labelSmall(color: AppColors.gray500),
              ),
              if (debt.interestRate > 0)
                Text(
                  '${debt.interestRate.toStringAsFixed(1)}% ${s.annualRate}',
                  style: AppTypography.labelSmall(color: AppColors.gray500),
                ),
            ],
          ),
          if (onEdit != null || onDelete != null) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(s.edit),
                  ),
                if (onDelete != null)
                  TextButton.icon(
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.error,
                    ),
                    label: Text(
                      s.delete,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
