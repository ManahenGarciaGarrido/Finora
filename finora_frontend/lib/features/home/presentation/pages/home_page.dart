import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/utils/app_startup_tracker.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import 'dashboard_content.dart';
import 'transactions_page.dart';
import 'stats_page.dart';
import 'accounts_page.dart';
import 'settings_page.dart';

/// Página Principal / Shell de navegación
///
/// Contiene la navegación inferior (móvil) o rail (tablet)
/// y gestiona la visualización de las diferentes secciones.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;

  /// Páginas preconstruidas para navegación instantánea (RNF-06)
  /// IndexedStack mantiene todas las páginas en memoria,
  /// eliminando el tiempo de reconstrucción al cambiar de sección.
  /// Navegación resultante: < 16ms (1 frame)
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardContent(
        onNavigateToTransactions: () => setState(() => _selectedNavIndex = 2),
      ),
      const StatsPage(),
      const TransactionsPage(),
      const AccountsPage(),
      const SettingsPage(),
    ];

    // Cargar transacciones tras el primer frame, cuando el token JWT ya está
    // configurado en ApiClient (la autenticación se completa antes de que
    // HomePage sea visible). Esto garantiza que se carguen tanto los datos
    // locales (Hive) como los remotos (API) desde el primer acceso.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TransactionBloc>().add(LoadTransactions());
        // RNF-08: Dashboard visible → registrar tiempo de inicio completo
        AppStartupTracker.markDashboardReady();
      }
    });
  }

  void _onRailTap(int index) {
    // En tablet: 0=Home, 1=Stats, 2=Transactions, 3=Accounts, 4=Settings
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
      ),
      bottomNavigationBar: context.isMobile ? _buildBottomNav() : null,
    );
  }

  /// Layout móvil con IndexedStack para navegación instantánea (RNF-06)
  Widget _buildMobileLayout(BuildContext context) {
    return IndexedStack(index: _selectedNavIndex, children: _pages);
  }

  /// Layout tablet con IndexedStack para navegación instantánea (RNF-06)
  Widget _buildTabletLayout(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          _buildNavigationRail(),
          Expanded(
            child: IndexedStack(index: _selectedNavIndex, children: _pages),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: _selectedNavIndex,
      onDestinationSelected: _onRailTap,
      backgroundColor: AppColors.surfaceLight,
      // Añadimos un indicador sutil para que se vea más profesional
      indicatorColor: AppColors.primary.withValues(alpha: 0.1),
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            // Este gradiente ahora será oscuro y elegante
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: AppColors.white,
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Inicio'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: Text('Estadísticas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Transacciones'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: Text('Cuentas'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: Text('Ajustes'),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildNavItem(
                  Icons.home_outlined,
                  Icons.home_rounded,
                  'Inicio',
                  0,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.analytics_outlined,
                  Icons.analytics_rounded,
                  'Estadísticas',
                  1,
                ),
              ),
              _buildAddButton(),
              Expanded(
                child: _buildNavItem(
                  Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded,
                  'Movimientos',
                  2,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet_rounded,
                  'Cuentas',
                  3,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  Icons.settings_outlined,
                  Icons.settings_rounded,
                  'Ajustes',
                  4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedNavIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedNavIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.gray400,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall(
                color: isSelected ? AppColors.primary : AppColors.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/add-transaction');
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          // Al usar el nuevo gradiente, este botón será azul oscuro/negro
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.shadowColor(AppColors.primary),
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.white, size: 28),
      ),
    );
  }
}
