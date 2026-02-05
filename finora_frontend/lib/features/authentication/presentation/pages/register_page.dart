import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/animated_button.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Pantalla de Registro de Usuario (RF-01)
///
/// Características:
/// - Diseño responsive (RNF-12)
/// - Animaciones fluidas
/// - Validación en tiempo real
/// - Indicadores de fortaleza de contraseña
/// - Soporte para orientación portrait y landscape
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  double _passwordStrength = 0;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
          ),
        );

    _animationController.forward();

    // Listeners para validación en tiempo real
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;

    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;

    setState(() {
      _passwordStrength = strength;
    });
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe contener al menos un carácter especial';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    // Validar campos
    setState(() {
      _nameError = _validateName(_nameController.text);
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
      );
    });

    if (_nameError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar los términos y la política de privacidad',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Enviar evento de registro al BLoC
    context.read<AuthBloc>().add(
      RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is RegistrationSuccess) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
      // Mostrar diálogo de verificación de email
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showEmailVerificationDialog(context, state.user.email);
        }
      });
    } else if (state is AuthError) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showEmailVerificationDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '¡Registro Exitoso!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Te hemos enviado un correo de verificación.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Revisa tu bandeja de entrada en $email y haz clic en el enlace para verificar tu cuenta.',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'No podrás iniciar sesión hasta verificar tu email.',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ir a Iniciar Sesión'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _handleAuthState,
      child: Scaffold(
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: ResponsiveBuilder(
              mobile: (context) => _buildMobileLayout(context),
              tablet: (context) => _buildTabletLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.horizontalPadding,
          vertical: responsive.verticalPadding,
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: responsive.hp(2)),
                _buildHeader(context),
                SizedBox(height: responsive.hp(4)),
                _buildForm(context),
                SizedBox(height: responsive.hp(3)),
                _buildTermsAndPrivacy(),
                SizedBox(height: responsive.hp(3)),
                _buildRegisterButton(),
                SizedBox(height: responsive.hp(3)),
                _buildLoginLink(context),
                SizedBox(height: responsive.hp(2)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Container(
          constraints: BoxConstraints(maxWidth: responsive.maxContentWidth),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.horizontalPadding,
            vertical: responsive.verticalPadding,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 32),
                      _buildForm(context),
                      const SizedBox(height: 24),
                      _buildTermsAndPrivacy(),
                      const SizedBox(height: 24),
                      _buildRegisterButton(),
                      const SizedBox(height: 24),
                      _buildLoginLink(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo o icono
        Container(
          width: responsive.value(mobile: 56.0, tablet: 64.0),
          height: responsive.value(mobile: 56.0, tablet: 64.0),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.shadowColor(AppColors.primary),
          ),
          child: Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.white,
            size: responsive.value(mobile: 28.0, tablet: 32.0),
          ),
        ),
        SizedBox(height: responsive.value(mobile: 24.0, tablet: 32.0)),

        // Título
        Text(
          'Crear cuenta',
          style: responsive.isMobile
              ? AppTypography.headlineLarge()
              : AppTypography.displaySmall(),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Comienza a gestionar tus finanzas de forma inteligente',
          style: AppTypography.bodyLarge(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final spacing = responsive.value(mobile: 16.0, tablet: 20.0);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Nombre
          CustomTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: 'Nombre completo',
            hint: 'Ej: Juan García',
            prefixIcon: Icons.person_outline_rounded,
            errorText: _nameError,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (_nameError != null) {
                setState(() => _nameError = _validateName(value));
              }
            },
            onSubmitted: (_) => _emailFocus.requestFocus(),
          ),
          SizedBox(height: spacing),

          // Email
          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Correo electrónico',
            hint: 'tu@email.com',
            prefixIcon: Icons.email_outlined,
            errorText: _emailError,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (_emailError != null) {
                setState(() => _emailError = _validateEmail(value));
              }
            },
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          SizedBox(height: spacing),

          // Contraseña
          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Contraseña',
            hint: 'Mínimo 8 caracteres',
            prefixIcon: Icons.lock_outline_rounded,
            errorText: _passwordError,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.next,
            onChanged: (value) {
              if (_passwordError != null) {
                setState(() => _passwordError = _validatePassword(value));
              }
            },
            onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
          ),

          // Indicador de fortaleza de contraseña
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          SizedBox(height: spacing),

          // Confirmar contraseña
          CustomTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: 'Confirmar contraseña',
            hint: 'Repite tu contraseña',
            prefixIcon: Icons.lock_outline_rounded,
            errorText: _confirmPasswordError,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.done,
            showSuccessState:
                _confirmPasswordController.text.isNotEmpty &&
                _confirmPasswordController.text == _passwordController.text,
            onChanged: (value) {
              if (_confirmPasswordError != null) {
                setState(
                  () => _confirmPasswordError = _validateConfirmPassword(value),
                );
              }
            },
            onSubmitted: (_) => _handleRegister(),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    String label;
    Color color;

    if (_passwordStrength <= 0.25) {
      label = 'Muy débil';
      color = AppColors.error;
    } else if (_passwordStrength <= 0.5) {
      label = 'Débil';
      color = AppColors.warning;
    } else if (_passwordStrength <= 0.75) {
      label = 'Media';
      color = AppColors.info;
    } else {
      label = 'Fuerte';
      color = AppColors.success;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.labelSmall(color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildRequirement(
              '8+ caracteres',
              _passwordController.text.length >= 8,
            ),
            const SizedBox(width: 8),
            _buildRequirement(
              'Mayúscula',
              _passwordController.text.contains(RegExp(r'[A-Z]')),
            ),
            const SizedBox(width: 8),
            _buildRequirement(
              'Número',
              _passwordController.text.contains(RegExp(r'[0-9]')),
            ),
            const SizedBox(width: 8),
            _buildRequirement(
              'Especial',
              _passwordController.text.contains(
                RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirement(String text, bool met) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle : Icons.circle_outlined,
            size: 12,
            color: met ? AppColors.success : AppColors.gray400,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTypography.labelSmall(
                color: met ? AppColors.success : AppColors.gray500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      children: [
        // Términos y condiciones
        _buildCheckboxRow(
          value: _acceptTerms,
          onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              children: [
                const TextSpan(text: 'Acepto los '),
                TextSpan(
                  text: 'Términos y Condiciones',
                  style: AppTypography.bodySmall(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Mostrar términos
                    },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Política de privacidad
        _buildCheckboxRow(
          value: _acceptPrivacy,
          onChanged: (value) => setState(() => _acceptPrivacy = value ?? false),
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              children: [
                const TextSpan(text: 'He leído y acepto la '),
                TextSpan(
                  text: 'Política de Privacidad',
                  style: AppTypography.bodySmall(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      // Mostrar política de privacidad
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return GradientButton(
      text: 'Crear cuenta',
      onPressed: _handleRegister,
      isLoading: _isLoading,
      isSuccess: _isSuccess,
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: '¿Ya tienes una cuenta? ',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          children: [
            TextSpan(
              text: 'Inicia sesión',
              style: AppTypography.link(color: AppColors.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/login');
                },
            ),
          ],
        ),
      ),
    );
  }
}
