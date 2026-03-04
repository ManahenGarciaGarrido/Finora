/// Página de Ajustes — incluye RF-03 Autenticación Biométrica
///
/// Muestra el perfil real del usuario obtenido desde AuthBloc.
/// - Sección Seguridad: toggle funcional de biometría (RF-03)
/// - Cerrar sesión: completamente funcional
/// - Resto de opciones: marcadas como en desarrollo
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/network/api_client.dart';
import '../../../../core/security/biometric_service.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../settings/presentation/pages/privacy_page.dart';
import '../../../banks/presentation/pages/psd2_consent_management_page.dart';

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
        _biometricLabel = label;
      });
    }
  }

  /// RF-03: Toggle biometric — activa con autenticación, desactiva directamente
  Future<void> _toggleBiometric(bool value) async {
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
            '$_biometricLabel activado. Próximo inicio de sesión más rápido.',
            AppColors.success,
          );
        case BiometricResult.canceled:
          setState(() => _biometricLoading = false);
          _showSnackBar('Activación cancelada', AppColors.gray700);
        case BiometricResult.notAvailable:
        case BiometricResult.notEnrolled:
          setState(() => _biometricLoading = false);
          _showSnackBar(
            'Configura $_biometricLabel en los ajustes del dispositivo primero.',
            AppColors.warning,
          );
        case BiometricResult.error:
          setState(() => _biometricLoading = false);
          _showSnackBar('Error al activar la biometría', AppColors.error);
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
      _showSnackBar(
        'Inicio de sesión biométrico desactivado',
        AppColors.gray700,
      );
    }
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
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.name;
    return 'Usuario';
  }

  String _getUserEmail() {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) return authState.user.email;
    return '';
  }

  String _getUserInitials() {
    final authState = context.watch<AuthBloc>().state;
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
    final responsive = ResponsiveUtils(context);

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
              child: Text('Ajustes', style: AppTypography.headlineSmall()),
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
                title: 'General',
                children: [
                  _buildSettingsRow(
                    icon: Icons.category_outlined,
                    title: 'Categorías',
                    subtitle: 'Gestionar categorías de gastos e ingresos',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CategoriesPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    subtitle: 'Gestionar alertas y avisos',
                    isDeveloping: true,
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.palette_outlined,
                    title: 'Apariencia',
                    subtitle: 'Tema, idioma y formato',
                    isDeveloping: true,
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Moneda y formato',
                    subtitle: 'EUR - Euros',
                    isDeveloping: true,
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
                title: 'Seguridad',
                children: [
                  _buildSettingsRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualizar contraseña de acceso',
                    isDeveloping: true,
                  ),
                  _divider(),
                  // RF-03: Biometric toggle — funcional
                  _buildBiometricRow(),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.security_rounded,
                    title: 'Autenticación 2FA',
                    subtitle: 'Verificación en dos pasos',
                    isDeveloping: true,
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
                title: 'Datos y privacidad',
                children: [
                  _buildSettingsRow(
                    icon: Icons.download_rounded,
                    title: 'Exportar datos',
                    subtitle: 'Descargar transacciones en CSV/PDF',
                    isDeveloping: true,
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.account_balance_outlined,
                    title: 'Consentimientos PSD2',
                    subtitle: 'Gestionar accesos bancarios autorizados',
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
                    title: 'Política de privacidad',
                    subtitle: 'Consultar política GDPR',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPage()),
                    ),
                  ),
                  _divider(),
                  _buildSettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Eliminar cuenta',
                    subtitle: 'Borrar todos los datos',
                    isDeveloping: true,
                    isDanger: true,
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
              onPressed: () => _showSnackBar(
                'Edición de perfil en desarrollo',
                AppColors.gray700,
              ),
              color: AppColors.textSecondaryLight,
              tooltip: 'Editar perfil',
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
                  'Próximamente',
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
    final isFaceId = _biometricLabel == 'Face ID';
    final icon = isFaceId ? Icons.face_rounded : Icons.fingerprint_rounded;
    final subtitle = _biometricDeviceSupported
        ? (_biometricEnabled
              ? '$_biometricLabel activado — toca para desactivar'
              : 'Activa el acceso rápido con $_biometricLabel')
        : 'No disponible en este dispositivo';

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
                  Text(_biometricLabel, style: AppTypography.titleSmall()),
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
                  'No disponible',
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
    return Semantics(
      label: 'Cerrar sesión',
      button: true,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                  SizedBox(width: 12),
                  Text('Cerrar sesión'),
                ],
              ),
              content: const Text(
                '¿Estás seguro de que quieres cerrar tu sesión?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppColors.textSecondaryLight),
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
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
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
                'Cerrar sesión',
                style: AppTypography.labelLarge(color: AppColors.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
