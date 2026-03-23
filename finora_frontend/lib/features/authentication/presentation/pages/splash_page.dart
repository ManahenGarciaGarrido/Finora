import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_startup_tracker.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../home/presentation/pages/onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Iniciar verificación de autenticación inmediata
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthState(BuildContext context, AuthState state) async {
    if (state is Authenticated) {
      AppStartupTracker.markSplashComplete();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else if (state is Unauthenticated) {
      AppStartupTracker.markSplashComplete();
      if (!mounted) return;

      final onboardingDone = await OnboardingPage.isCompleted();
      if (!mounted) return;

      if (!onboardingDone && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingPage(
              onComplete: () {
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        );
      } else {
        if (!context.mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Inyectamos el idioma aquí
    final s = AppLocalizations.of(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(context, state),
      child: Scaffold(
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedLogo(),
                  const SizedBox(height: 40),
                  _buildAppName(),
                  const SizedBox(height: 8),
                  _buildSubtitle(s), // Pasamos s al subtítulo
                  const SizedBox(height: 60),
                  _buildLoadingIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 80,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: const Text(
        'Finora',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryLight,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildSubtitle(AppLocalizations s) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Text(
        s.splashSubtitle, // Traducido dinámicamente
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textSecondaryLight,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 3,
        ),
      ),
    );
  }
}
