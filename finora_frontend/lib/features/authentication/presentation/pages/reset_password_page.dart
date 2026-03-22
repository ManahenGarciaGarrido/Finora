import 'package:finora_frontend/core/l10n/app_localizations.dart';
import 'package:finora_frontend/shared/widgets/animated_gradient_background.dart';
import 'package:finora_frontend/shared/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

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

  // Requisitos de contraseña
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

  // VALIDACIONES INYECTADAS
  String? _validatePassword(String value, AppLocalizations s) {
    if (value.isEmpty) return s.passwordRequired;
    if (value.length < 8) return s.passwordTooShort;
    if (!value.contains(RegExp(r'[A-Z]'))) return s.passwordUppercase;
    if (!value.contains(RegExp(r'[0-9]'))) return s.passwordNumber;
    if (!value.contains(
      RegExp(
        r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\/`~;'
        r"']",
      ),
    )) {
      return s.passwordSpecial;
    }
    return null;
  }

  String? _validateConfirmPassword(String value, AppLocalizations s) {
    if (value.isEmpty) return s.confirmPasswordRequired;
    if (value != _passwordController.text) return s.passwordsDontMatch;
    return null;
  }

  Future<void> _handleResetPassword(AppLocalizations s) async {
    setState(() {
      _passwordError = _validatePassword(_passwordController.text, s);
      _confirmPasswordError = _validateConfirmPassword(
        _confirmPasswordController.text,
        s,
      );
    });

    if (_passwordError != null || _confirmPasswordError != null) return;

    context.read<AuthBloc>().add(
      ResetPasswordRequested(
        token: widget.token,
        newPassword: _passwordController.text,
      ),
    );
  }

  void _handleAuthState(
    BuildContext context,
    AuthState state,
    AppLocalizations s,
  ) {
    if (state is AuthLoading) {
      setState(() => _isLoading = true);
    } else if (state is PasswordResetSuccess) {
      setState(() => _isLoading = false);

      // Diálogo de éxito 100% localizado
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.successTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
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
              child: Text(s.login), // Asegúrate de tener 'login' en tus strings
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) => _handleAuthState(context, state, s),
      child: Scaffold(
        body: AnimatedGradientBackground(
          child: SafeArea(
            child: ResponsiveBuilder(
              mobile: (context) => _buildMobileLayout(context, s, responsive),
              tablet: (context) => _buildTabletLayout(context, s, responsive),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppLocalizations s,
    ResponsiveUtils res,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(res.wp(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: res.hp(4)),
          Text(
            s.resetPasswordTitle,
            style: TextStyle(
              fontSize: res.sp(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimaryLight,
            ),
          ),
          SizedBox(height: res.hp(2)),
          Text(
            s.resetPasswordSubtitle,
            style: TextStyle(
              fontSize: res.sp(14),
              color: AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          SizedBox(height: res.hp(4)),
          _buildForm(s, res),
          SizedBox(height: res.hp(4)),
          _buildSubmitButton(s, res),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations s, ResponsiveUtils res) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: s.newPasswordLabel,
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
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            onChanged: (value) {
              _checkPasswordRequirements(value);
              if (_passwordError != null) {
                setState(() => _passwordError = _validatePassword(value, s));
              }
            },
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmPasswordFocus),
          ),
          SizedBox(height: res.hp(2)),
          _buildPasswordRequirements(s, res),
          SizedBox(height: res.hp(2)),
          CustomTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: s.confirmPasswordLabel,
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
              onPressed: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
            ),
            onChanged: (value) {
              if (_confirmPasswordError != null) {
                setState(
                  () => _confirmPasswordError = _validateConfirmPassword(
                    value,
                    s,
                  ),
                );
              }
            },
            onSubmitted: (_) => _handleResetPassword(s),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirements(AppLocalizations s, ResponsiveUtils res) {
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
            s.passwordRequirementsHeader,
            style: TextStyle(
              fontSize: res.sp(12),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequirementRow(s.reqChars, _hasMinLength, res),
          _buildRequirementRow(s.reqUpper, _hasUpperCase, res),
          _buildRequirementRow(s.reqNumber, _hasNumber, res),
          _buildRequirementRow(s.reqSpecial, _hasSpecialChar, res),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isMet, ResponsiveUtils res) {
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
              fontSize: res.sp(12),
              color: isMet ? AppColors.success : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations s, ResponsiveUtils res) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _handleResetPassword(s),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
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
                s.resetPasswordButton,
                style: TextStyle(
                  fontSize: res.sp(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTabletLayout(
    BuildContext context,
    AppLocalizations s,
    ResponsiveUtils res,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _buildMobileLayout(context, s, res),
      ),
    );
  }
}