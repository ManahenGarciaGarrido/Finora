import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';

const _kPrefKey = 'debts_tutorial_seen';

/// Returns true if the tutorial has already been shown to the user.
Future<bool> debtsTutorialAlreadySeen() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPrefKey) ?? false;
}

/// Marks the tutorial as seen.
Future<void> markDebtsTutorialSeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kPrefKey, true);
}

class DebtsTutorialPage extends StatefulWidget {
  const DebtsTutorialPage({super.key});

  @override
  State<DebtsTutorialPage> createState() => _DebtsTutorialPageState();
}

class _DebtsTutorialPageState extends State<DebtsTutorialPage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(AppLocalizations s) {
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await markDebtsTutorialSeen();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final steps = [
      _TutorialStep(
        icon: Icons.credit_score_rounded,
        color: const Color(0xFFE53935),
        title: s.debtsTutorialStep1Title,
        body: s.debtsTutorialStep1Body,
      ),
      _TutorialStep(
        icon: Icons.add_circle_outline_rounded,
        color: const Color(0xFF039BE5),
        title: s.debtsTutorialStep2Title,
        body: s.debtsTutorialStep2Body,
      ),
      _TutorialStep(
        icon: Icons.psychology_rounded,
        color: const Color(0xFF00897B),
        title: s.debtsTutorialStep3Title,
        body: s.debtsTutorialStep3Body,
      ),
      _TutorialStep(
        icon: Icons.calculate_rounded,
        color: const Color(0xFF6C63FF),
        title: s.debtsTutorialStep4Title,
        body: s.debtsTutorialStep4Body,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Saltar',
                  style: AppTypography.bodyMedium(color: AppColors.gray500),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: steps.length,
                itemBuilder: (_, i) => _buildStep(steps[i]),
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _page == i ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : AppColors.gray300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Next / Start button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _next(s),
                  child: Text(
                    _page < 3 ? s.onboardingNext : s.debtsTutorialStart,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_TutorialStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 56),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            style: AppTypography.titleLarge(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.body,
            style: AppTypography.bodyMedium(color: AppColors.gray600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TutorialStep {
  final IconData icon;
  final Color color;
  final String title;
  final String body;

  const _TutorialStep({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}
