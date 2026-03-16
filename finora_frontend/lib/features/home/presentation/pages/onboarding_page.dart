library;

import 'package:finora_frontend/features/authentication/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Generamos la lista de páginas dinámicamente para usar las traducciones
  List<_OnboardingData> _getPages(AppLocalizations s) {
    return [
      _OnboardingData(
        icon: Icons.account_balance_wallet_rounded,
        iconColor: AppColors.primary,
        bgColor: AppColors.primarySoft,
        title: s.onboardingStep1Title,
        subtitle: s.onboardingStep1Subtitle,
        description: s.onboardingStep1Description,
      ),
      _OnboardingData(
        icon: Icons.add_circle_rounded,
        iconColor: AppColors.success,
        bgColor: AppColors.successSoft,
        title: s.onboardingStep2Title,
        subtitle: s.onboardingStep2Subtitle,
        description: s.onboardingStep2Description,
      ),
      _OnboardingData(
        icon: Icons.insights_rounded,
        iconColor: AppColors.info,
        bgColor: AppColors.infoSoft,
        title: s.onboardingStep3Title,
        subtitle: s.onboardingStep3Subtitle,
        description: s.onboardingStep3Description,
      ),
      _OnboardingData(
        icon: Icons.savings_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFFEDE9FE),
        title: s.onboardingStep4Title,
        subtitle: s.onboardingStep4Subtitle,
        description: s.onboardingStep4Description,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next(int totalPages) {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    await OnboardingPage.markCompleted();
    if (!mounted) return;

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));

    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final pages = _getPages(s);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Semantics(
                  button: true,
                  label: s.skipIntroductionSemantics,
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      s.skipButton,
                      style: AppTypography.bodyMedium(color: AppColors.gray400),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: pages.length,
                itemBuilder: (_, i) => _buildPage(pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) => _buildDot(i)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _next(pages.length),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < pages.length - 1
                        ? s.nextButton
                        : s.startNowButton,
                    style: AppTypography.button(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: page.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, color: page.iconColor, size: 72),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: AppTypography.headlineMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            style: AppTypography.titleSmall(color: page.iconColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: AppTypography.bodyMedium(color: AppColors.gray600),
            textAlign: TextAlign.center,
            maxLines: 5,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.gray300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String subtitle;
  final String description;

  const _OnboardingData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}
