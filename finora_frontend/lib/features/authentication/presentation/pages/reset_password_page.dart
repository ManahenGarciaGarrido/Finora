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

/// Reset Password Page
/// Allows users to set a new password using reset token
class ResetPasswordPage extends StatefulWidget {
  final String token;

  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _passwordError;
  String? _confirmPasswordError;

  // Password requirements state
  bool _hasMinLength = false;
  bool _hasUpperCase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _checkPasswordRequirements(String password) {
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUpperCase = password.contains(RegExp(r'[A-Z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(
        RegExp(
          r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;'
          r"']",
        ),
      );
    });
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) {
      return 'La contraseña es requerida'; // TODO: add localization key
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres'; // TODO: add localization key
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Debe contener al menos una mayúscula'; // TODO: add localization key
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Debe contener al menos un número'; // TODO: add localization key
    }
    if (!value.contains(
      RegExp(
        r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;'
        r"']",
      ),
    )) {
      return 'Debe contener al menos un carácter especial'; // TODO: add localization key
    }
    return null;
  }

  String? _validateConfirmPassword(String value) {
    if (value.isEmpty) {
      return 'Debes confirmar la contraseña'; // TODO: add localization key
    }
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden'; // TODO: add localization key
    }
    return null;
  }

  Future<void> _handleResetPassword() async {
    // Validar campos
    setState(() {
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
      );
    });

    if (_passwordError != null || _confirmPasswordError != null) return;

    // Enviar evento al BLoC
    context.read<AuthBloc>().add(
      ResetPasswordRequested(
        token: widget.token,
        newPassword: _passwordController.text,
      ),
    );
  }

  void _handleAuthState(BuildContext context, AuthState state) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is PasswordResetSuccess) {
      setState(() => _isLoading = false);

      // Mostrar diálogo de éxito y navegar al login
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¡Éxito!', // TODO: add localization key
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Text(
            state.message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Iniciar Sesión'), // TODO: add localization key
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

          // Title
          Text(
            'Restablecer Contraseña', // TODO: add localization key
            style: TextStyle(
              fontSize: responsive.sp(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),

          SizedBox(height: responsive.hp(2)),

          // Subtitle
          Text(
            'Ingresa tu nueva contraseña. Asegúrate de que cumple con los requisitos de seguridad.', // TODO: add localization key
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
            child: Column(
              children: [
                // New password field
                CustomTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: 'Nueva Contraseña', // TODO: add localization key
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  onChanged: (value) {
                    _checkPasswordRequirements(value);
                    if (_passwordError != null) {
                      setState(() {
                        _passwordError = _validatePassword(value);
                      });
                    }
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_confirmPasswordFocus);
                  },
                ),

                SizedBox(height: responsive.hp(2)),

                // Password requirements
                _buildPasswordRequirements(responsive),

                SizedBox(height: responsive.hp(2)),

                // Confirm password field
                CustomTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: 'Confirmar Contraseña', // TODO: add localization key
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outlined,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () {
                      setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      );
                    },
                  ),
                  onChanged: (value) {
                    if (_confirmPasswordError != null) {
                      setState(() {
                        _confirmPasswordError = _validateConfirmPassword(value);
                      });
                    }
                  },
                  onSubmitted: (_) => _handleResetPassword(),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.hp(4)),

          // Submit button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
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
                      'Restablecer Contraseña', // TODO: add localization key
                      style: TextStyle(
                        fontSize: responsive.sp(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements(ResponsiveUtils responsive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requisitos de contraseña:', // TODO: add localization key
            style: TextStyle(
              fontSize: responsive.sp(12),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(
            'Mínimo 8 caracteres', // TODO: add localization key
            _hasMinLength,
            responsive,
          ),
          _buildRequirementRow(
            'Al menos una mayúscula', // TODO: add localization key
            _hasUpperCase,
            responsive,
          ),
          _buildRequirementRow(
            'Al menos un número',
            _hasNumber,
            responsive,
          ), // TODO: add localization key
          _buildRequirementRow(
            'Al menos un carácter especial', // TODO: add localization key
            _hasSpecialChar,
            responsive,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(
    String text,
    bool isMet,
    ResponsiveUtils responsive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 16,
            color: isMet ? AppColors.success : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: isMet ? AppColors.success : AppColors.textSecondaryLight,
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
