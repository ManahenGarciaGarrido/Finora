import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';

/// Fondo con gradiente animado para pantallas de autenticación
///
/// Crea un efecto visual atractivo con círculos/burbujas que se mueven
/// y un gradiente suave de fondo
class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? colors;
  final bool showBubbles;
  final int bubbleCount;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.showBubbles = true,
    this.bubbleCount = 6,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _bubbleController;
  late List<_BubbleData> _bubbles;

  @override
  void initState() {
    super.initState();

    // Controlador para animación de gradiente
    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);

    // Controlador para burbujas
    _bubbleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Generar burbujas aleatorias
    _bubbles = List.generate(
      widget.bubbleCount,
      (index) => _BubbleData.random(),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        widget.colors ??
        [
          AppColors.primary.withValues(alpha: 0.8),
          AppColors.accent.withValues(alpha: 0.6),
          AppColors.secondary.withValues(alpha: 0.4),
        ];

    return Stack(
      children: [
        // Fondo con gradiente animado
        AnimatedBuilder(
          animation: _gradientController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    math.cos(_gradientController.value * math.pi * 2),
                    math.sin(_gradientController.value * math.pi * 2),
                  ),
                  end: Alignment(
                    -math.cos(_gradientController.value * math.pi * 2),
                    -math.sin(_gradientController.value * math.pi * 2),
                  ),
                  colors: [
                    AppColors.backgroundLight,
                    colors[0].withValues(alpha: 0.1),
                    colors[1].withValues(alpha: 0.05),
                  ],
                ),
              ),
            );
          },
        ),

        // Burbujas animadas
        if (widget.showBubbles)
          ...List.generate(widget.bubbleCount, (index) {
            final bubble = _bubbles[index];
            return AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                final progress =
                    (_bubbleController.value + bubble.offset) % 1.0;
                final size = MediaQuery.of(context).size;

                return Positioned(
                  left: bubble.startX * size.width,
                  top: size.height * (1 - progress) - bubble.size / 2,
                  child: Transform.scale(
                    scale: 0.5 + (math.sin(progress * math.pi) * 0.5),
                    child: Opacity(
                      opacity: math.sin(progress * math.pi) * bubble.opacity,
                      child: Container(
                        width: bubble.size,
                        height: bubble.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              bubble.color.withValues(alpha: 0.3),
                              bubble.color.withValues(alpha: 0.1),
                              bubble.color.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

        // Contenido principal
        widget.child,
      ],
    );
  }
}

/// Datos de una burbuja individual
class _BubbleData {
  final double startX;
  final double size;
  final double offset;
  final double opacity;
  final Color color;

  _BubbleData({
    required this.startX,
    required this.size,
    required this.offset,
    required this.opacity,
    required this.color,
  });

  factory _BubbleData.random() {
    final random = math.Random();
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.info,
    ];

    return _BubbleData(
      startX: random.nextDouble(),
      size: 100 + random.nextDouble() * 150,
      offset: random.nextDouble(),
      opacity: 0.3 + random.nextDouble() * 0.4,
      color: colors[random.nextInt(colors.length)],
    );
  }
}

/// Widget auxiliar para construir con animación
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
