import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/bloc/auth_state.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../../settings/presentation/pages/privacy_page.dart';

/// Página de Ajustes
///
/// Muestra el perfil real del usuario obtenido desde AuthBloc.
/// Cerrar sesión está completamente funcional.
/// Las demás opciones están marcadas como en desarrollo.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  String _getUserName(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.name;
    }
    return 'Usuario';
  }

  String _getUserEmail(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      return authState.user.email;
    }
    return '';
  }

  String _getUserInitials(BuildContext context) {
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
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 16,
                responsive.horizontalPadding, 0,
              ),
              child: Text('Ajustes', style: AppTypography.headlineSmall()),
            ),
          ),

          // Perfil con datos reales
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 20,
                responsive.horizontalPadding, 0,
              ),
              child: _buildProfileSection(context),
            ),
          ),

          // General
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 24,
                responsive.horizontalPadding, 0,
              ),
              child: _buildSettingsSection(
                title: 'General',
                items: [
                  _SettingsItem(
                    icon: Icons.category_outlined,
                    title: 'Categorías',
                    subtitle: 'Gestionar categorías de gastos e ingresos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CategoriesPage(),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notificaciones',
                    subtitle: 'Gestionar alertas y avisos',
                    isDeveloping: true,
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Apariencia',
                    subtitle: 'Tema, idioma y formato',
                    isDeveloping: true,
                  ),
                  _SettingsItem(
                    icon: Icons.currency_exchange_rounded,
                    title: 'Moneda y formato',
                    subtitle: 'EUR - Euros',
                    isDeveloping: true,
                  ),
                ],
              ),
            ),
          ),

          // Seguridad
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding, 16,
                responsive.horizontalPadding, 0,
              ),
              child: _buildSettingsSection(
                title: 'Seguridad',
                items: [
                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    title: 'Cambiar contraseña',
                    subtitle: 'Actualizar contraseña de acceso',
                    isDeveloping: true,
                  ),
                  _SettingsItem(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometría',
                    subtitle: 'Desbloqueo con huella dactilar',
                    isDeveloping: true,
                  ),
                  _SettingsItem(
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
                responsive.horizontalPadding, 16,
                responsive.horizontalPadding, 0,
              ),
              child: _buildSettingsSection(
                title: 'Datos y privacidad',
                items: [
                  _SettingsItem(
                    icon: Icons.download_rounded,
                    title: 'Exportar datos',
                    subtitle: 'Descargar transacciones en CSV/PDF',
                    isDeveloping: true,
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    subtitle: 'Consultar política GDPR',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPage(),
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
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
                responsive.horizontalPadding, 24,
                responsive.horizontalPadding, 0,
              ),
              child: _buildLogoutButton(context),
            ),
          ),

          // Versión
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(responsive.horizontalPadding),
              child: Center(
                child: Text(
                  'Finora v1.0.0',
                  style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: responsive.hp(12))),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
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
                _getUserInitials(context),
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
                Text(_getUserName(context), style: AppTypography.titleMedium()),
                const SizedBox(height: 2),
                Text(
                  _getUserEmail(context),
                  style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
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
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Edición de perfil en desarrollo'),
                    backgroundColor: AppColors.gray700,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<_SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: AppTypography.labelMedium(color: AppColors.textSecondaryLight),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  _buildSettingsRow(item),
                  if (index < items.length - 1)
                    Divider(height: 1, indent: 56, color: AppColors.gray100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsRow(_SettingsItem item) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.isDanger ? AppColors.errorSoft : AppColors.gray100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: item.isDanger ? AppColors.error : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleSmall(
                    color: item.isDanger ? AppColors.error : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  style: AppTypography.bodySmall(color: AppColors.textTertiaryLight),
                ),
              ],
            ),
          ),
          if (item.isDeveloping)
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
    );

    if (item.onTap != null) {
      return GestureDetector(
        onTap: item.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
                const SizedBox(width: 12),
                const Text('Cerrar sesión'),
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
            const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Cerrar sesión',
              style: AppTypography.labelLarge(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDeveloping;
  final bool isDanger;
  final VoidCallback? onTap;

  _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDeveloping = false,
    this.isDanger = false,
    this.onTap,
  });
}
