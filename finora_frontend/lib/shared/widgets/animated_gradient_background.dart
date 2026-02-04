import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../core/theme/app_colors.dart';

/// Fondo con gradiente animado suave para pantallas de autenticación
///
/// Crea un efecto visual elegante con formas difuminadas que se mueven
/// lentamente creando un efecto de "aurora" o "mesh gradient"
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
    this.bubbleCount = 4,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo base con gradiente estático
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF8FAFC), // Gris muy claro
                Color(0xFFEEF2FF), // Indigo muy claro
                Color(0xFFF5F3FF), // Violeta muy claro
              ],
            ),
          ),
        ),

        // Formas animadas suaves
        if (widget.showBubbles)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _AuroraBackgroundPainter(
                  animation: _controller.value,
                  colors:
                      widget.colors ??
                      [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.secondary.withValues(alpha: 0.1),
                        AppColors.accent.withValues(alpha: 0.12),
                        AppColors.info.withValues(alpha: 0.08),
                      ],
                ),
                size: Size.infinite,
              );
            },
          ),

        // Contenido principal
        widget.child,
      ],
    );
  }
}

/// Painter que dibuja formas difuminadas tipo aurora
class _AuroraBackgroundPainter extends CustomPainter {
  final double animation;
  final List<Color> colors;

  _AuroraBackgroundPainter({required this.animation, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    // Forma 1 - Esquina superior derecha
    final offset1 = Offset(
      size.width * 0.8 + math.sin(animation * 2 * math.pi) * size.width * 0.1,
      size.height * 0.15 +
          math.cos(animation * 2 * math.pi) * size.height * 0.08,
    );
    paint.color = colors[0 % colors.length];
    canvas.drawCircle(offset1, size.width * 0.35, paint);

    // Forma 2 - Esquina inferior izquierda
    final offset2 = Offset(
      size.width * 0.2 +
          math.cos(animation * 2 * math.pi + 1) * size.width * 0.08,
      size.height * 0.75 +
          math.sin(animation * 2 * math.pi + 1) * size.height * 0.1,
    );
    paint.color = colors[1 % colors.length];
    canvas.drawCircle(offset2, size.width * 0.4, paint);

    // Forma 3 - Centro derecha
    final offset3 = Offset(
      size.width * 0.9 +
          math.sin(animation * 2 * math.pi + 2) * size.width * 0.06,
      size.height * 0.5 +
          math.cos(animation * 2 * math.pi + 2) * size.height * 0.12,
    );
    paint.color = colors[2 % colors.length];
    canvas.drawCircle(offset3, size.width * 0.3, paint);

    // Forma 4 - Centro superior
    final offset4 = Offset(
      size.width * 0.4 +
          math.cos(animation * 2 * math.pi + 3) * size.width * 0.1,
      size.height * 0.3 +
          math.sin(animation * 2 * math.pi + 3) * size.height * 0.06,
    );
    paint.color = colors[3 % colors.length];
    canvas.drawCircle(offset4, size.width * 0.25, paint);
  }

  @override
  bool shouldRepaint(_AuroraBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
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
    return AnimatedWidget2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedWidget2 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedWidget2({
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
