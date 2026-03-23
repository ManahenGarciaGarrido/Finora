import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Dialog de consentimiento PSD2 (HU-05, RNF-05).
///
/// Se muestra antes de iniciar la conexión bancaria para:
///  - Explicar claramente qué permisos solicita Finora (PSD2 SCA)
///  - Mostrar badges de seguridad (PSD2, cifrado, solo lectura)
///  - Obtener el consentimiento explícito del usuario
///
/// HU-05 AC: "Explicación clara de los permisos solicitados (PSD2 consent dialog)"
/// HU-05 AC: "Badges de seguridad visibles (PSD2, cifrado, acceso de solo lectura)"
class Psd2ConsentDialog extends StatelessWidget {
  final String bankName;

  const Psd2ConsentDialog({super.key, required this.bankName});

  /// Muestra el dialog y devuelve true si el usuario acepta, false si cancela.
  static Future<bool> show(BuildContext context, String bankName) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Psd2ConsentDialog(bankName: bankName),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Título
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.psd2SecureAccessTo(bankName),
                        style: AppTypography.titleMedium(),
                      ),
                      Text(
                        s.psd2ConsentLabel,
                        style: AppTypography.labelSmall(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Badges de seguridad
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _SecurityBadge(
                    icon: Icons.verified_user_rounded,
                    label: 'PSD2 Compliant',
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _SecurityBadge(
                    icon: Icons.lock_rounded,
                    label: s.tlsEncryptedLabel,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _SecurityBadge(
                    icon: Icons.visibility_outlined,
                    label: s.readOnlyLabel,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  _SecurityBadge(
                    icon: Icons.delete_sweep_outlined,
                    label: s.noDataStoredLabel,
                    color: AppColors.gray500,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              s.psd2RequestsAccess,
              style: AppTypography.bodyMedium(color: AppColors.gray500),
            ),
            const SizedBox(height: 12),

            // Permisos explicados
            _PermissionItem(
              icon: Icons.account_balance_outlined,
              title: s.bankAccountBalanceLabel,
              description: s.psd2BalanceDesc,
            ),
            const SizedBox(height: 10),
            _PermissionItem(
              icon: Icons.receipt_long_outlined,
              title: s.bankTransactionsLabel,
              description: s.psd2TransactionsDesc,
            ),
            const SizedBox(height: 10),
            _PermissionItem(
              icon: Icons.info_outline_rounded,
              title: s.bankAccountInfoLabel,
              description: s.psd2AccountInfoDesc,
            ),

            const SizedBox(height: 20),

            // Nota PSD2
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.update_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.psd2ConsentNote,
                      style: AppTypography.bodySmall(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.check_rounded),
                label: Text(s.authorizeContinue),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  s.cancel,
                  style: AppTypography.labelMedium(color: AppColors.gray500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SecurityBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.labelSmall(color: color)),
        ],
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.gray500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyMedium()),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.bodySmall(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
