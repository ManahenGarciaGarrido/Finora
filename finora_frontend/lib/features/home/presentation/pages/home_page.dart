import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/responsive_builder.dart';
import '../../../../core/utils/app_startup_tracker.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/presentation/bloc/transaction_bloc.dart';
import '../../../transactions/presentation/bloc/transaction_event.dart';
import 'accounts_page.dart';
import 'dashboard_content.dart';
import 'transactions_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';
import 'modules_hub_page.dart';

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

  /// RF-12: GlobalKey para acceder a TransactionsPageState y aplicar filtros
  /// de cuenta bancaria desde otras pestañas (e.g., AccountsPage).
  final _txPageKey = GlobalKey<TransactionsPageState>();

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
      // RF-12: key pública para filtrar transacciones por cuenta desde accounts_page
      TransactionsPage(key: _txPageKey),
      ModulesHubPage(
        onNavigateToAccounts: () => setState(() => _selectedNavIndex = 5),
      ),
      const SettingsPage(),
      // Índice 5: AccountsPage integrada en el IndexedStack para mantener bottom nav
      AccountsPage(
        onBack: () => setState(() => _selectedNavIndex = 3),
        onViewAccountTransactions: (accountId, accountName) {
          setState(() => _selectedNavIndex = 2);
        },
      ),
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

  void _onTabSelected(int index) {
    setState(() => _selectedNavIndex = index);
  }

  void _onRailTap(int index) {
    // En tablet: 0=Home, 1=Stats, 2=Transactions, 3=Accounts, 4=Settings
    _onTabSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: ResponsiveBuilder(
        mobile: (context) => _buildMobileLayout(context),
        tablet: (context) => _buildTabletLayout(context),
      ),
      floatingActionButton: context.isMobile
          ? FloatingActionButton(
              onPressed: () => Navigator.pushNamed(context, '/add-transaction'),
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.white,
                size: 28,
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
      destinations: [
        NavigationRailDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: Text(AppLocalizations.of(context).home),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.analytics_outlined),
          selectedIcon: const Icon(Icons.analytics_rounded),
          label: Text(AppLocalizations.of(context).statistics),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.receipt_long_outlined),
          selectedIcon: const Icon(Icons.receipt_long_rounded),
          label: Text(AppLocalizations.of(context).transactions),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.grid_view_outlined),
          selectedIcon: const Icon(Icons.grid_view_rounded),
          label: Text(AppLocalizations.of(context).modules),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(Icons.settings_rounded),
          label: Text(AppLocalizations.of(context).settings),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Builder(
          builder: (context) {
            final s = AppLocalizations.of(context);
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  Icons.home_outlined,
                  Icons.home_rounded,
                  s.home,
                  0,
                ),
                _buildNavItem(
                  Icons.analytics_outlined,
                  Icons.analytics_rounded,
                  s.analysis,
                  1,
                ),
                // Espacio central para el FAB
                const SizedBox(width: 64),
                _buildNavItem(
                  Icons.grid_view_outlined,
                  Icons.grid_view_rounded,
                  s.modules,
                  3,
                ),
                _buildNavItem(
                  Icons.settings_outlined,
                  Icons.settings_rounded,
                  s.settings,
                  4,
                ),
              ],
            );
          },
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
    // Cuando AccountsPage (índice 5) está activa, el tab "Módulos" (3) se muestra seleccionado
    final effectiveIndex = _selectedNavIndex == 5 ? 3 : _selectedNavIndex;
    final isSelected = effectiveIndex == index;

    return InkWell(
      onTap: () => _onTabSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.gray400,
              size: 22,
            ),
            const SizedBox(height: 3),
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
}
