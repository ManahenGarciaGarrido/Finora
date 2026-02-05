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

/// Pantalla de Inicio de Sesión (RF-02)
///
/// Características:
/// - Diseño responsive (RNF-12)
/// - Animaciones fluidas
/// - Validación en tiempo real
/// - Manejo de credenciales incorrectas
/// - Manejo de cuenta no verificada
/// - Sesión persistente con token seguro
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
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
    return null;
  }

  Future<void> _handleLogin() async {
    // Validar campos
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    // Enviar evento de login al BLoC
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is Authenticated) {
      setState(() => _isLoading = false);

      // Verificar si el email está verificado
      if (!state.user.isEmailVerified) {
        // Mostrar diálogo de verificación pendiente
        _showEmailVerificationDialog(context);
      } else {
        // Navegar al dashboard
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }
    } else if (state is EmailResent) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } else if (state is AuthError) {
      setState(() => _isLoading = false);

      // Verificar si es error de cuenta no verificada
      if (state.message.contains('verifica tu correo') ||
          state.message.contains('Cuenta No Verificada')) {
        _showEmailVerificationDialog(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showEmailVerificationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.mail_outline, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Verificación Pendiente',
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
              'Tu correo electrónico aún no ha sido verificado.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Por favor, revisa tu bandeja de entrada y haz clic en el enlace de verificación que te enviamos.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Enviar evento para reenviar email de verificación
              context.read<AuthBloc>().add(
                ResendVerificationRequested(
                  email: _emailController.text.trim(),
                ),
              );
            },
            child: const Text(
              'Reenviar Email',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Entendido'),
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
                SizedBox(height: responsive.hp(6)),
                _buildHeader(context),
                SizedBox(height: responsive.hp(5)),
                _buildForm(context),
                SizedBox(height: responsive.hp(2)),
                _buildForgotPassword(context),
                SizedBox(height: responsive.hp(4)),
                _buildLoginButton(),
                SizedBox(height: responsive.hp(3)),
                _buildRegisterLink(context),
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
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.all(responsive.hp(5)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      SizedBox(height: responsive.hp(4)),
                      _buildForm(context),
                      SizedBox(height: responsive.hp(2)),
                      _buildForgotPassword(context),
                      SizedBox(height: responsive.hp(4)),
                      _buildLoginButton(),
                      SizedBox(height: responsive.hp(3)),
                      _buildRegisterLink(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo o icono
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Bienvenido de nuevo',
          style: AppTypography.displayLarge(color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar',
          style: AppTypography.bodyLarge(
            color: AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email
          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Correo Electrónico',
            hint: 'correo@ejemplo.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onChanged: (_) {
              if (_emailError != null) {
                setState(() => _emailError = null);
              }
            },
            onSubmitted: (_) {
              _emailFocus.unfocus();
              _passwordFocus.requestFocus();
            },
          ),
          const SizedBox(height: 20),

          // Password
          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: 'Contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outlined,
            obscureText: true,
            showPasswordToggle: true,
            textInputAction: TextInputAction.done,
            errorText: _passwordError,
            onChanged: (_) {
              if (_passwordError != null) {
                setState(() => _passwordError = null);
              }
            },
            onSubmitted: (_) {
              _passwordFocus.unfocus();
              _handleLogin();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/forgot-password');
        },
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return AnimatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      isLoading: _isLoading,
      text: 'Iniciar Sesión',
      icon: Icons.login,
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: '¿No tienes una cuenta? ',
          style: AppTypography.bodyMedium(
            color: AppColors.textSecondaryLight,
          ),
          children: [
            TextSpan(
              text: 'Regístrate',
              style: AppTypography.link(color: AppColors.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, '/register');
                },
            ),
          ],
        ),
      ),
    );
  }
}
