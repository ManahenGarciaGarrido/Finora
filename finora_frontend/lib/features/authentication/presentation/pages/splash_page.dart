import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_startup_tracker.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../home/presentation/pages/onboarding_page.dart'; // RNF-10

/// Pantalla de Splash con verificación de autenticación
///
/// Características (RNF-08):
/// - Verifica si hay una sesión activa al iniciar
/// - Navega automáticamente al home si está autenticado
/// - Navega al login si no está autenticado
/// - Animación optimizada: duración total < 1 segundo
/// - CheckAuthStatus se dispara de forma inmediata sin delays artificiales
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

    // RNF-08: Animación reducida a 600ms (era 1500ms) para cumplir splash < 1s
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

    // RNF-08: Verificar estado de autenticación de forma inmediata,
    // sin delay artificial (era 500ms de espera innecesaria)
    context.read<AuthBloc>().add(const CheckAuthStatus());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleAuthState(BuildContext context, AuthState state) async {
    if (state is Authenticated) {
      // RNF-08: Navegación inmediata al home, sin delay artificial (era 500ms)
      AppStartupTracker.markSplashComplete();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else if (state is Unauthenticated) {
      // RNF-08: Navegación inmediata, sin delay artificial
      AppStartupTracker.markSplashComplete();
      if (!mounted) return;

      // RNF-10: Mostrar onboarding a usuarios nuevos (primera vez)
      final onboardingDone = await OnboardingPage.isCompleted();
      if (!mounted) return;

      if (!onboardingDone && context.mounted) {
        // Primer uso: mostrar onboarding antes del login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingPage(
              onComplete: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            ),
          ),
        );
      } else {
        if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animado
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
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
                  ),
                  const SizedBox(height: 40),

                  // Nombre de la app
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Finora',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimaryLight,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtítulo
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      'Tu gestor financiero personal',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryLight,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Indicador de carga
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
