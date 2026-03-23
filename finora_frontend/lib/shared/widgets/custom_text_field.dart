import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Campo de texto personalizado con animaciones y validación visual
///
/// Características:
/// - Animación de enfoque suave
/// - Indicador de validación visual
/// - Soporte para contraseña con toggle de visibilidad
/// - Iconos animados
/// - Mensajes de error con animación
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool showPasswordToggle;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onTap;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final bool showSuccessState;
  final bool isLoading;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.showPasswordToggle = false,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.showSuccessState = false,
    this.isLoading = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isObscured = true;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _isObscured = widget.obscureText;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      _errorText = widget.errorText;
    }
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_isFocused) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _toggleObscure() {
    setState(() {
      _isObscured = !_isObscured;
    });
  }

  Color get _borderColor {
    if (_errorText != null || widget.errorText != null) {
      return AppColors.error;
    }
    if (widget.showSuccessState) {
      return AppColors.success;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    return AppColors.gray200;
  }

  Color get _iconColor {
    if (_errorText != null || widget.errorText != null) {
      return AppColors.error;
    }
    if (widget.showSuccessState) {
      return AppColors.success;
    }
    if (_isFocused) {
      return AppColors.primary;
    }
    return AppColors.gray400;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              if (widget.label != null) ...[
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: AppTypography.labelMedium(
                    color: _isFocused
                        ? AppColors.primary
                        : AppColors.textSecondaryLight,
                  ),
                  child: Text(widget.label!),
                ),
                const SizedBox(height: 8),
              ],

              // Campo de texto
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  obscureText: _isObscured,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  inputFormatters: widget.inputFormatters,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  maxLines: widget.obscureText ? 1 : widget.maxLines,
                  maxLength: widget.maxLength,
                  style: AppTypography.input(),
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    if (widget.validator != null) {
                      setState(() {
                        _errorText = widget.validator!(value);
                      });
                    }
                  },
                  onFieldSubmitted: widget.onSubmitted,
                  onTap: widget.onTap,
                  validator: widget.validator,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: AppTypography.hint(),
                    errorText: null, // Mostramos el error abajo
                    counterText: '',
                    prefixIcon: widget.prefixIcon != null
                        ? AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              widget.prefixIcon,
                              color: _iconColor,
                              size: 22,
                            ),
                          )
                        : null,
                    suffixIcon: _buildSuffixIcon(),
                    filled: true,
                    fillColor: widget.enabled
                        ? AppColors.gray50
                        : AppColors.gray100,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _borderColor,
                        width: widget.showSuccessState ? 2 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 2,
                      ),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.gray200.withValues(alpha: 0.5),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

              // Mensaje de error con animación
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _buildErrorMessage(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (widget.showSuccessState &&
        (_errorText == null && widget.errorText == null)) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Icon(Icons.check_circle, color: AppColors.success, size: 22),
      );
    }

    if (widget.showPasswordToggle && widget.obscureText) {
      return IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isObscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            key: ValueKey(_isObscured),
            color: _iconColor,
            size: 22,
          ),
        ),
        onPressed: _toggleObscure,
        splashRadius: 20,
      );
    }

    return widget.suffixIcon;
  }

  Widget _buildErrorMessage() {
    final error = _errorText ?? widget.errorText;

    if (error == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: AppColors.error),
          const SizedBox(width: 4),
          Expanded(child: Text(error, style: AppTypography.error())),
        ],
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
