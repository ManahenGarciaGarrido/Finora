/// Página de Ajustes — RF-03 + RF-32 + RF-34 + RF-35 + RNF-03 + RNF-10 + RNF-13
///
/// - Sección General: categorías, notificaciones (RF-31/32/33), presupuestos (RF-32),
///   apariencia e idioma (RNF-13)
/// - Sección Seguridad: biometría (RF-03), 2FA (RNF-03)
/// - Sección Datos: exportar CSV/PDF (RF-34/35), consentimientos PSD2, privacidad GDPR
library;

import 'dart:math' as math;
import 'package:finora_frontend/features/home/presentation/pages/change_password_page.dart';
import 'package:finora_frontend/features/home/presentation/pages/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../settings/presentation/pages/privacy_page.dart';
import '../../../banks/presentation/pages/psd2_consent_management_page.dart';
import 'export_page.dart'; // RF-34 / RF-35
import 'budget_page.dart'; // RF-32
import 'two_fa_setup_page.dart'; // RNF-03
import 'notification_settings_page.dart'; // RF-31 / RF-32 / RF-33
import '../../../debts/presentation/pages/debts_page.dart';
import '../../../investments/presentation/pages/investments_page.dart';
import '../../../household/presentation/pages/household_page.dart';
import '../../../gamification/presentation/pages/gamification_page.dart';
import '../../../fiscal/presentation/pages/fiscal_page.dart';
import '../../../ocr/presentation/pages/ocr_page.dart';
import '../../../widget/presentation/pages/widget_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // RF-03: Biometric state
  bool _biometricDeviceSupported = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  String _biometricLabel = 'Huella dactilar';

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  String _translateLabel(BuildContext context, String label) {
    final s = AppLocalizations.of(context);

    switch (label.toLowerCase()) {
      case 'huella dactilar':
        return s.biometricFingerprint;
      case 'face id':
        return s.biometricFaceId;
      case 'biometría':
        return s.biometricGeneric;
      default:
        return label;
    }
  }

  /// RF-03: Load biometric availability and user preference
  Future<void> _loadBiometricStatus() async {
    final service = di.sl<BiometricService>();
    final isAvailable = await service.isAvailable();
    if (!isAvailable) {
      if (mounted) setState(() => _biometricDeviceSupported = false);
      return;
    }
    final isEnabled = await service.isBiometricEnabled();
    final label = await service.getBiometricLabel();
    if (mounted) {
      setState(() {
        _biometricDeviceSupported = true;
        _biometricEnabled = isEnabled;
        _biometricLabel = _translateLabel(context, label);
      });
    }
  }

  /// RF-03: Toggle biometric — activa con autenticación, desactiva directamente
  Future<void> _toggleBiometric(bool value) async {
    final s = AppLocalizations.of(context);
    final service = di.sl<BiometricService>();
    setState(() => _biometricLoading = true);

    if (value) {
      // Al activar se pide autenticación biométrica por seguridad
      final result = await service.enableBiometric();
      if (!mounted) return;
      switch (result) {
        case BiometricResult.success:
          setState(() {
            _biometricEnabled = true;
            _biometricLoading = false;
          });
          _showSnackBar(
            s.biometricActivatedMsg(_biometricLabel),
            AppColors.success,
          );
        case BiometricResult.canceled:
          setState(() => _biometricLoading = false);
          _showSnackBar(s.biometricCancelledMsg, AppColors.gray700);
        case BiometricResult.notAvailable:
        case BiometricResult.notEnrolled:
          setState(() => _biometricLoading = false);
          _showSnackBar(
            s.biometricSetupDeviceMsg(_biometricLabel),
            AppColors.warning,
          );
        case BiometricResult.error:
          setState(() => _biometricLoading = false);
          _showSnackBar(s.biometricErrorMsg, AppColors.error);
        case BiometricResult.disabled:
          setState(() => _biometricLoading = false);
      }
    } else {
      await service.disableBiometric();
      if (!mounted) return;
      setState(() {
        _biometricEnabled = false;
        _biometricLoading = false;
      });
      _showSnackBar(s.biometricDeactivatedMsg, AppColors.gray700);
    }
  }

  // ── Fix-9: Edit Profile Dialog ──────────────────────────────────────────────
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }

  // ── Fix-11: Change Password Dialog ──────────────────────────────────────────
  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getUserName() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.name;
    return 'Usuario';
  }

  String _getUserEmail() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.email;
    return '';
  }

  String _getUserInitials() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final parts = authState.user.name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthBloc>();
    final responsive = ResponsiveUtils(context);
    final s = AppLocalizations.of(context);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                0,
              ),
              child: Text(s.settings, style: AppTypography.headlineSmall()),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                20,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildProfileSection(),
            ),
          ),

          // General
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                24,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildSettingsSection(
                title: s.sectionGeneral,
                children: [
                  _buildSettingsRow(
                    icon: Icons.category_outlined,
                    title: s.settingsCategories,
                    subtitle: s.settingsCategoriesSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoriesPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.notifications_outlined,
                    title: s.settingsNotifications,
                    subtitle: s.settingsNotificationsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsPage(),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.account_balance_wallet_rounded,
                    title: s.settingsBudgets,
                    subtitle: s.settingsBudgetsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BudgetPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Seguridad (RF-03: biometría funcional)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildSettingsSection(
                title: s.sectionSecurity,
                children: [
                  _buildSettingsRow(
                    icon: Icons.lock_outline_rounded,
                    title: s.settingsChangePassword,
                    subtitle: s.settingsChangePasswordSubtitle,
                    onTap: _navigateToChangePassword,
                  ),
                  _divider(),
                  // RF-03: Biometric toggle — funcional
                  _buildBiometricRow(),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.security_rounded,
                    title: s.settingsBiometric2fa,
                    subtitle: s.twoFactorAuth,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TwoFaSetupPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Datos y privacidad
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildSettingsSection(
                title: s.sectionData,
                children: [
                  _buildSettingsRow(
                    icon: Icons.download_rounded,
                    title: s.settingsExportData,
                    subtitle: s.settingsExportDataSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExportPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.account_balance_outlined,
                    title: s.settingsPsd2,
                    subtitle: s.settingsPsd2Subtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Psd2ConsentManagementPage(
                          apiClient: di.sl<ApiClient>(),
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    title: s.settingsPrivacy,
                    subtitle: s.settingsPrivacySubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: s.deleteAccount,
                    subtitle: s.deleteAllData,
                    isDeveloping: true,
                    isDanger: true,
                  ),
                ],
              ),
            ),
          ),

          // Finanzas avanzadas
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildSettingsSection(
                title: s.sectionAdvancedFinances,
                children: [
                  _buildSettingsRow(
                    icon: Icons.credit_card_outlined,
                    title: s.settingsDebts,
                    subtitle: s.settingsDebtsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DebtsPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.trending_up_rounded,
                    title: s.settingsInvestments,
                    subtitle: s.settingsInvestmentsSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InvestmentsPage(),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.home_outlined,
                    title: s.settingsHousehold,
                    subtitle: s.settingsHouseholdSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HouseholdPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.emoji_events_outlined,
                    title: s.settingsGamification,
                    subtitle: s.settingsGamificationSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GamificationPage(),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.receipt_long_outlined,
                    title: s.settingsFiscal,
                    subtitle: s.settingsFiscalSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FiscalPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.document_scanner_outlined,
                    title: s.settingsOcr,
                    subtitle: s.settingsOcrSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OcrPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.widgets_outlined,
                    title: s.settingsWidget,
                    subtitle: s.settingsWidgetSubtitle,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WidgetPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Cerrar sesión
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                24,
                responsive.horizontalPadding,
                0,
              ),
              child: _buildLogoutButton(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Center(
                child: Text(
                  'Finora v1.0.0',
                  style: AppTypography.bodySmall(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: AppColors.gray100);

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gray100),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _getUserInitials(),
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getUserName(), style: AppTypography.titleMedium()),
                const SizedBox(height: 2),
                Text(
                  _getUserEmail(),
                  style: AppTypography.bodySmall(
                    color: AppColors.textSecondaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: _navigateToEditProfile,
              color: AppColors.textSecondaryLight,
              tooltip: AppLocalizations.of(context).editProfileTitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelMedium(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDeveloping = false,
    bool isDanger = false,
    VoidCallback? onTap,
  }) {
    final s = AppLocalizations.of(context);
    final content = Semantics(
      label: title,
      hint: subtitle,
      button: onTap != null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDanger ? AppColors.errorSoft : AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDanger
                    ? AppColors.error
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall(
                      color: isDanger
                          ? AppColors.error
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isDeveloping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.comingSoon,
                  style: AppTypography.badge(color: AppColors.warningDark),
                ),
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 20,
              ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  // RF-03: Biometric settings row with functional Switch
  Widget _buildBiometricRow() {
    final s = AppLocalizations.of(context);
    final isFaceId = _biometricLabel == 'Face ID';
    final icon = isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded;
    final String subtitle;
    if (_biometricDeviceSupported) {
      subtitle = _biometricEnabled
          ? s.biometricEnabledStatus(_biometricLabel)
          : s.biometricDisabledStatus(_biometricLabel);
    } else {
      subtitle = s.biometricNotAvailable;
    }

    return Semantics(
      label: 'Autenticación biométrica',
      hint: subtitle,
      toggled: _biometricEnabled,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _biometricEnabled
                    ? AppColors.primarySoft
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: _biometricEnabled
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _translateLabel(context, _biometricLabel),
                    style: AppTypography.titleSmall(),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall(
                      color: AppColors.textTertiaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (!_biometricDeviceSupported)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  s.notAvailable,
                  style: AppTypography.badge(
                    color: AppColors.textTertiaryLight,
                  ),
                ),
              )
            else if (_biometricLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Switch.adaptive(
                value: _biometricEnabled,
                onChanged: _biometricDeviceSupported ? _toggleBiometric : null,
                activeTrackColor: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    final s = AppLocalizations.of(context);
    return Semantics(
      label: s.settingsLogout,
      button: true,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) {
              final ds = AppLocalizations.of(dialogContext);
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(ds.settingsLogout),
                  ],
                ),
                content: Text(
                  ds.locale.startsWith('en')
                      ? 'Are you sure you want to sign out?'
                      : '¿Estás seguro de que quieres cerrar tu sesión?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      ds.cancel,
                      style: const TextStyle(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(ds.settingsLogout),
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.errorSoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                s.settingsLogout,
                style: AppTypography.labelLarge(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
