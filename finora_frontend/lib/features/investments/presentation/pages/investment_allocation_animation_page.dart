import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/portfolio_suggestion_entity.dart';
import '../bloc/investment_bloc.dart';
import '../bloc/investment_event.dart';
import '../bloc/investment_state.dart';

/// RF-28: Animated donut chart shown after saving/modifying investor profile.
/// Premium UI Remodel: Glowing chart, Slide+Fade cards, Soft shadows.
class InvestmentAllocationAnimationPage extends StatefulWidget {
  const InvestmentAllocationAnimationPage({super.key});

  @override
  State<InvestmentAllocationAnimationPage> createState() =>
      _InvestmentAllocationAnimationPageState();
}

class _InvestmentAllocationAnimationPageState
    extends State<InvestmentAllocationAnimationPage>
    with TickerProviderStateMixin {
  PortfolioSuggestionEntity? _portfolio;
  bool _loading = true;

  final List<AnimationController> _controllers = [];
  final List<Animation<double>> _animations = [];
  int _visibleCount = 0;

  // Paleta de colores más vibrante para el efecto Glow
  static const List<Color> _palette = [
    Color(0xFF6C63FF),
    Color(0xFF00BCD4),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF009688),
    Color(0xFFF44336),
  ];

  @override
  void initState() {
    super.initState();
    context.read<InvestmentBloc>().add(const LoadPortfolioSuggestion());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _startAnimation(PortfolioSuggestionEntity portfolio) {
    setState(() {
      _portfolio = portfolio;
      _loading = false;
    });
    _buildAnimations(portfolio);
    _animateSequentially(0);
  }

  void _buildAnimations(PortfolioSuggestionEntity portfolio) {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
    _animations.clear();

    for (var i = 0; i < portfolio.portfolio.length; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(
          milliseconds: 850,
        ), // Un poco más lento para más elegancia
      );
      // Usamos una curva más dramática
      final anim = CurvedAnimation(parent: ctrl, curve: Curves.easeOutQuart);
      _controllers.add(ctrl);
      _animations.add(anim);
    }
    setState(() => _visibleCount = 0);
  }

  void _animateSequentially(int index) {
    if (index >= _controllers.length) return;
    setState(() => _visibleCount = index + 1);

    _controllers[index].forward().then((_) {
      // Reducimos el delay para que la siguiente empiece justo antes de que termine la anterior
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _animateSequentially(index + 1);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return BlocListener<InvestmentBloc, InvestmentState>(
      listener: (ctx, state) {
        if (state is PortfolioLoaded && _portfolio == null) {
          _startAnimation(state.suggestion);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor:
              Colors.transparent, // AppBar transparente para un look limpio
          elevation: 0,
          centerTitle: true,
          title: Text(s.portfolioTab, style: AppTypography.titleMedium()),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(s),
      ),
    );
  }

  Widget _buildContent(dynamic s) {
    final portfolio = _portfolio!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(), // Scroll más suave
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ANIMADO ---
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Column(
              children: [
                Center(
                  child: Text(
                    s.recommendedStrategy,
                    style: AppTypography.titleMedium().copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    portfolio.rationale,
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryLight,
                    ).copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // --- GRÁFICA DE DONA CON GLOW Y CENTRO ---
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Texto central interactivo
                  AnimatedOpacity(
                    opacity: _visibleCount > 0 ? 1.0 : 0.0,
                    duration: const Duration(seconds: 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_graph_rounded,
                          color: AppColors.primary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "100%",
                          style: AppTypography.titleMedium().copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          "Capital",
                          style: AppTypography.labelMedium(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dona animada
                  AnimatedBuilder(
                    animation: Listenable.merge(_animations),
                    builder: (ctx, _) {
                      return CustomPaint(
                        size: const Size(240, 240),
                        painter: _DonutPainter(
                          allocations: portfolio.portfolio,
                          animations: _animations,
                          colors: _palette,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),

          // --- LISTA DE ETFs (Slide + Fade) ---
          Text(
            s.portfolioTab.toUpperCase(),
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...List.generate(portfolio.portfolio.length, (i) {
            final etf = portfolio.portfolio[i];
            final color = _palette[i % _palette.length];
            final animation = _animations.length > i
                ? _animations[i]
                : const AlwaysStoppedAnimation(0.0);

            // Cada tarjeta se desliza hacia arriba y aparece MIENTRAS su sección de la dona se dibuja
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: FadeTransition(
                opacity: animation,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(
                      20,
                    ), // Bordes más suaves
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.04,
                        ), // Sombra premium muy sutil
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ícono circular con gradiente ligero
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              color.withValues(alpha: 0.2),
                              color.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${etf.allocation}%',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    etf.etf,
                                    style: AppTypography.titleSmall().copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    etf.ticker,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              etf.category,
                              style: AppTypography.bodySmall(
                                color: AppColors.textSecondaryLight,
                              ),
                            ),
                            if (etf.reason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                etf.reason,
                                style:
                                    AppTypography.bodySmall(
                                      color: AppColors.textTertiaryLight,
                                    ).copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 11,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // --- BOTÓN FINAL (Animado al terminar) ---
          AnimatedOpacity(
            opacity: _visibleCount >= portfolio.portfolio.length ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 600),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                ),
                onPressed: _visibleCount >= portfolio.portfolio.length
                    ? () => Navigator.pop(context, true)
                    : null,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: Text(
                  s.save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<PortfolioAllocationEntity> allocations;
  final List<Animation<double>> animations;
  final List<Color> colors;

  _DonutPainter({
    required this.allocations,
    required this.animations,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth =
        28.0; // Ligeramente más delgado para un look más refinado
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - strokeWidth / 2,
    );

    // Track de fondo sutil
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.gray200
          .withValues(alpha: 0.3) // Más sutil
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, bgPaint);

    final total = allocations.fold<int>(0, (sum, e) => sum + e.allocation);
    if (total == 0) return;

    double startAngle = -math.pi / 2;
    const gap = 0.04; // Un gap un poco más visible queda muy bien

    for (var i = 0; i < allocations.length; i++) {
      final etf = allocations[i];
      final targetSweep =
          (etf.allocation / total) * (math.pi * 2 - gap * allocations.length);
      final animValue = i < animations.length ? animations[i].value : 0.0;
      final sweepAngle = targetSweep * animValue;

      if (sweepAngle > 0) {
        final color = colors[i % colors.length];

        // 1. Pintar el "Glow" (Resplandor)
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            12,
          ); // Efecto difuminado

        canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

        // 2. Pintar el trazo sólido encima
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color;

        canvas.drawArc(rect, startAngle, sweepAngle, false, strokePaint);
      }

      startAngle += targetSweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true; // En animaciones siempre repintamos
}
