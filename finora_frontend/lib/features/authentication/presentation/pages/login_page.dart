/// Pantalla de Inicio de Sesión (RF-02 + RF-03)
///
/// Características:
/// - Diseño responsive (RNF-12)
/// - Animaciones fluidas
/// - Validación en tiempo real
/// - Autenticación biométrica (RF-03): Touch ID, Face ID, huella Android
/// - Manejo de credenciales incorrectas
/// - Sesión persistente con token seguro
library;

import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:finora_frontend/shared/widgets/animated_button.dart';
import 'package:finora_frontend/shared/widgets/animated_gradient_background.dart';
import 'package:finora_frontend/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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

  // RF-03: Biometric state
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricLabel = 'Huella dactilar';
  bool _biometricAuthenticating = false;

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

    // RF-03: Check biometric availability on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const CheckBiometricAvailability());
    });
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
    final s = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return s.emailRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return s.emailInvalid;
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context).passwordRequired;
    }
    return null;
  }

  Future<void> _handleLogin() async {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
      _passwordError = _validatePassword(_passwordController.text);
    });

    if (_emailError != null || _passwordError != null) return;

    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  // RF-03: Trigger biometric authentication
  void _handleBiometricLogin() {
    context.read<AuthBloc>().add(const BiometricLoginRequested());
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading || state is BiometricAuthenticating) {
      setState(() {
        _isLoading = state is AuthLoading;
        _biometricAuthenticating = state is BiometricAuthenticating;
      });
    } else if (state is Authenticated) {
      setState(() {
        _isLoading = false;
        _biometricAuthenticating = false;
      });

      if (!state.user.isEmailVerified) {
        _showEmailVerificationDialog(context);
      } else {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      }
    } else if (state is BiometricAvailable) {
      setState(() {
        _biometricAvailable = true;
        _biometricEnabled = state.isEnabled;
        _biometricLabel = state.biometricLabel;
        _biometricAuthenticating = false;
      });
      // RF-03: Auto-trigger biometric if enabled (acceso < 2 segundos)
      if (state.isEnabled) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _handleBiometricLogin();
        });
      }
    } else if (state is BiometricNotAvailable) {
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
        _biometricAuthenticating = false;
      });
    } else if (state is BiometricFailed) {
      setState(() {
        _isLoading = false;
        _biometricAuthenticating = false;
      });
      // Show snackbar — fallback to password is automatic (form stays visible)
      if (mounted &&
          state.reason.isNotEmpty &&
          !state.reason.contains('cancelada')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.reason),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
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
      setState(() {
        _isLoading = false;
        _biometricAuthenticating = false;
      });

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
    } else {
      setState(() {
        _isLoading = false;
        _biometricAuthenticating = false;
      });
    }
  }

  void _showEmailVerificationDialog(BuildContext context) {
    final s = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.mail_outline, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.emailVerificationPending,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.emailNotVerifiedMsg,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              s.checkInboxMsg,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(
                ResendVerificationRequested(
                  email: _emailController.text.trim(),
                ),
              );
            },
            child: Text(
              s.resendEmail,
              style: const TextStyle(color: AppColors.primary),
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
            child: Text(s.understood),
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
                // RF-03: Biometric separator + button
                if (_biometricAvailable && _biometricEnabled) ...[
                  SizedBox(height: responsive.hp(2)),
                  _buildBiometricDivider(),
                  SizedBox(height: responsive.hp(2)),
                  _buildBiometricButton(),
                ],
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

    return Row(
      children: [
        // Left branding panel
        Expanded(
          flex: 1,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Finora',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context).splashSubtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Right form panel
        Expanded(
          flex: 1,
          child: Container(
            color: AppColors.backgroundLight,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
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
                              _buildHeader(context),
                              SizedBox(height: responsive.hp(4)),
                              _buildForm(context),
                              SizedBox(height: responsive.hp(2)),
                              _buildForgotPassword(context),
                              SizedBox(height: responsive.hp(4)),
                              _buildLoginButton(),
                              if (_biometricAvailable && _biometricEnabled) ...[
                                SizedBox(height: responsive.hp(2)),
                                _buildBiometricDivider(),
                                SizedBox(height: responsive.hp(2)),
                                _buildBiometricButton(),
                              ],
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          s.welcomeBack,
          style: AppTypography.displayLarge(color: AppColors.textPrimaryLight),
        ),
        const SizedBox(height: 8),
        Text(
          s.signInToContinue,
          style: AppTypography.bodyLarge(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Semantics(
            label: s.email,
            child: CustomTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: s.email,
              hint: s.emailHint,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) {
                _emailFocus.unfocus();
                _passwordFocus.requestFocus();
              },
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: s.password,
            child: CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: s.password,
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
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
        child: Text(
          AppLocalizations.of(context).forgotPassword,
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final s = AppLocalizations.of(context);
    return Semantics(
      label: s.login,
      button: true,
      child: AnimatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        isLoading: _isLoading,
        text: s.login,
        icon: Icons.login,
      ),
    );
  }

  // RF-03: Divisor "o" entre login normal y biométrico
  Widget _buildBiometricDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.gray200)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.gray200)),
      ],
    );
  }

  // RF-03: Botón de autenticación biométrica
  Widget _buildBiometricButton() {
    final s = AppLocalizations.of(context);
    final isFaceId = _biometricLabel == 'Face ID';
    final icon = isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded;

    return Semantics(
      label: '${s.accessWith} $_biometricLabel',
      button: true,
      hint: s.biometricDescription,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: _biometricAuthenticating ? null : _handleBiometricLogin,
          icon: _biometricAuthenticating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : Icon(icon, size: 22, color: AppColors.primary),
          label: Text(
            _biometricAuthenticating
                ? s.authenticating
                : '${s.accessWith} $_biometricLabel',
            style: AppTypography.labelLarge(color: AppColors.primary),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor: AppColors.primarySoft,
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: RichText(
        text: TextSpan(
          text: '${s.noAccountYet} ',
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          children: [
            TextSpan(
              text: s.register,
              style: AppTypography.link(color: AppColors.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushNamed(context, '/register'),
            ),
          ],
        ),
      ),
    );
  }
}