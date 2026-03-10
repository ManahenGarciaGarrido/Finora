import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Forgot Password Page
/// Allows users to request password reset via email
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  String? _validateEmail(String value) {
    if (value.isEmpty) {
      return 'El correo electrónico es requerido'; // TODO: add localization key
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido'; // TODO: add localization key
    }
    return null;
  }

  Future<void> _handleForgotPassword() async {
    // Validar campo
    setState(() {
      _emailError = _validateEmail(_emailController.text);
    });

    if (_emailError != null) return;

    // Enviar evento al BLoC
    context.read<AuthBloc>().add(
      ForgotPasswordRequested(email: _emailController.text.trim()),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is PasswordResetEmailSent) {
      setState(() => _isLoading = false);

      // Mostrar diálogo de éxito
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.mail_outline, color: AppColors.success, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Email Enviado', // TODO: add localization key
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.message,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'Revisa tu bandeja de entrada y haz clic en el enlace para restablecer tu contraseña.', // TODO: add localization key
                style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volver a login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Volver al Login',
              ), // TODO: add localization key
            ),
          ],
        ),
      );
    } else if (state is AuthError) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
      padding: EdgeInsets.all(responsive.wp(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: responsive.hp(4)),

          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SizedBox(height: responsive.hp(2)),

          // Title
          Text(
            '¿Olvidaste tu contraseña?', // TODO: add localization key
            style: TextStyle(
              fontSize: responsive.sp(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),

          SizedBox(height: responsive.hp(2)),

          // Subtitle
          Text(
            'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.', // TODO: add localization key
            style: TextStyle(
              fontSize: responsive.sp(14),
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),

          SizedBox(height: responsive.hp(4)),

          // Form
          Form(
            key: _formKey,
            child: CustomTextField(
              controller: _emailController,
              focusNode: _emailFocus,
              label: 'Correo Electrónico', // TODO: add localization key
              hint: 'correo@ejemplo.com', // TODO: add localization key
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: _emailError,
              onChanged: (value) {
                if (_emailError != null) {
                  setState(() {
                    _emailError = _validateEmail(value);
                  });
                }
              },
              onSubmitted: (_) => _handleForgotPassword(),
            ),
          ),

          SizedBox(height: responsive.hp(4)),

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Enviar Enlace', // TODO: add localization key
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          SizedBox(height: responsive.hp(3)),

          // Back to login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Volver al inicio de sesión', // TODO: add localization key
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: responsive.sp(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: EdgeInsets.all(responsive.wp(4)),
        child: _buildMobileLayout(context),
      ),
    );
  }
}
