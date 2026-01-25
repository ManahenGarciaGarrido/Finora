import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Botón animado con múltiples estados y efectos visuales
///
/// Características:
/// - Animación de escala al presionar
/// - Estado de carga con spinner
/// - Estado de éxito con checkmark
/// - Gradiente opcional
/// - Sombra animada
class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final bool isOutlined;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final bool showShadow;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.isOutlined = false,
    this.icon,
    this.width,
    this.height = 52,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.borderRadius,
    this.showShadow = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!_isDisabled) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  bool get _isDisabled =>
      widget.onPressed == null || widget.isLoading || widget.isSuccess;

  Color get _backgroundColor {
    if (widget.isOutlined) return Colors.transparent;
    if (_isDisabled && !widget.isSuccess) return AppColors.gray300;
    return widget.backgroundColor ?? AppColors.primary;
  }

  Color get _textColor {
    if (widget.isOutlined) {
      return _isDisabled
          ? AppColors.gray400
          : (widget.textColor ?? AppColors.primary);
    }
    return widget.textColor ?? AppColors.white;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onTap: _isDisabled ? null : widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                gradient:
                    !widget.isOutlined &&
                        widget.gradient != null &&
                        !_isDisabled
                    ? widget.gradient
                    : null,
                color: widget.gradient == null || widget.isOutlined
                    ? _backgroundColor
                    : null,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
                border: widget.isOutlined
                    ? Border.all(
                        color: _isDisabled
                            ? AppColors.gray300
                            : (widget.backgroundColor ?? AppColors.primary),
                        width: 2,
                      )
                    : null,
                boxShadow:
                    widget.showShadow && !widget.isOutlined && !_isDisabled
                    ? [
                        BoxShadow(
                          color: (widget.backgroundColor ?? AppColors.primary)
                              .withValues(alpha: _isPressed ? 0.2 : 0.3),
                          blurRadius: _isPressed ? 8 : 16,
                          offset: Offset(0, _isPressed ? 2 : 6),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return SizedBox(
        key: const ValueKey('loading'),
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: _textColor),
      );
    }

    if (widget.isSuccess) {
      return Icon(
        Icons.check_rounded,
        key: const ValueKey('success'),
        color: AppColors.white,
        size: 28,
      );
    }

    if (widget.icon != null) {
      return Row(
        key: const ValueKey('iconText'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, color: _textColor, size: 20),
          const SizedBox(width: 8),
          Text(widget.text, style: AppTypography.button(color: _textColor)),
        ],
      );
    }

    return Text(
      widget.text,
      key: const ValueKey('text'),
      style: AppTypography.button(color: _textColor),
    );
  }
}

/// Botón con gradiente preconfigurado
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;
  final double? width;
  final double height;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isSuccess: isSuccess,
      icon: icon,
      width: width,
      height: height,
      gradient: AppColors.primaryGradient,
    );
  }
}

/// Botón de texto simple
class TextLinkButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;
  final bool underline;

  const TextLinkButton({
    super.key,
    required this.text,
    this.onPressed,
    this.color,
    this.icon,
    this.underline = false,
  });

  @override
  State<TextLinkButton> createState() => _TextLinkButtonState();
}

class _TextLinkButtonState extends State<TextLinkButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style:
              AppTypography.labelLarge(
                color: _isHovered ? color.withValues(alpha: 0.7) : color,
              ).copyWith(
                decoration: widget.underline ? TextDecoration.underline : null,
              ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(widget.text),
            ],
          ),
        ),
      ),
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
    return AnimatedWidget3(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedWidget3 extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedWidget3({
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
