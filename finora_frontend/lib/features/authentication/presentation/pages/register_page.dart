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
  bool _hasCustomizedConsents = false;

  Map<String, bool> _consents = {
    'essential': true,
    'analytics': true,
    'marketing': true,
    'third_party': true,
    'personalization': true,
    'data_processing': true,
  };

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

  // ─── Lógica de Validación (Localizada) ─────────────────────────────────────

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.25;
    setState(() => _passwordStrength = strength);
  }

  String? _validateName(String? value) {
    final s = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return s.nameRequired;
    if (value.length < 2) return s.nameTooShort;
    return null;
  }

  String? _validateEmail(String? value) {
    final s = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return s.emailRequired;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return s.invalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    final s = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return s.passwordRequired;
    if (value.length < 8) return s.passwordTooShort;
    if (!value.contains(RegExp(r'[A-Z]'))) return s.passwordUppercase;
    if (!value.contains(RegExp(r'[0-9]'))) return s.passwordNumber;
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return s.passwordSpecial;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final s = AppLocalizations.of(context);
    if (value == null || value.isEmpty) return s.confirmPasswordRequired;
    if (value != _passwordController.text) return s.passwordsDontMatch;
    return null;
  }

  // ─── Gestión de Registro y BLoC ────────────────────────────────────────────

  Future<void> _handleRegister() async {
    final s = AppLocalizations.of(context);

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
        SnackBar(
          content: Text(s.acceptTermsPrivacyError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<AuthBloc>().add(
      RegisterRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        consents: _hasCustomizedConsents ? _consents : null,
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
      Future.delayed(const Duration(milliseconds: 500), () {
        if (context.mounted) {
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

  /// Helper para renderizar secciones legales con título y cuerpo
  Widget _buildLegalSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _showEmailVerificationDialog(BuildContext context, String email) {
    final s = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.success,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                s.registerSuccessTitle,
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
              s.verificationEmailSent,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              '${s.checkInboxVerify} $email',
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
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.verificationWarning,
                      style: const TextStyle(fontSize: 12, height: 1.4),
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
            child: Text(s.goToLogin),
          ),
        ],
      ),
    );
  }

  // ─── Build Principal ───────────────────────────────────────────────────────

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
    final s = AppLocalizations.of(context);

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
                          Icons.account_balance_wallet_rounded,
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
                        s.registerSubtitle,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Text(
          s.registerTitle,
          style: responsive.isMobile
              ? AppTypography.headlineLarge()
              : AppTypography.displaySmall(),
        ),
        const SizedBox(height: 8),
        Text(
          s.registerSubtitle,
          style: AppTypography.bodyLarge(color: AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    final s = AppLocalizations.of(context);
    final responsive = ResponsiveUtils(context);
    final spacing = responsive.value(mobile: 16.0, tablet: 20.0);

    return Form(
      key: _formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _nameController,
            focusNode: _nameFocus,
            label: s.fullNameLabel,
            hint: s.fullNameHint,
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
          CustomTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: s.emailLabel,
            hint: s.emailHint,
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
          CustomTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: s.password,
            hint: s.passwordTooShort,
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
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPasswordStrengthIndicator(),
          ],
          SizedBox(height: spacing),
          CustomTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocus,
            label: s.confirmPasswordRequired,
            hint: s.passwordsDontMatch,
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
    final s = AppLocalizations.of(context);
    String label;
    Color color;

    if (_passwordStrength <= 0.25) {
      label = s.passwordStrengthVeryWeak;
      color = AppColors.error;
    } else if (_passwordStrength <= 0.5) {
      label = s.passwordStrengthWeak;
      color = AppColors.warning;
    } else if (_passwordStrength <= 0.75) {
      label = s.passwordStrengthMedium;
      color = AppColors.info;
    } else {
      label = s.passwordStrengthStrong;
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
            _buildRequirement(s.reqChars, _passwordController.text.length >= 8),
            const SizedBox(width: 8),
            _buildRequirement(
              s.reqUpper,
              _passwordController.text.contains(RegExp(r'[A-Z]')),
            ),
            const SizedBox(width: 8),
            _buildRequirement(
              s.reqNumber,
              _passwordController.text.contains(RegExp(r'[0-9]')),
            ),
            const SizedBox(width: 8),
            _buildRequirement(
              s.reqSpecial,
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
    final s = AppLocalizations.of(context);
    return Column(
      children: [
        _buildCheckboxRow(
          value: _acceptTerms,
          onChanged: (value) => setState(() {
            _acceptTerms = value ?? false;
            if (_acceptTerms && _hasCustomizedConsents) {
              _hasCustomizedConsents = false;
            }
          }),
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              children: [
                TextSpan(text: s.acceptTermsPart1),
                TextSpan(
                  text: s.termsAndConditions,
                  style: AppTypography.bodySmall(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showTermsAndConditions(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCheckboxRow(
          value: _acceptPrivacy,
          onChanged: (value) => setState(() {
            _acceptPrivacy = value ?? false;
            if (_acceptPrivacy && _hasCustomizedConsents) {
              _hasCustomizedConsents = false;
            }
          }),
          child: RichText(
            text: TextSpan(
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
              children: [
                TextSpan(text: s.acceptPrivacyPart1),
                TextSpan(
                  text: s.privacyPolicy,
                  style: AppTypography.bodySmall(
                    color: AppColors.primary,
                  ).copyWith(fontWeight: FontWeight.w600),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => _showPrivacyPolicyWithConsents(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showTermsAndConditions() {
    final s = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.termsAndConditions,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildLegalSection(s.termsSection1Title, s.termsSection1Body),
                  _buildLegalSection(s.termsSection2Title, s.termsSection2Body),
                  _buildLegalSection(s.termsSection3Title, s.termsSection3Body),
                  _buildLegalSection(s.termsSection4Title, s.termsSection4Body),
                  _buildLegalSection(s.termsSection5Title, s.termsSection5Body),
                  _buildLegalSection(s.termsSection6Title, s.termsSection6Body),
                  _buildLegalSection(s.termsSection7Title, s.termsSection7Body),
                  const SizedBox(height: 24),
                  Text(
                    s.lastUpdateText,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _acceptTerms = true);
                  },
                  child: Text(s.acceptTermsButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyWithConsents() {
    final s = AppLocalizations.of(context);
    final localConsents = Map<String, bool>.from(_consents);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.privacyPolicy,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      s.consentManagementTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.consentDescription,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'essential',
                      s.essentialDataTitle,
                      s.essentialDataDesc,
                      required: true,
                    ),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'data_processing',
                      s.dataProcessingTitle,
                      s.dataProcessingDesc,
                      required: true,
                    ),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'analytics',
                      s.analyticsTitle,
                      s.analyticsDesc,
                    ),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'marketing',
                      s.marketingTitle,
                      s.marketingDesc,
                    ),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'third_party',
                      s.thirdPartyTitle,
                      s.thirdPartyDesc,
                    ),
                    _buildConsentOption(
                      setSheetState,
                      localConsents,
                      'personalization',
                      s.personalizationTitle,
                      s.personalizationDesc,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      s.policySummaryTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.gdprComplianceText}\n\nContacto: privacy@finora.app\n${s.lastUpdateText}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final allTrue = localConsents.values.every((v) => v);
                      setState(() {
                        _consents = Map<String, bool>.from(localConsents);
                        _acceptPrivacy = true;
                        if (!allTrue) _hasCustomizedConsents = true;
                      });
                      Navigator.pop(context);
                    },
                    child: Text(s.acceptPrivacyButton),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsentOption(
    StateSetter setSheetState,
    Map<String, bool> localConsents,
    String key,
    String title,
    String description, {
    bool required = false,
  }) {
    final s = AppLocalizations.of(context);
    return Column(
      children: [
        SwitchListTile(
          title: Row(
            children: [
              Expanded(child: Text(title)),
              if (required)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    s.requiredBadge,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Text(description, style: const TextStyle(fontSize: 12)),
          value: localConsents[key] ?? true,
          onChanged: required
              ? null
              : (value) => setSheetState(() => localConsents[key] = value),
        ),
        const Divider(),
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
    final s = AppLocalizations.of(context);
    return GradientButton(
      text: s.registerTitle,
      onPressed: _handleRegister,
      isLoading: _isLoading,
      isSuccess: _isSuccess,
    );
  }

  Widget _buildLoginLink(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: RichText(
        text: TextSpan(
          text: s.alreadyHaveAccount,
          style: AppTypography.bodyMedium(color: AppColors.textSecondaryLight),
          children: [
            TextSpan(
              text: s.loginLink,
              style: AppTypography.link(color: AppColors.primary),
              recognizer: TapGestureRecognizer()
                ..onTap = () => Navigator.pushNamed(context, '/login'),
            ),
          ],
        ),
      ),
    );
  }
}