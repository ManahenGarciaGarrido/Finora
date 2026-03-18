import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// Tutorial de primera conexión bancaria (HU-05).
///
/// Se muestra automáticamente la primera vez que el usuario intenta
/// conectar un banco, explicando el proceso paso a paso.
///
/// HU-05 AC: "Tutorial opcional para la primera conexión bancaria"
/// HU-05 AC: "Proceso guiado paso a paso"
class BankConnectionTutorial extends StatefulWidget {
  const BankConnectionTutorial({super.key});

  static const _prefKey = 'bank_tutorial_shown';

  /// Muestra el tutorial si no se ha mostrado antes.
  /// Devuelve true si el usuario quiere continuar, false si cancela.
  static Future<bool> showIfNeeded(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool(_prefKey) ?? false;

    if (shown) return true; // Ya se mostró → continuar sin tutorial

    if (!context.mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => const BankConnectionTutorial(),
    );

    await prefs.setBool(_prefKey, true);
    return result ?? false;
  }

  @override
  State<BankConnectionTutorial> createState() => _BankConnectionTutorialState();
}

class _BankConnectionTutorialState extends State<BankConnectionTutorial> {
  int _currentStep = 0;

  List<_TutorialStep> _buildSteps(AppLocalizations s) => [
    _TutorialStep(
      icon: Icons.account_balance_rounded,
      title: s.tutorialStep1Title,
      description: s.tutorialStep1Desc,
      color: AppColors.primary,
    ),
    _TutorialStep(
      icon: Icons.search_rounded,
      title: s.tutorialStep2Title,
      description: s.tutorialStep2Desc,
      color: AppColors.info,
    ),
    _TutorialStep(
      icon: Icons.verified_user_rounded,
      title: s.tutorialStep3Title,
      description: s.tutorialStep3Desc,
      color: AppColors.success,
    ),
    _TutorialStep(
      icon: Icons.sync_rounded,
      title: s.tutorialStep4Title,
      description: s.tutorialStep4Desc,
      color: AppColors.warning,
    ),
    _TutorialStep(
      icon: Icons.lock_outline_rounded,
      title: s.tutorialStep5Title,
      description: s.tutorialStep5Desc,
      color: AppColors.secondary,
    ),
  ];

  void _next(int stepsLength) {
    if (_currentStep < stepsLength - 1) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context, true);
    }
  }

  void _skip() => Navigator.pop(context, true);
  void _cancel() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final steps = _buildSteps(s);
    final step = steps[_currentStep];
    final isLast = _currentStep == steps.length - 1;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Step indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _currentStep ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _currentStep
                        ? AppColors.primary
                        : AppColors.gray200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Icono animado
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_currentStep),
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: step.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 40, color: step.color),
              ),
            ),

            const SizedBox(height: 24),

            // Título
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                key: ValueKey('title_$_currentStep'),
                step.title,
                style: AppTypography.titleLarge(),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 12),

            // Descripción
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                key: ValueKey('desc_$_currentStep'),
                step.description,
                style: AppTypography.bodyMedium(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Botones
            Row(
              children: [
                // Cancelar / Saltar
                if (_currentStep == 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(s.cancel),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _skip,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(s.skipTutorial),
                    ),
                  ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton(
                    onPressed: () => _next(steps.length),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(isLast ? s.tutorialStart : s.next),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
