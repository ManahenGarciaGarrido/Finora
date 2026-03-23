/// Página de Ajustes — RF-03 + RF-32 + RF-34 + RF-35 + RNF-03 + RNF-10 + RNF-13
///
/// - Sección General: categorías, notificaciones (RF-31/32/33), presupuestos (RF-32),
///   apariencia e idioma (RNF-13)
/// - Sección Seguridad: biometría (RF-03), 2FA (RNF-03)
/// - Sección Datos: exportar CSV/PDF (RF-34/35), consentimientos PSD2, privacidad GDPR
library;

import 'dart:convert';
import 'dart:math' as math;
import 'package:finora_frontend/features/banks/presentation/pages/psd2_consent_management_page.dart';
import 'package:finora_frontend/features/home/presentation/pages/change_password_page.dart';
import 'package:finora_frontend/features/home/presentation/pages/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_service.dart';
import 'theme_customization_page.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/security/biometric_service.dart';
import 'package:finora_frontend/core/l10n/app_localizations.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../settings/presentation/pages/privacy_page.dart';
import 'export_page.dart'; // RF-34 / RF-35
import 'budget_page.dart'; // RF-32
import 'two_fa_setup_page.dart'; // RNF-03
import 'notification_settings_page.dart'; // RF-31 / RF-32 / RF-33
import '../../../../core/services/profile_photo_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Tablet two-panel navigation state
  String _selectedSettingsSection = 'profile';

  // RF-03: Biometric state
  bool _biometricDeviceSupported = false;
  bool _biometricEnabled = false;
  bool _biometricLoading = false;
  String _biometricLabel = 'Huella dactilar';

  // Color theme state
  String _currentThemeId = 'navy';

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
    ProfilePhotoService().loadIfNeeded(di.sl<ApiClient>());
    _currentThemeId = ThemeService().currentPalette.id;
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

    if (responsive.isTablet) {
      return SafeArea(child: _buildTabletLayout(context));
    }

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
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.palette_rounded,
                    title: 'Personalizar colores',
                    subtitle: 'Cambia la paleta de colores de toda la app',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ThemeCustomizationPage(),
                      ),
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

  // ── Tablet two-panel layout ──────────────────────────────────────────────────

  Widget _buildTabletLayout(BuildContext context) {
    final s = AppLocalizations.of(context);

    final navItems = [
      {
        'key': 'profile',
        'label': s.editProfileTitle,
        'icon': Icons.person_outline,
      },
      {'key': 'general', 'label': s.sectionGeneral, 'icon': Icons.tune_rounded},
      {
        'key': 'security',
        'label': s.sectionSecurity,
        'icon': Icons.lock_outline_rounded,
      },
      {
        'key': 'data',
        'label': s.sectionData,
        'icon': Icons.privacy_tip_outlined,
      },
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            border: const Border(
              right: BorderSide(color: AppColors.gray100, width: 1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Text(s.settings, style: AppTypography.headlineSmall()),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: navItems.length,
                  itemBuilder: (context, index) {
                    final item = navItems[index];
                    final key = item['key'] as String;
                    final label = item['label'] as String;
                    final icon = item['icon'] as IconData;
                    final isSelected = _selectedSettingsSection == key;

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSettingsSection = key);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              label,
                              style: AppTypography.titleSmall(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Vertical divider
        Container(width: 1, color: AppColors.gray100),

        // Right panel
        Expanded(child: _buildRightPanelContent(context)),
      ],
    );
  }

  Widget _buildRightPanelContent(BuildContext context) {
    switch (_selectedSettingsSection) {
      case 'profile':
        return _buildProfileContent(context);
      case 'general':
        return _buildGeneralContent(context);
      case 'security':
        return _buildSecurityContent(context);
      case 'data':
        return _buildDataContent(context);
      default:
        return _buildProfileContent(context);
    }
  }

  Widget _buildProfileContent(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.editProfileTitle, style: AppTypography.headlineSmall()),
            const SizedBox(height: 20),
            _buildProfileSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralContent(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionGeneral, style: AppTypography.headlineSmall()),
            const SizedBox(height: 20),
            _buildSettingsSection(
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
            const SizedBox(height: 20),
            // ── Color Theme Picker ──────────────────────────────────────
            _buildSettingsSection(
              title: 'Color de la aplicación',
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Paleta de colores',
                            style: AppTypography.titleSmall(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personaliza los colores principales de la app',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ThemeService().palettes.map((palette) {
                          final isSelected = _currentThemeId == palette.id;
                          return GestureDetector(
                            onTap: () async {
                              await ThemeService().setPalette(palette.id);
                              if (mounted) {
                                setState(() => _currentThemeId = palette.id);
                                _showSnackBar(
                                  'Tema "${palette.name}" aplicado',
                                  palette.primary,
                                );
                              }
                            },
                            child: Tooltip(
                              message: palette.name,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: palette.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppColors.primary,
                                          width: 3,
                                        )
                                      : Border.all(
                                          color: AppColors.gray200,
                                          width: 1.5,
                                        ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: palette.primary.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tema actual: ${ThemeService().palettes.firstWhere((p) => p.id == _currentThemeId, orElse: () => ThemeService().palettes.first).name}',
                        style: AppTypography.bodySmall(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ThemeCustomizationPage(),
                          ),
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('Personalización avanzada'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityContent(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionSecurity, style: AppTypography.headlineSmall()),
            const SizedBox(height: 20),
            _buildSettingsSection(
              title: s.sectionSecurity,
              children: [
                _buildSettingsRow(
                  icon: Icons.lock_outline_rounded,
                  title: s.settingsChangePassword,
                  subtitle: s.settingsChangePasswordSubtitle,
                  onTap: _navigateToChangePassword,
                ),
                _divider(),
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
          ],
        ),
      ),
    );
  }

  Widget _buildDataContent(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.sectionData, style: AppTypography.headlineSmall()),
            const SizedBox(height: 20),
            _buildSettingsSection(
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
              ],
            ),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, color: AppColors.gray100);

  Widget _initialsAvatar() {
    return Container(
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
    );
  }

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
          ValueListenableBuilder<String?>(
            valueListenable: ProfilePhotoService().photoNotifier,
            builder: (_, photo, __) {
              if (photo != null && photo.isNotEmpty) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(photo),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initialsAvatar(),
                  ),
                );
              }
              return _initialsAvatar();
            },
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
              SizedBox(
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
