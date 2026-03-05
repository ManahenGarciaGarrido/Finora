/// Página de Onboarding — RNF-10
///
/// RNF-10: Curva de aprendizaje
///  - Onboarding intuitivo y breve (< 1 minuto)
///  - 4 pantallas que explican las funciones clave de Finora
///  - Primera transacción accesible en < 2 minutos desde instalación
///  - Opción de saltar onboarding
///  - Diseño auto-explicativo con ilustraciones y textos claros

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// RNF-10: Flujo de bienvenida para nuevos usuarios.
class OnboardingPage extends StatefulWidget {
  /// Callback llamado cuando el usuario completa o salta el onboarding.
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  /// Comprueba si el onboarding ya fue completado.
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }

  /// Marca el onboarding como completado.
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

  // ── Definición de pantallas ────────────────────────────────────────────────

  static const _pages = [
    _OnboardingData(
      icon: Icons.account_balance_wallet_rounded,
      iconColor: AppColors.primary,
      bgColor: AppColors.primarySoft,
      title: 'Bienvenido a Finora',
      subtitle: 'Tu gestor financiero personal inteligente',
      description:
          'Controla tus ingresos, gastos y objetivos de ahorro en un solo lugar. '
          'Finora te ayuda a tomar mejores decisiones financieras con la ayuda de IA.',
    ),
    _OnboardingData(
      icon: Icons.add_circle_rounded,
      iconColor: AppColors.success,
      bgColor: AppColors.successSoft,
      title: 'Registra transacciones fácilmente',
      subtitle: 'Manual o conectando tu banco',
      description:
          'Añade gastos e ingresos en segundos. Conecta tu cuenta bancaria para '
          'sincronización automática. La IA categoriza cada transacción por ti.',
    ),
    _OnboardingData(
      icon: Icons.insights_rounded,
      iconColor: AppColors.info,
      bgColor: AppColors.infoSoft,
      title: 'Visualiza tus finanzas',
      subtitle: 'Gráficos interactivos y predicciones',
      description:
          'Analiza tus gastos por categoría, visualiza tendencias temporales y '
          'recibe predicciones de tus gastos del próximo mes con machine learning.',
    ),
    _OnboardingData(
      icon: Icons.savings_rounded,
      iconColor: AppColors.savings,
      bgColor: Color(0xFFEDE9FE),
      title: 'Alcanza tus metas',
      subtitle: 'Objetivos de ahorro con recomendaciones IA',
      description:
          'Crea objetivos de ahorro con fechas límite y visualiza tu progreso. '
          'El asistente de IA te da recomendaciones personalizadas para ahorrar más.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
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
    widget.onComplete();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Botón saltar
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: Semantics(
                  button: true,
                  label: 'Saltar introducción',
                  child: TextButton(
                    onPressed: _complete,
                    child: Text(
                      'Saltar',
                      style: AppTypography.bodyMedium(color: AppColors.gray400),
                    ),
                  ),
                ),
              ),
            ),

            // Páginas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Indicadores de punto
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => _buildDot(i)),
            ),
            const SizedBox(height: 24),

            // Botón siguiente / empezar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage < _pages.length - 1
                        ? 'Siguiente'
                        : '¡Empezar ahora!',
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
          // Ilustración / ícono
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

          // Título
          Text(
            page.title,
            style: AppTypography.headlineMedium(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtítulo
          Text(
            page.subtitle,
            style: AppTypography.titleSmall(color: page.iconColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Descripción
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

// ── Modelo de datos de página ──────────────────────────────────────────────────

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
